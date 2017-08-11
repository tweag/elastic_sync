defmodule ElasticSync.IndexTest do
  use ExUnit.Case, async: false

  alias Tirexs.HTTP
  alias ElasticSync.Index

  @index %Index{
    name: "elastic_sync_index_test",
    type: "elastic_sync_index_test"
  }

  @config {Index, :default_config}

  setup do
    HTTP.delete!("*")
    :ok
  end

  test "put/3 with a name" do
    assert Index.put(@index, :name, "foo").name == "foo"
  end

  test "put/3 with a nil name" do
    assert_raise ArgumentError, fn ->
      Index.put(@index, :name, nil)
    end
  end

  test "put/3 with config tuple" do
    assert Index.put(@index, :config, @config).config == @config
  end

  test "put/3 with nil config" do
    assert Index.put(@index, :config, nil) == @index
  end

  test "put/3 with non-tuple" do
    assert_raise ArgumentError, fn ->
      Index.put(@index, :config, "foo")
    end
  end

  test "put_alias/1" do
    index1 = Index.put_alias(@index)
    assert index1.alias == @index.name
    assert Regex.match?(~r/^#{@index.name}-\d{13}$/, index1.name)

    index2 = Index.put_alias(index1)
    assert index2.alias == @index.name
    assert Regex.match?(~r/^#{@index.name}-\d{13}$/, index2.name)
  end
end
