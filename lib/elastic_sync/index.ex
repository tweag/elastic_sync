defmodule ElasticSync.Index do
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

    use ElasticSync.Index, index: "foods"
    """
  end
  def put(index, :config, nil), do: index
  def put(_index, :config, value) when not is_tuple(value) do
    raise ArgumentError, """
    The index config must be a tuple in the format.

    use ElasticSync.Index, index: "foods", config: {Food, :index_config}
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
end
