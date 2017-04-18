defmodule ElasticSync.Schema do
  defmacro __using__(opts) do
    index  = Keyword.get(opts, :index)
    type   = Keyword.get(opts, :type, index)
    {mod, fun} = Keyword.get(opts, :config, {ElasticSync.Schema, :default_config})

    validate_index_name!(index)

    quote do
      def __elastic_sync__ do
        %ElasticSync.Index{
          name: unquote(index),
          type: unquote(type),
          config: apply(unquote(mod), unquote(fun), [])
        }
      end
    end
  end

  def default_config do
    %{}
  end

  defp validate_index_name!(nil) do
    raise ArgumentError, """
    You must provide an index name. For example:

    use ElasticSync.Schema, index: "foods"
    """
  end
  defp validate_index_name!(_), do: nil
end
