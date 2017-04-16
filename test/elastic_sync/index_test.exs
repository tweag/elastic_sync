defmodule ElasticSync.IndexTest do
  use ExUnit.Case

  alias Tirexs.HTTP
  alias ElasticSync.Index

  @index "elastic_sync_index_test"

  setup do
    HTTP.delete!("/*")
    :ok
  end

  test "get_alias/1" do
    re   = ~r/^#{@index}-\d{13}$/
    name = Index.get_new_alias_name(@index)

    assert Regex.match?(re, name)
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

  test "remove_indicies/1" do
    first = Index.get_new_alias_name(@index)
    {:ok, _, _} = Index.create(first)
    {:ok, _, _} = Index.replace_alias(@index, index: first)

    second = Index.get_new_alias_name(@index)
    {:ok, _, _} = Index.create(second)
    {:ok, _, _} = Index.replace_alias(@index, index: second)

    assert {:ok, _, _} = Index.remove_indicies(@index, except: [second])

    assert Index.exists?(@index)
    assert Index.exists?(second)
    refute Index.exists?(first)
  end
end
