defmodule ElasticSync.Schema do
  defmacro __using__([index: index, type: type]) do
    quote do
      def __elastic_sync__(:index), do: unquote(index)
      def __elastic_sync__(:type), do: unquote(type)
    end
  end

  defmacro __using__(_opts) do
    raise ArgumentError, """
    You must provide an index name and a type. For example:

        use ElasticSync.Schema, index: "something", type: "blah"
    """
  end

  def get_index(schema, opts \\ []) do
    schema
    |> get_config(opts)
    |> Keyword.get(:index)
  end

  def get_type(schema, opts \\ []) do
    schema
    |> get_config(opts)
    |> Keyword.get(:type)
  end

  def get_config(schema, opts \\ []) do
    index = schema.__elastic_sync__(:index)
    type = schema.__elastic_sync__(:type)
    Keyword.merge([index: index, type: type], opts)
  end
end
