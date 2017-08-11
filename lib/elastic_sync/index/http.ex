defmodule ElasticSync.Index.HTTP do
  alias ElasticSync.Index
  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API

  @doc """
  Useful for reindexing. It will:

  1. Create a new index using the given alias_name.
  2. Call the given function, with the alias name as an argument.
  3. Refresh the index.
  4. Set the newly created index to the alias.
  5. Remove old indicies.
  """
  def transition(%Index{} = index, load_data) do
    new_index = Index.put_alias(index)

    with :ok <- normalize_http(create(new_index)),
         :ok <- normalize_data_load(load_data.(new_index)),
         :ok <- normalize_http(refresh(new_index)),
         :ok <- normalize_http(replace_alias(new_index)),
         :ok <- normalize_http(clean_indicies(new_index)),
      do: {:ok, new_index}
  end

  def create(%Index{name: name, config: {mod, fun}}) do
    name
    |> API.index
    |> HTTP.put(apply(mod, fun, []))
  end

  def remove(%Index{name: name}) do
    do_remove(name)
  end

  def exists?(%Index{name: name}) do
    case name |> API.index |> HTTP.get do
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end
  end

  def refresh(%Index{name: name}) do
    name
    |> API._refresh
    |> HTTP.post
  end

  def load(%Index{name: name, type: type}, data) do
    import Tirexs.Bulk

    # Tirexs requires keyword lists...
    data = Enum.map data, fn
      doc when is_list(doc) -> doc
      doc -> Enum.into(doc, [])
    end

    payload =
      [index: name, type: type]
      |> bulk(do: index(data))

    Tirexs.bump!(payload)._bulk()
  end

  @doc """
  Attach the alias name to the newly created index. Remove
  all old aliases.
  """
  def replace_alias(%Index{name: name, alias: alias_name}) do
    add = %{add: %{alias: alias_name, index: name}}

    remove =
      alias_name
      |> get_aliases()
      |> Enum.map(fn a ->
        %{remove: %{alias: alias_name, index: a}}
      end)

    API._aliases
    |> HTTP.post(%{actions: remove ++ [add]})
  end

  def clean_indicies(%Index{name: name, alias: alias_name}) do
    alias_name
    |> get_aliases()
    |> Enum.filter(&(&1 != name))
    |> case do
         []    -> {:ok, 200, %{acknowledged: true}}
         names -> do_remove(names)
       end
  end

  defp do_remove(names) do
    names
    |> API.index
    |> HTTP.delete
  end

  defp get_aliases(name) do
    API._aliases
    |> HTTP.get
    |> normalize_aliases()
    |> Enum.filter(&Regex.match?(~r/^#{name}-\d{13}$/, &1))
  end

  defp normalize_http({:ok, _, _}), do: :ok
  defp normalize_http({:error, _, error}) do
    {:error, error["error"]["reason"]}
  end

  defp normalize_data_load(:ok), do: :ok
  defp normalize_data_load(other) do
    {:error, "Failed to load data. Expected function to return :ok, but got #{inspect other}."}
  end

  defp normalize_aliases({:error, _, _}), do: []
  defp normalize_aliases({:ok, 200, aliases}) do
    aliases
    |> Map.keys()
    |> Enum.map(&to_string/1)
  end
end
