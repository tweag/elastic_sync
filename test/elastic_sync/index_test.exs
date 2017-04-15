defmodule ElasticSync.IndexTest do
  use ExUnit.Case

  alias Tirexs.HTTP
  alias ElasticSync.Index

  @index "elastic_sync_index_test"

  setup do
    {:ok, _, _} = HTTP.delete("/*")
    :ok
  end

  test "get_alias/1" do
    assert Regex.match?(~r"#{@index}-\d{10}", Index.get_new_alias_name(@index))
  end

  test "create/1" do
    assert {:error, _, _} = HTTP.get(@index)
    {:ok, _, _} = Index.create(@index)
    assert {:ok, _, _} = HTTP.get(@index)
  end

  test "replace_alias/2" do
    {:ok, _, _} = Index.create("foo")
    {:ok, _, _} = Index.replace_alias(@index, index: "foo")
    assert {:ok, _, _} = HTTP.get("/#{@index}")
  end

  test "clean_aliases/1" do
    {:ok, _, _} = Index.create("foo")
    {:ok, _, _} = Index.replace_alias(@index, index: "foo")

    {:ok, _, _} = Index.create("bar")
    {:ok, _, _} = Index.replace_alias(@index, index: "bar")

    # HTTP.get("/_")
  end
end
