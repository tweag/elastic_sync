defmodule ElasticSync.RepoTest do
  use ExUnit.Case
  doctest ElasticSync.Repo
  import Tirexs.HTTP

  defmodule Thing do
    defstruct [:id, :name]
    use ElasticSync.Schema, index: "elastic_sync_test", type: "things"

    def search_data(record) do
      Map.take(record, [:id, :name])
    end
  end

  defmodule Repo do
    use ElasticSync.Repo
  end

  defp find(id) do
    get("/elastic_sync_test/things/#{id}")
  end

  setup do
    {:ok, 200, _} = delete("/elastic_sync_test")
    {:ok, 200, _} = put("/elastic_sync_test")
    :ok
  end

  test "to_collection_url/1 generates a valid url" do
    assert Repo.to_collection_url(%Thing{}) == "/elastic_sync_test/things"
  end

  test "to_resource_url/2 generates a valid url" do
    assert Repo.to_resource_url(%Thing{id: 1}) == "/elastic_sync_test/things/1"
  end

  test "insert/1" do
    {:ok, 201, _} = Repo.insert(%Thing{id: 1})
    assert {:ok, 200, _} = find(1)
  end

  test "insert!" do
    Repo.insert!(%Thing{id: 1})
    assert {:ok, 200, _} = find(1)
  end

  test "update/1" do
    Repo.insert!(%Thing{id: 1})
    assert {:ok, 200, _} = Repo.update(%Thing{id: 1, name: "pasta"})
    {:ok, 200, %{_source: source}} = find(1)
    assert source == %{id: 1, name: "pasta"}
  end

  test "update!/1" do
    Repo.insert!(%Thing{id: 1})
    Repo.update!(%Thing{id: 1, name: "pasta"})
    {:ok, 200, %{_source: source}} = find(1)
    assert source == %{id: 1, name: "pasta"}
  end

  test "delete/1" do
    Repo.insert!(%Thing{id: 1})
    assert {:ok, 200, _} = Repo.delete(%Thing{id: 1, name: "pasta"})
    {:error, 404, _} = find(1)
  end

  test "delete!/1" do
    Repo.insert!(%Thing{id: 1})
    Repo.delete!(%Thing{id: 1, name: "pasta"})
    {:error, 404, _} = find(1)
  end

  test "insert_all/1" do
    Repo.insert_all(Thing, [
      %Thing{id: 1, name: "meatloaf"},
      %Thing{id: 2, name: "pizza"},
      %Thing{id: 3, name: "sausage"},
    ])

    {:ok, 200, %{hits: %{hits: hits}}} = get("/elastic_sync_test/things/_search")
    assert length(hits) == 3
  end
end
