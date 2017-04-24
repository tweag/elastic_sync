defmodule ElasticSyncTest do
  use ExUnit.Case, async: false

  import Tirexs.HTTP

  doctest ElasticSync

  test "es_version/0" do
    {:ok, 200, %{version: %{number: version}}} = get("/")
    assert ElasticSync.version() == version
  end
end
