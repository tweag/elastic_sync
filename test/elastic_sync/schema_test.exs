defmodule ElasticSync.SchemaTest do
  use ExUnit.Case, async: false

  alias ElasticSync.Schema

  def config do
    %{
      mappings: %{
        test: %{
          properties: %{
            title: %{
              type: "text"
            }
          }
        }
      }
    }
  end

  defmodule Simple do
    defstruct id: 1
    use ElasticSync.Schema, index: "foo"
  end

  defmodule WithType do
    defstruct id: 1
    use ElasticSync.Schema, index: "foo", type: "bar"
  end

  defmodule WithConfig do
    defstruct id: 1
    use ElasticSync.Schema, index: "foo", type: "bar", config: {ElasticSync.SchemaTest, :config}
  end

  test "__elastic_sync__/1" do
    expected = %ElasticSync.Schema{index: "foo", type: "foo", config: []}
    assert expected == Simple.__elastic_sync__
  end

  test "__elastic_sync__/1 with type" do
    expected = %ElasticSync.Schema{index: "foo", type: "bar", config: []}
    assert expected == WithType.__elastic_sync__
  end

  test "__elastic_sync__/1 with config" do
    expected = %ElasticSync.Schema{index: "foo", type: "bar", config: ElasticSync.SchemaTest.config()}
    assert expected == WithConfig.__elastic_sync__
  end

  test "get/2" do
    assert Schema.get(Simple, :index) == "foo"
    assert Schema.get(Simple, :type) == "foo"
    assert Schema.get(Simple, :config) == []

    assert Schema.get(WithType, :index) == "foo"
    assert Schema.get(WithType, :type) == "bar"
    assert Schema.get(WithType, :config) == []

    assert Schema.get(WithConfig, :index) == "foo"
    assert Schema.get(WithConfig, :type) == "bar"
    assert Schema.get(WithConfig, :config) == ElasticSync.SchemaTest.config()
  end
end
