defmodule ElasticSync.Reindex do
  alias ElasticSync.{Index, Repo}

  @batch_size 500

  def run(ecto, schema, opts \\ []) do
    index      = schema.__elastic_sync__
    batch_size = Keyword.get(opts, :batch_size, @batch_size)
    progress   = Keyword.get(opts, :progress, false)

    Index.HTTP.transition(index, fn new_index ->
      result = ecto.transaction fn ->
        schema
        |> ecto.stream(max_rows: batch_size)
        |> Stream.chunk(batch_size, batch_size, [])
        |> Stream.each(&Repo.load(new_index, &1))
        |> log_progress(ecto, schema, progress)
        |> Stream.run
      end

      normalize_transaction(result)
    end)
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
