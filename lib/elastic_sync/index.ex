defmodule ElasticSync.Index do
  alias Tirexs.HTTP

  # TODO: Allow developers to control mappings here
  def create(name) do
    HTTP.put("/#{name}")
  end

  def remove(name) do
    HTTP.delete("/#{name}")
  end

  def refresh(name) do
    HTTP.post("/#{name}/_refresh")
  end

  def transition(name, fun) do
    transition(name, get_new_alias_name(name), fun)
  end

  @doc """
  Useful for reindexing. It will:

  1. Create a new index using the given alias_name.
  2. Call the given function, with the alias name as an argument.
  3. Refresh the index.
  4. Set the newly created index to the alias.
  5. Remove old indicies.
  """
  def transition(name, alias_name, fun) do
    with {:ok, _, _} <- create(alias_name),
         {:ok, :ok}  <- fun.(alias_name),
         {:ok, _, _} <- refresh(alias_name),
         {:ok, _, _} <- replace_alias(name, index: alias_name),
         {:ok, _, _} <- remove_stale_indicies(name),
         do: :ok
  end

  @doc """
  Attach the alias name to the newly created index. Remove
  all old aliases.
  """
  def replace_alias(name, index: index_name) do
    add = %{add: %{alias: name, index: index_name}}

    remove =
      name
      |> get_index_names_for_alias()
      |> Enum.map(fn a ->
        %{remove: %{alias: name, index: a}}
      end)

    HTTP.post("/_aliases", %{actions: remove ++ [add]})
  end

  @doc """
  Delete all the indicies for the given alias name
  that aren't currently aliases of the name.
  """
  def clean_indicies(_name) do
    raise "Not implemented"
  end

  @doc """
  Generate an index name ending with the current timestamp in
  milliseconds from a name.
  """
  def get_new_alias_name(name) do
    ms = :os.system_time(:milli_seconds)
    name <> "-" <> to_string(ms)
  end

  defp get_index_names_for_alias(name) do
    case HTTP.get("/_aliases/#{name}") do
      {:ok, 200, aliases} ->
        Map.keys(aliases)
      {:error, _, _} ->
        []
    end
  end
end
