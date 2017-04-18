defmodule ElasticSync.IndexTest do
  use ExUnit.Case, async: false

  alias Tirexs.HTTP
  alias ElasticSync.Index

  @index "elastic_sync_index_test"
  @config %{
    mappings: %{
      test: %{
        properties: %{
          title: %{
            type: "integer"
          }
        }
      }
    }
  }

  setup do
    HTTP.delete!("*")
    :ok
  end
end
