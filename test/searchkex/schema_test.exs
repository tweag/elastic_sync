defmodule Searchkex.SchemaTest do
  use ExUnit.Case
  doctest Searchkex.Schema
  alias Searchkex.Schema

  defmodule Simple do
    defstruct id: 1, name: "simple"
    use Searchkex.Schema, index: "searchkex_test", type: "simple"
  end

  test "__searchkex__(:name)" do
    assert Simple.__searchkex__(:index) == "searchkex_test"
  end

  test "__searchkex__(:type)" do
    assert Simple.__searchkex__(:type) == "simple"
  end

  test "get_config" do
    assert Schema.get_config(Simple) == %{index: "searchkex_test", type: "simple"}
  end

  test "get_index" do
    assert Schema.get_index(Simple) == "searchkex_test"
  end

  test "get_type" do
    assert Schema.get_type(Simple) == "simple"
  end
end
