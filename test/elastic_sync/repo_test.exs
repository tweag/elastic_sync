defmodule ElasticSync.RepoTest do
  use ExUnit.Case
  import Tirexs.HTTP

  alias ElasticSync.TestSearchRepo

  doctest ElasticSync.Repo

  defmodule Thing do
    defstruct [:id, :name]
    use ElasticSync.Schema, index: "elastic_sync_test", type: "things"

    def to_search_document(struct) do
      Map.take(struct, [:id, :name])
    end
  end

  defp find(id) do
    get("/elastic_sync_test/things/#{id}")
  end

  setup do
    delete("/elastic_sync_test")
    put("/elastic_sync_test")
    :ok
  end

  test "to_collection_url/1 generates a valid url" do
    assert TestSearchRepo.to_collection_url(%Thing{}) == "/elastic_sync_test/things"
  end

  test "to_resource_url/2 generates a valid url" do
    assert TestSearchRepo.to_resource_url(%Thing{id: 1}) == "/elastic_sync_test/things/1"
  end

  test "insert/1" do
    {:ok, 201, _} = TestSearchRepo.insert(%Thing{id: 1})
    assert {:ok, 200, _} = find(1)
  end

  test "insert!" do
    TestSearchRepo.insert!(%Thing{id: 1})
    assert {:ok, 200, _} = find(1)
  end

  test "update/1" do
    TestSearchRepo.insert!(%Thing{id: 1})
    assert {:ok, 200, _} = TestSearchRepo.update(%Thing{id: 1, name: "pasta"})
    {:ok, 200, %{_source: source}} = find(1)
    assert source == %{id: 1, name: "pasta"}
  end

  test "update!/1" do
    TestSearchRepo.insert!(%Thing{id: 1})
    TestSearchRepo.update!(%Thing{id: 1, name: "pasta"})
    {:ok, 200, %{_source: source}} = find(1)
    assert source == %{id: 1, name: "pasta"}
  end

  test "delete/1" do
    TestSearchRepo.insert!(%Thing{id: 1})
    assert {:ok, 200, _} = TestSearchRepo.delete(%Thing{id: 1, name: "pasta"})
    {:error, 404, _} = find(1)
  end

  test "delete!/1" do
    TestSearchRepo.insert!(%Thing{id: 1})
    TestSearchRepo.delete!(%Thing{id: 1, name: "pasta"})
    {:error, 404, _} = find(1)
  end

  test "insert_all/1" do
    TestSearchRepo.insert_all(Thing, [
      %Thing{id: 1, name: "meatloaf"},
      %Thing{id: 2, name: "pizza"},
      %Thing{id: 3, name: "sausage"},
    ])

    {:ok, 200, %{hits: %{hits: hits}}} = get("/elastic_sync_test/things/_search")
    assert length(hits) == 3
  end
end
