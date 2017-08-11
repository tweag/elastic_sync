defmodule ElasticSync.Reindex do
  alias ElasticSync.{Index, Repo}

  @batch_size 500
  @timeout 10_000

  def run(ecto, schema, opts \\ []) do
    index      = schema.__elastic_sync__

    batch_size = Keyword.get(opts, :batch_size, @batch_size)
    timeout    = Keyword.get(opts, :timeout, @timeout)
    progress   = Keyword.get(opts, :progress, false)
    parallel   = Keyword.get(opts, :parallel, true)

    Index.HTTP.transition(index, fn new_index ->
      result = ecto.transaction fn ->
        schema
        |> ecto.stream(max_rows: batch_size)
        |> Stream.chunk(batch_size, batch_size, [])
        |> log_progress(ecto, schema, progress)
        |> load_records(&Repo.load(new_index, &1), timeout, parallel)
        |> Stream.run
      end

      normalize_transaction(result)
    end)
  end

  defp load_records(stream, fun, _, false) do
    Stream.each(stream, fun)
  end
  defp load_records(stream, fun, timeout, true) do
    Task.async_stream(stream, fun, timeout: timeout)
  end

  defp log_progress(stream, _, _, false), do: stream
  defp log_progress(stream, ecto, schema, true) do
    total  = ecto.aggregate(schema, :count, :id)
    format = [left: [IO.ANSI.magenta, "Reindexing...", IO.ANSI.reset, " |"]]

    stream
    |> Stream.with_index(1)
    |> Stream.each(fn {_, i} -> ProgressBar.render(i, total, format) end)
    |> Stream.map(fn {v, _} -> v end)
  end

  defp normalize_transaction({:ok, :ok}), do: :ok
  defp normalize_transaction(other), do: other
end
