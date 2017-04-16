defmodule ElasticSync.SchemaTest do
  use ExUnit.Case
  alias ElasticSync.Schema

  defmodule Simple do
    defstruct id: 1
    use ElasticSync.Schema, index: "foo"
  end

  defmodule WithType do
    defstruct id: 1
    use ElasticSync.Schema, index: "foo", type: "bar"
  end

  test "__elastic_sync__/1" do
    expected = %ElasticSync.Schema{index: "foo", type: "foo"}
    assert expected == Simple.__elastic_sync__
  end

  test "__elastic_sync__/1 with type" do
    expected = %ElasticSync.Schema{index: "foo", type: "bar"}
    assert expected == WithType.__elastic_sync__
  end

  test "get/2" do
    assert Schema.get(Simple, :index) == "foo"
    assert Schema.get(Simple, :type) == "foo"

    assert Schema.get(WithType, :index) == "foo"
    assert Schema.get(WithType, :type) == "bar"
  end
end
