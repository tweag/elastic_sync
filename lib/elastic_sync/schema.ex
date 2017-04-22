defmodule ElasticSync.Schema do
  defstruct [:index, :type, :config]

  defmacro __using__(opts) do
    index  = Keyword.get(opts, :index)
    type   = Keyword.get(opts, :type, index)
    {mod, fun} = Keyword.get(opts, :config, {ElasticSync.Schema, :default_config})

    validate_index_name!(index)

    quote do
      def __elastic_sync__ do
        %ElasticSync.Schema{
          index: unquote(index),
          type: unquote(type),
          config: apply(unquote(mod), unquote(fun), [])
        }
      end
    end
  end

  def default_config do
    %{}
  end

  def get(%__MODULE__{} = schema, key) do
    Map.get(schema, key)
  end
  def get(schema, key) do
    get(schema.__elastic_sync__, key)
  end

  def to_list(%__MODULE__{} = schema) do
    schema
    |> Map.delete(:__struct__)
    |> Map.to_list()
  end
  def to_list(schema) do
    to_list(schema.__elastic_sync__)
  end

  def merge(%__MODULE__{} = schema, opts) when is_map(opts) do
    Map.merge(schema, opts)
  end
  def merge(schema, opts) when is_list(opts) do
    merge(schema, Enum.into(opts, %{}))
  end
  def merge(schema, opts) do
    merge(schema.__elastic_sync__, opts)
  end

  defp validate_index_name!(nil) do
    raise ArgumentError, """
    You must provide an index name. For example:

    use ElasticSync.Schema, index: "foods"
    """
  end
  defp validate_index_name!(_), do: nil
end
