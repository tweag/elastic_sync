defmodule ElasticSync.SchemaTest do
  use ExUnit.Case, async: false

  alias ElasticSync.Schema

  # @config %{
  #   mappings: %{
  #     test: %{
  #       properties: %{
  #         title: %{
  #           type: "string"
  #         }
  #       }
  #     }
  #   }
  # }

  # def config do
  #   @config
  # end

  # defmodule Simple do
  #   defstruct id: 1
  #   use ElasticSync.Schema, index: "foo"
  # end

  # defmodule WithType do
  #   defstruct id: 1
  #   use ElasticSync.Schema, index: "foo", type: "bar"
  # end

  # defmodule WithConfig do
  #   defstruct id: 1
  #   use ElasticSync.Schema, index: "foo", type: "bar", config: {ElasticSync.SchemaTest, :config}
  # end
end
