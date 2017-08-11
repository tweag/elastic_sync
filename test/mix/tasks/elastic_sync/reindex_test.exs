defmodule Mix.Tasks.ElasticSync.ReindexTest do
  use ExUnit.Case, async: false

  alias Tirexs.HTTP
  alias Mix.Tasks.ElasticSync.Reindex
  alias ElasticSync.{TestRepo, Thing}

  @index "elastic_sync_thing"
  @search "/#{@index}/_search"
  @aliases "/_aliases"

  setup do
    Tirexs.HTTP.delete!("*")
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ElasticSync.TestRepo)
  end

  setup do
    TestRepo.insert!(%Thing{name: "one"})
    TestRepo.insert!(%Thing{name: "two"})
    TestRepo.insert!(%Thing{name: "three"})
    :ok
  end

  defp reindex! do
    # ExUnit.CaptureIO.capture_io fn ->
      assert :ok == Reindex.run(["ElasticSync.TestSyncRepo", "ElasticSync.Thing"])
    # end
  end

  describe "the first reindex" do
    test "creates an index" do
      reindex!()

      assert {:ok, _, _} = HTTP.get(@index)
    end

    test "loads the data" do
      reindex!()
      assert {:ok, _, %{hits: %{hits: hits}}} = HTTP.get(@search)
      assert length(hits) == 3
    end
  end

  describe "after the first reindex" do
    test "creates a new alias for the index" do
      reindex!()
      assert {:ok, _, phase1} = HTTP.get(@aliases)

      reindex!()
      assert {:ok, _, phase2} = HTTP.get(@aliases)
      refute Map.keys(phase1) == Map.keys(phase2)
    end

    test "reloads the data" do
      reindex!()
      assert {:ok, _, %{hits: %{hits: hits}}} = HTTP.get(@search)
      assert length(hits) == 3

      TestRepo.insert!(%Thing{name: "four"})

      reindex!()
      assert {:ok, _, %{hits: %{hits: hits}}} = HTTP.get(@search)
      assert length(hits) == 4
    end
  end
end
