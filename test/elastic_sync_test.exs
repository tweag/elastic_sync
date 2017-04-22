defmodule ElasticSyncTest do
  use ExUnit.Case, async: false

  import Tirexs.HTTP

  doctest ElasticSync

  test "get version" do
    {:ok, 200, info} = get("/")
    assert info.version == ElasticSync.version()
  end
end
