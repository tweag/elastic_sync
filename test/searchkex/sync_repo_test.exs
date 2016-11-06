defmodule Searchkex.SyncRepoTest do
  use ExUnit.Case
  doctest Searchkex.SyncRepo

  alias Searchkex.TestSyncRepo

  defmodule Thing do
    use Ecto.Schema
    import Ecto.Changeset
    use Searchkex.Schema, index: "searchkex_test", type: "things"

    schema "things" do
      field :name, :string
    end

    def search_data(record) do
      Map.take(record, [:id, :name])
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:name])
      |> validate_required([:name])
    end
  end

  setup do
    {:ok, 200, _} = Tirexs.HTTP.delete("/searchkex_test")
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Searchkex.TestRepo)
  end

  test "insert with a struct" do
    assert {:ok, %Thing{id: _}} = TestSyncRepo.insert(%Thing{name: "meatloaf"})
  end

  test "insert with a changeset" do
    changeset = Thing.changeset(%Thing{name: "meatloaf"})
    assert {:ok, %Thing{id: _}} = TestSyncRepo.insert(changeset)
  end

  test "insert with invalid changeset" do
    changeset = Thing.changeset(%Thing{})
    assert {:error, _} = TestSyncRepo.insert(changeset)
  end

  test "update with a changeset" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    changeset = Thing.changeset(thing, %{"name" => "pears"})
    assert {:ok, %Thing{name: "pears"}} = TestSyncRepo.update(changeset)
  end

  test "update with invalid changeset" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    changeset = Thing.changeset(thing, %{"name" => ""})
    assert {:error, _} = TestSyncRepo.update(changeset)
  end

  test "delete" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    assert {:ok, _} = TestSyncRepo.delete(thing)
  end

  test "delete with a changeset" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    assert {:ok, _} = TestSyncRepo.delete(Thing.changeset(thing))
  end
end
