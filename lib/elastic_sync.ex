defmodule ElasticSync do
  import Tirexs.HTTP

  def es_version do
    {:ok, 200, %{version: %{number: version}}} = get!("/")
    version
  end
end
