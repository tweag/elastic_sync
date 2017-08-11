defmodule Mix.Tasks.ElasticSync.Reindex do
  import Mix.Ecto

  @switches [batch_size: :integer]

  def run(args) do
    Mix.Task.run "loadpaths", args

    unless "--no-compile" in args do
      Mix.Project.compile([])
    end

    {sync_repo, schema, opts} = parse!(args)
    repo = sync_repo.__elastic_sync__(:ecto)

    ensure_started(repo, [])

    case sync_repo.reindex(schema, opts) do
      {:ok, _} ->
        :ok
      error ->
        Mix.raise "The following error occurred:\n  #{inspect error}"
    end
  end

  def parse!(args) when length(args) < 2 do
    Mix.raise "Wrong number of arguments."
  end
  def parse!([sync_repo_name, schema_name | args]) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches)
    {compile!(sync_repo_name), compile!(schema_name), opts}
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
