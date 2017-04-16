defmodule ElasticSync.SyncRepoTest do
  use ExUnit.Case, async: false

  doctest ElasticSync.SyncRepo

  alias ElasticSync.{Thing, TestSyncRepo}

  setup do
    Tirexs.HTTP.delete!("*")
    Tirexs.HTTP.put!("elastic_sync_test")
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ElasticSync.TestRepo)
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
