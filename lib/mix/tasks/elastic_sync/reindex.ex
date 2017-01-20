defmodule Mix.Tasks.ElasticSync.Reindex do
  def run(args) do
    Mix.Task.run "loadpaths", args

    unless "--no-compile" in args do
      Mix.Project.compile(args)
    end

    case parse_args(args) do
      {:ok, schema, sync_repo} ->
        ecto_repo = sync_repo.__elastic_sync__(:ecto)
        Mix.Ecto.ensure_started(ecto_repo, args)
        sync_repo.reindex(schema)
      {:error, message} ->
        Mix.raise(message)
    end
  end

  defp parse_args(args) when length(args) < 2 do
    {:error, "Wrong number of arguments."}
  end

  defp parse_args([sync_repo_name, schema_name | _args]) do
    with {:ok, schema} <- parse_elastic_sync(schema_name),
         {:ok, sync_repo} <- parse_elastic_sync(sync_repo_name),
         do: {:ok, schema, sync_repo}
  end

  defp parse_elastic_sync(name) do
    mod = Module.concat([name])

    case Code.ensure_compiled(mod) do
      {:module, _} ->
        if function_exported?(mod, :__elastic_sync__, 1) do
          {:ok, mod}
        else
          {:error, "Module #{inspect mod} isn't using elastic_sync."}
        end
      {:error, error} ->
        {:error, "Could not load #{inspect mod}, error: #{inspect error}."}
    end
  end
end
