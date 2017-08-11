defmodule ElasticSync.SyncRepoTest do
  use ExUnit.Case, async: false

  doctest ElasticSync.SyncRepo

  alias ElasticSync.{Thing, TestRepo, TestSyncRepo}

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

  test "update! with a changeset" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    changeset = Thing.changeset(thing, %{"name" => "pears"})
    assert %Thing{name: "pears"} = TestSyncRepo.update!(changeset)
  end

  test "update! with an invalid changeset" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    changeset = Thing.changeset(thing, %{"name" => ""})

    assert_raise Ecto.InvalidChangesetError, fn ->
      TestSyncRepo.update!(changeset)
    end
  end

  test "delete" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    assert {:ok, _} = TestSyncRepo.delete(thing)
  end

  test "delete with a changeset" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    assert {:ok, _} = TestSyncRepo.delete(Thing.changeset(thing))
  end

  test "delete!" do
    thing = TestSyncRepo.insert!(%Thing{name: "meatloaf"})
    assert %Thing{name: "meatloaf"} = TestSyncRepo.delete!(thing)
  end

  test "reindex" do
    TestRepo.insert!(%Thing{name: "one"})
    TestRepo.insert!(%Thing{name: "two"})
    TestRepo.insert!(%Thing{name: "three"})

    assert {:ok, _} = TestSyncRepo.reindex(Thing)
    assert {:ok, _, %{hits: %{hits: hits}}} = ElasticSync.Repo.search(Thing)
    assert length(hits) == 3
  end
end
