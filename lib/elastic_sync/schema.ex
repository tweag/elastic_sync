defmodule ElasticSync.Schema do
  defmacro __using__(opts) do
    quote do
      use ElasticSync.Index, unquote(opts)
    end
  end
end
