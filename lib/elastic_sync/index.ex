defmodule ElasticSync.Index do
  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API

  defstruct [:name, :type, :alias]

  def merge(%__MODULE__{} = index, opts) when is_list(opts) do
    merge(index, Enum.into(opts, %{}))
  end
  def merge(%__MODULE__{} = index, %{index: name} = opts) do
    opts =
      opts
      |> Map.delete(:index)
      |> Map.put(:name, name)

    merge(index, opts)
  end
  def merge(%__MODULE__{} = index, opts) do
    Map.merge(index, opts)
  end

  def to_list(%__MODULE__{name: name, type: type}) do
    [index: name, type: type]
  end

  def put_alias(%__MODULE__{name: name} = index) do
    next_name = get_new_index_name(name)
    %__MODULE__{index | name: next_name, alias: name}
  end

  def create(%__MODULE__{name: name, config: config}) do
    name
    |> API.index
    |> HTTP.put(config)
  end

  def remove(%__MODULE__{name: name}) do
    do_remove(name)
  end

  def exists?(%__MODULE__{name: name}) do
    case name |> API.index |> HTTP.get do
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end
  end

  def refresh(%__MODULE__{name: name}) do
    name
    |> API._refresh
    |> HTTP.post
  end

  @doc """
  Useful for reindexing. It will:

  1. Create a new index using the given alias_name.
  2. Call the given function, with the alias name as an argument.
  3. Refresh the index.
  4. Set the newly created index to the alias.
  5. Remove old indicies.
  """
  def transition(%__MODULE__{} = index, fun) do
    with {:ok, _, _} <- create(index),
         :ok  <- fun.(index),
         {:ok, _, _} <- refresh(index),
         {:ok, _, _} <- replace_alias(index),
         {:ok, _, _} <- remove_indicies(index),
         do: :ok
  end

  @doc """
  Attach the alias name to the newly created index. Remove
  all old aliases.
  """
  def replace_alias(%__MODULE__{name: name, alias: alias_name}) do
    add = %{add: %{alias: alias_name, index: name}}

    remove =
      name
      |> get_aliases()
      |> Enum.map(fn a ->
        %{remove: %{alias: alias_name, index: a}}
      end)

    API._aliases()
    |> HTTP.post(%{actions: remove ++ [add]})
  end

  def remove_indicies(%__MODULE__{name: name, alias: alias_name}) do
    alias_name
    |> get_aliases()
    |> Enum.filter(&(&1 != name))
    |> case do
         [] ->
           {:ok, 200, %{acknowledged: true}}
         names ->
           do_remove(names)
       end
  end

  defp do_remove(names) do
    names
    |> API.index
    |> HTTP.delete
  end

  defp get_new_index_name(name) do
    ms = :os.system_time(:milli_seconds)
    name <> "-" <> to_string(ms)
  end

  defp get_aliases(name) do
    API._aliases
    |> HTTP.get
    |> normalize_aliases()
    |> Enum.filter(&Regex.match?(~r/^#{name}-\d{13}$/, &1))
  end

  defp normalize_aliases({:error, _, _}), do: []
  defp normalize_aliases({:ok, 200, aliases}) do
    aliases
    |> Map.keys()
    |> Enum.map(&to_string/1)
  end
end
