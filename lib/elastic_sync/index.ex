defmodule ElasticSync.Index do
  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API

  defstruct [
    name: nil,
    type: nil,
    alias: nil,
    config: {ElasticSync.Index, :default_config}
  ]

  defmacro __using__(opts) do
    name   = Keyword.get(opts, :index)
    type   = Keyword.get(opts, :type, name)
    config = Keyword.get(opts, :config)

    quote do
      def __elastic_sync__ do
        alias ElasticSync.Index

        %Index{}
        |> Index.put(:name, unquote(name))
        |> Index.put(:type, unquote(type))
        |> Index.put(:config, unquote(config))
      end
    end
  end

  def put(_index, :name, nil) do
    raise ArgumentError, """
    You must provide an index name. For example:

    use ElasticSync.Schema, index: "foods"
    """
  end
  def put(index, :config, nil), do: index
  def put(_index, :config, value) when not is_tuple(value) do
    IO.inspect(value)
    raise ArgumentError, """
    The index config must be a tuple in the format.

    use ElasticSync.Schema, index: "foods", config: {Food, :index_config}
    """
  end
  def put(index, key, value), do: Map.put(index, key, value)

  def default_config do
    %{}
  end

  def put_alias(%__MODULE__{name: name, alias: alias_name} = index) do
    ms = :os.system_time(:milli_seconds)
    base_name = alias_name || name
    next_name = base_name <> "-" <> to_string(ms)
    %__MODULE__{index | name: next_name, alias: base_name}
  end

  def create(%__MODULE__{name: name, config: {mod, fun}}) do
    name
    |> API.index
    |> HTTP.put(apply(mod, fun, []))
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
    with index <- put_alias(index),
         {:ok, _, _} <- create(index),
         :ok  <- fun.(index),
         {:ok, _, _} <- refresh(index),
         {:ok, _, _} <- replace_alias(index),
         {:ok, _, _} <- clean_indicies(index),
         do: {:ok, index}
  end

  def load(%__MODULE__{name: name, type: type}, data) do
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
  def replace_alias(%__MODULE__{name: name, alias: alias_name}) do
    add = %{add: %{alias: alias_name, index: name}}

    remove =
      alias_name
      |> get_aliases()
      |> Enum.map(fn a ->
        %{remove: %{alias: alias_name, index: a}}
      end)

    HTTP.post(API._aliases(), %{actions: remove ++ [add]})
  end

  def clean_indicies(%__MODULE__{name: name, alias: alias_name}) do
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
