defmodule Mix.Tasks.ElasticSync.Reindex do
  def run(args) do
    Mix.Task.run "loadpaths", args

    unless "--no-compile" in args do
      Mix.Project.compile(args)
    end

    case reindex(args) do
      :ok ->
        :ok
      {:error, error} ->
        Mix.raise "Reindex failed, error: #{inspect error}"
    end
  end

  def reindex(args) do
    with {:ok, schema, sync_repo} <- parse_args(args),
         {:ok, _, _} <- ensure_started(sync_repo, args),
         :ok <- sync_repo.reindex(schema),
         do: :ok
  end

  defp ensure_started(sync_repo, args) do
    Mix.Ecto.ensure_started(sync_repo.__elastic_sync__(:ecto), args)
  end

  defp parse_args(args) when length(args) < 2 do
    {:error, "Wrong number of arguments."}
  end

  defp parse_args([sync_repo_name, schema_name | _args]) do
    with {:ok, schema} <- parse_elastic_sync(schema_name, 0),
         {:ok, sync_repo} <- parse_elastic_sync(sync_repo_name, 1),
         do: {:ok, schema, sync_repo}
  end

  defp parse_elastic_sync(name, arity) do
    mod = Module.concat([name])

    case Code.ensure_compiled(mod) do
      {:module, _} ->
        if function_exported?(mod, :__elastic_sync__, arity) do
          {:ok, mod}
        else
          {:error, "Module #{inspect mod} isn't using elastic_sync."}
        end
      {:error, error} ->
        {:error, "Could not load #{inspect mod}, error: #{inspect error}."}
    end
  end
end
