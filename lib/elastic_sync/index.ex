defmodule ElasticSync.Index do
  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API

  # TODO: Allow developers to control mappings here
  def create(names, config \\ []) do
    names
    |> API.index
    |> HTTP.put(Tirexs.get_uri_env(), config)
  end

  def remove(names) do
    names
    |> API.index
    |> HTTP.delete
  end

  def exists?(name) do
    case name |> API.index |> HTTP.get do
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end
  end

  def refresh(name) do
    name
    |> API._refresh
    |> HTTP.post
  end

  def transition(name, fun, config \\ []) do
    transition(name, get_new_alias_name(name), fun, config)
  end

  @doc """
  Useful for reindexing. It will:

  1. Create a new index using the given alias_name.
  2. Call the given function, with the alias name as an argument.
  3. Refresh the index.
  4. Set the newly created index to the alias.
  5. Remove old indicies.
  """
  def transition(name, alias_name, fun, config) do
    with {:ok, _, _} <- create(alias_name, config),
         :ok  <- fun.(alias_name),
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

    API._aliases()
    |> HTTP.post(%{actions: remove ++ [add]})
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
    name
    |> get_aliases()
    |> Enum.filter(&(not &1 in except))
    |> case do
         [] ->
           {:ok, 200, %{acknowledged: true}}
         names ->
           remove(names)
       end
  end

  defp get_aliases(name) do
    re = ~r/^#{name}-\d{13}$/

    API._aliases()
    |> HTTP.get()
    |> normalize_aliases()
    |> Enum.filter(&Regex.match?(re, &1))
  end

  defp normalize_aliases({:error, _, _}), do: []
  defp normalize_aliases({:ok, 200, aliases}) do
    aliases
    |> Map.keys()
    |> Enum.map(&to_string/1)
  end
end
