defmodule Mix.Tasks.ElasticSync.ReindexTest do
  use ExUnit.Case
  import Tirexs.HTTP

  alias Mix.Tasks.ElasticSync.Reindex
  alias ElasticSync.{TestRepo, Thing}

  setup do
    Tirexs.HTTP.delete("/elastic_sync_test")
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ElasticSync.TestRepo)
  end

  test "reindexes the index" do
    TestRepo.insert(%Thing{name: "one"})
    TestRepo.insert(%Thing{name: "two"})
    TestRepo.insert(%Thing{name: "three"})

    Reindex.run(["ElasticSync.TestSyncRepo", "ElasticSync.Thing"])

    {:ok, _, _} = get("/elastic_sync_test/_search")
  end
end
