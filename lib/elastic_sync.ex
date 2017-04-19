defmodule ElasticSync do
  import Tirexs.HTTP

  def version do
    {:ok, 200, info} = get("/")
    info.version
  end
end
