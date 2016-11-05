defmodule Searchkex.Schema do
  defmacro __using__([index: index, type: type]) do
    quote do
      def __searchkex__(:index), do: unquote(index)
      def __searchkex__(:type), do: unquote(type)
    end
  end

  defmacro __using__(_opts) do
    raise ArgumentError, """
    You must provide an index name and a type. For example:

        use Searchkex.Schema, index: "something", type: "blah"
    """
  end

  def get_index(schema) do
    schema.__searchkex__(:index)
  end

  def get_type(schema) do
    schema.__searchkex__(:type)
  end

  def get_config(schema) do
    Enum.reduce([:index, :type], %{}, fn(prop, acc) ->
      Map.put(acc, prop, schema.__searchkex__(prop))
    end)
  end
end
