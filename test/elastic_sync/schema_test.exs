defmodule ElasticSync.SchemaTest do
  use ExUnit.Case, async: false

  alias ElasticSync.Schema

  defmodule Simple do
    defstruct id: 1
    use ElasticSync.Schema, index: "foo"
  end

  defmodule WithType do
    defstruct id: 1
    use ElasticSync.Schema, index: "foo", type: "bar"
  end

  @simple [index: "foo", type: "foo"]
  @with_type [index: "foo", type: "bar"]

  test "__elastic_sync__/1" do
    expected = %ElasticSync.Schema{index: "foo", type: "foo"}
    assert expected == Simple.__elastic_sync__
  end

  test "__elastic_sync__/1 with type" do
    expected = %ElasticSync.Schema{index: "foo", type: "bar"}
    assert expected == WithType.__elastic_sync__
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
  end

  test "merge/2" do
    expected = %Schema{index: "blah", type: "foo"}
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
  end
end
