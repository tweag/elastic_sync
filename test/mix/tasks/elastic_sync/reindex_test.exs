defmodule Mix.Tasks.ElasticSync.ReindexTest do
  use ExUnit.Case
  import Tirexs.HTTP

  alias Mix.Tasks.ElasticSync.Reindex
  alias ElasticSync.{TestRepo, Thing}

  setup do
    Tirexs.HTTP.delete("/elastic_sync_test")
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ElasticSync.TestRepo)
  end

  test "it works" do
    one = TestRepo.insert(%Thing{name: "one"})
    two = TestRepo.insert(%Thing{name: "two"})
    three = TestRepo.insert(%Thing{name: "three"})

    Reindex.run(["ElasticSync.TestSyncRepo", "ElasticSync.Thing"])

    {:ok, _, _} = get("/elastic_sync_test/_search")
  end
end
