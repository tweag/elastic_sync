defmodule Mix.Tasks.ElasticSync.Reindex do
  def run(args) do
    Mix.Task.run "loadpaths", args

    unless "--no-compile" in args do
      Mix.Project.compile(args)
    end

    {sync_repo, schema, args} = parse!(args)
    repo = sync_repo.__elastic_sync__(:ecto)
    ensure_started!(repo, args)

    case sync_repo.reindex(schema, progress: true) do
      {:ok, _} ->
        :ok
      error ->
        Mix.raise "The following error occurred:\n  #{inspect error}"
    end
  end

  defp ensure_started!(repo, args) do
    case Mix.Ecto.ensure_started(repo, args) do
      {:ok, _, _} ->
        :ok
      error ->
        Mix.raise "Failed to start Ecto, error: #{inspect error}."
    end
  end

  defp parse!(args) when length(args) < 2 do
    Mix.raise "Wrong number of arguments."
  end
  defp parse!([sync_repo_name, schema_name | args]) do
    {compile!(sync_repo_name), compile!(schema_name), args}
  end

  defp compile!(name) do
    case [name] |> Module.concat() |> Code.ensure_compiled() do
      {:module, mod} ->
        mod
      error ->
        Mix.raise "Invalid module name '#{name}', error: #{inspect error}."
    end
  end
end
