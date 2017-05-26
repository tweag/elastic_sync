defmodule ElasticSync.RepoTest do
  use ExUnit.Case, async: false

  alias Tirexs.HTTP
  alias ElasticSync.Repo

  doctest ElasticSync.Repo

  defmodule Thing do
    defstruct [:id, :name]

    use ElasticSync.Index,
      index: "elastic_sync_repo_test",
      type: "things"

    def to_search_document(struct) do
      Map.take(struct, [:id, :name])
    end
  end

  defp find(id) do
    HTTP.get("/elastic_sync_repo_test/things/#{id}")
  end

  setup do
    HTTP.delete!("*")
    HTTP.put!("elastic_sync_test")
    :ok
  end

  test "to_index_url/1 generates a valid url" do
    assert Repo.to_index_url(Thing) == "elastic_sync_repo_test/things"
  end

  test "to_document_url/1 generates a valid url" do
    assert Repo.to_document_url(%Thing{id: 1}) == "elastic_sync_repo_test/things/1"
  end

  test "insert/1" do
    assert {:ok, 201, _} = Repo.insert(%Thing{id: 1})
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
    assert {:error, 404, _} = find(1)
  end

  test "delete!/1" do
    Repo.insert!(%Thing{id: 1})
    Repo.delete!(%Thing{id: 1, name: "pasta"})
    {:error, 404, _} = find(1)
  end

  test "insert_all/1" do
    Repo.insert_all Thing, [
      %Thing{id: 1, name: "meatloaf"},
      %Thing{id: 2, name: "pizza"},
      %Thing{id: 3, name: "sausage"},
    ]

    {:ok, 200, %{hits: %{hits: hits}}} = HTTP.get("/elastic_sync_repo_test/things/_search")
    assert length(hits) == 3
  end

  test "search/3" do
    Repo.insert_all Thing, [
      %Thing{id: 1, name: "meatloaf"},
      %Thing{id: 2, name: "pizza"}
    ]

    {:ok, 200, %{hits: %{hits: hits}}} = Repo.search(Thing, "meatloaf")
    assert length(hits) == 1
  end

  test "search/3 with map" do
    Repo.insert_all Thing, [
      %Thing{id: 1, name: "meatloaf"},
      %Thing{id: 2, name: "pizza"}
    ]

    query = %{query: %{bool: %{must: [%{match: %{name: "meatloaf"}}]}}}
    {:ok, 200, %{hits: %{hits: hits}}} = Repo.search(Thing, query)
    assert length(hits) == 1
  end

  test "search/3 with DSL" do
    import Tirexs.Search

    Repo.insert_all Thing, [
      %Thing{id: 1, name: "meatloaf"},
      %Thing{id: 2, name: "pizza"}
    ]

    query = search do
      query do
        bool do
          must do
            match "name", "meatloaf"
          end
        end
      end
    end

    {:ok, 200, %{hits: %{hits: hits}}} = Repo.search(Thing, query)
    assert length(hits) == 1
  end
end
