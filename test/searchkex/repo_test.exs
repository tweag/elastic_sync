defmodule Searchkex.RepoTest do
  use ExUnit.Case
  doctest Searchkex.Repo

  alias Searchkex.Repo
  import Tirexs.HTTP

  defmodule Thing do
    defstruct [:id, :name]
    def searchkex_index_name, do: "searchkex_test"
    def searchkex_index_type, do: "things"
    def searchkex_serialize(record) do
      Map.from_struct(record)
    end
  end

  defp find(id), do: get("/searchkex_test/things/#{id}")

  setup do
    delete("/searchkex_test")
    :ok
  end

  test "to_url/1 generates a valid url" do
    assert Repo.to_url(%Thing{}) == "/searchkex_test/things"
  end

  test "to_url/2 generates a valid url" do
    assert Repo.to_url(%Thing{}, [1]) == "/searchkex_test/things/1"
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

  test "insert_all/1" do
    Repo.insert_all(Thing, [
      %Thing{id: 1, name: "meatloaf"},
      %Thing{id: 2, name: "pizza"},
      %Thing{id: 3, name: "sausage"},
    ])

    Repo.refresh(Thing)
    {:ok, 200, %{hits: %{hits: hits}}} = get("/searchkex_test/things/_search")
    assert length(hits) == 3
  end
end
