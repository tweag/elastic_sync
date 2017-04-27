defmodule ElasticSync.IndexTest do
  use ExUnit.Case, async: false

  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API
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

  test "create and remove" do
    Index.create(@index)
    assert Index.exists?(@index)

    Index.remove(@index)
    refute Index.exists?(@index)
  end

  test "load/2 and refresh/1" do
    Index.create(@index)
    Index.load(@index, [%{id: 1, name: "foo"}, %{id: 2, name: "bar"}])

    {:ok, _, %{hits: %{hits: hits}}} = HTTP.get("#{@index.name}/_search")
    assert length(hits) == 0

    Index.refresh(@index)
    {:ok, _, %{hits: %{hits: hits}}} = HTTP.get("#{@index.name}/_search")
    assert length(hits) == 2
  end

  test "replace_alias/1" do
    # Generate a new alias name
    index1 = Index.put_alias(@index)

    # Replace alias should point "elastic_sync_index_test"
    # at the timestamped index name.
    Index.create(index1)
    Index.replace_alias(index1)
    assert {:ok, _, resp} = HTTP.get(@index.name)
    assert Map.keys(resp) == [String.to_atom(index1.name)]

    # Swap to the next alias
    index2 = Index.put_alias(index1)
    Index.create(index2)
    Index.replace_alias(index2)

    assert {:ok, _, resp} = HTTP.get(@index.name)
    assert Map.keys(resp) == [String.to_atom(index2.name)]
  end

  test "clean_indicies/1" do
    index1 = Index.put_alias(@index)
    Index.create(index1)

    index2 = Index.put_alias(index1)
    Index.create(index2)

    {:ok, _, resp} = HTTP.get(API._aliases())
    assert Map.keys(resp) == [String.to_atom(index1.name), String.to_atom(index2.name)]

    Index.clean_indicies(index2)

    {:ok, _, resp} = HTTP.get(API._aliases())
    assert Map.keys(resp) == [String.to_atom(index2.name)]
  end

  test "transition/1" do
    {:ok, index1} = Index.transition(@index, fn _i -> :ok end)
    assert Index.exists?(index1)

    {:ok, index2} = Index.transition(@index, fn _i -> :ok end)
    refute Index.exists?(index1)
    assert Index.exists?(index2)
  end
end
