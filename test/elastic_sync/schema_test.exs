defmodule ElasticSync.SchemaTest do
  use ExUnit.Case
  doctest ElasticSync.Schema
  alias ElasticSync.Schema

  defmodule Simple do
    defstruct id: 1, name: "simple"
    use ElasticSync.Schema, index: "elastic_sync_test", type: "simple"
  end

  test "__elastic_sync__(:name)" do
    assert Simple.__elastic_sync__(:index) == "elastic_sync_test"
  end

  test "__elastic_sync__(:type)" do
    assert Simple.__elastic_sync__(:type) == "simple"
  end

  test "get_config" do
    assert Schema.get_config(Simple) == %{index: "elastic_sync_test", type: "simple"}
  end

  test "get_index" do
    assert Schema.get_index(Simple) == "elastic_sync_test"
  end

  test "get_type" do
    assert Schema.get_type(Simple) == "simple"
  end
end
