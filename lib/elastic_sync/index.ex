defmodule ElasticSync.Index do
  alias Tirexs.HTTP

  # TODO: Allow developers to control mappings here
  def create(name) do
    HTTP.put("/#{name}")
  end

  def remove(name) do
    HTTP.delete("/#{name}")
  end

  def exists?(name) do
    case HTTP.get("/#{name}") do
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end
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
         {:ok, _, _} <- remove_indicies(name, except: [alias_name]),
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
      |> get_aliases()
      |> Enum.map(fn a ->
        %{remove: %{alias: name, index: a}}
      end)

    HTTP.post("/_aliases", %{actions: remove ++ [add]})
  end

  @doc """
  Generate an index name ending with the current timestamp in
  milliseconds from a name.
  """
  def get_new_alias_name(name) do
    ms = :os.system_time(:milli_seconds)
    name <> "-" <> to_string(ms)
  end

  def remove_indicies(name, except: except) do
    re = ~r/^#{name}-\d{13}$/

    name
    |> get_aliases()
    |> Enum.filter(&Regex.match?(re, &1))
    |> Enum.filter(&(not &1 in except))
    |> Enum.each(&HTTP.delete("/#{&1}"))
  end

  defp get_aliases(name) do
    case HTTP.get("/_aliases/#{name}") do
      {:ok, 200, aliases} ->
        aliases
        |> Map.keys()
        |> Enum.map(&to_string/1)
      {:error, _, _} ->
        []
    end
  end
end
