defmodule ElasticSync.Index.HTTPTest do
  use ExUnit.Case, async: false

  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API
  alias ElasticSync.Index

  @index %Index{
    name: "elastic_sync_index_test",
    type: "elastic_sync_index_test"
  }

  @search "#{@index.name}/_search"

  setup do
    HTTP.delete!("*")
    :ok
  end

  test "create and remove" do
    assert {:ok, _, _} = Index.HTTP.create(@index)
    assert Index.HTTP.exists?(@index)

    assert {:ok, _, _} = Index.HTTP.remove(@index)
    refute Index.HTTP.exists?(@index)
  end

  test "load/2 and refresh/1" do
    assert {:ok, _, _} = Index.HTTP.create(@index)
    assert {:ok, _, _} = Index.HTTP.load(@index, [%{id: 1, name: "foo"}, %{id: 2, name: "bar"}])

    {:ok, _, %{hits: %{hits: hits}}} = HTTP.get(@search)
    assert length(hits) == 0

    Index.HTTP.refresh(@index)
    {:ok, _, %{hits: %{hits: hits}}} = HTTP.get(@search)
    assert length(hits) == 2
  end

  test "replace_alias/1" do
    # Generate a new alias name
    index1 = Index.put_alias(@index)

    # Replace alias should point "elastic_sync_index_test"
    # at the timestamped index name.
    Index.HTTP.create(index1)
    Index.HTTP.replace_alias(index1)
    assert {:ok, _, resp} = HTTP.get(@index.name)
    assert Map.keys(resp) == [String.to_atom(index1.name)]

    # Swap to the next alias
    index2 = Index.put_alias(index1)
    assert {:ok, _, _} = Index.HTTP.create(index2)
    assert {:ok, _, _} = Index.HTTP.replace_alias(index2)

    assert {:ok, _, resp} = HTTP.get(@index.name)
    assert Map.keys(resp) == [String.to_atom(index2.name)]
  end

  test "clean_indicies/1" do
    index1 = Index.put_alias(@index)
    Index.HTTP.create(index1)

    index2 = Index.put_alias(index1)
    Index.HTTP.create(index2)

    {:ok, _, resp} = HTTP.get(API._aliases())
    assert Map.keys(resp) == [String.to_atom(index1.name), String.to_atom(index2.name)]

    Index.HTTP.clean_indicies(index2)

    {:ok, _, resp} = HTTP.get(API._aliases())
    assert Map.keys(resp) == [String.to_atom(index2.name)]
  end

  test "transition/1" do
    assert {:ok, index1} = Index.HTTP.transition(@index, fn _i -> :ok end)
    assert Index.HTTP.exists?(index1)

    assert {:ok, index2} = Index.HTTP.transition(@index, fn _i -> :ok end)
    refute Index.HTTP.exists?(index1)
    assert Index.HTTP.exists?(index2)
  end
end
