defmodule ElasticSync.SchemaTest do
  use ExUnit.Case, async: false

  alias ElasticSync.Schema

  @config %{
    mappings: %{
      test: %{
        properties: %{
          title: %{
            type: "string"
          }
        }
      }
    }
  }

  def config do
    @config
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

  @simple [config: %{}, index: "foo", type: "foo"]
  @with_type [config: %{}, index: "foo", type: "bar"]
  @with_config [config: @config, index: "foo", type: "bar"]

  test "__elastic_sync__/1" do
    expected = %ElasticSync.Schema{index: "foo", type: "foo", config: %{}}
    assert expected == Simple.__elastic_sync__
  end

  test "__elastic_sync__/1 with type" do
    expected = %ElasticSync.Schema{index: "foo", type: "bar", config: %{}}
    assert expected == WithType.__elastic_sync__
  end

  test "__elastic_sync__/1 with config" do
    expected = %ElasticSync.Schema{index: "foo", type: "bar", config: ElasticSync.SchemaTest.config()}
    assert expected == WithConfig.__elastic_sync__
  end

  test "get/2" do
    Enum.each @simple, fn {k, v} ->
      assert Schema.get(Simple, k) == v
      assert Schema.get(Simple.__elastic_sync__, k) == v
    end

    Enum.each @with_type, fn {k, v} ->
      assert Schema.get(WithType, k) == v
      assert Schema.get(WithType.__elastic_sync__, k) == v
    end

    Enum.each @with_config, fn {k, v} ->
      assert Schema.get(WithConfig, k) == v
      assert Schema.get(WithConfig.__elastic_sync__, k) == v
    end
  end

  test "merge/2" do
    expected = %Schema{index: "blah", type: "foo", config: %{}}
    assert Schema.merge(Simple, %{index: "blah"}) == expected
    assert Schema.merge(Simple.__elastic_sync__, %{index: "blah"}) == expected

    assert Schema.merge(Simple.__elastic_sync__, [index: "blah"]) == expected
    assert Schema.merge(Simple.__elastic_sync__, [index: "blah"]) == expected
  end

  test "to_list/1" do
    assert Schema.to_list(Simple) == @simple
    assert Schema.to_list(Simple.__elastic_sync__) == @simple

    assert Schema.to_list(WithType) == @with_type
    assert Schema.to_list(WithType.__elastic_sync__) == @with_type

    assert Schema.to_list(WithConfig) == @with_config
    assert Schema.to_list(WithConfig.__elastic_sync__) == @with_config
  end
end
