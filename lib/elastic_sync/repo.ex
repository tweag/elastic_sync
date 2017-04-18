defmodule ElasticSync.Repo do
  alias ElasticSync.Index
  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API

  def search(schema, query) when is_binary(query) do
    schema
    |> to_search_url()
    |> HTTP.get(%{q: query})
  end
  def search(schema, [search: query]) do
    search(schema, query)
  end
  def search(schema, query) do
    schema
    |> to_search_url()
    |> HTTP.post(query)
  end

  def insert(record) do
    record.__struct__
    |> to_index_url()
    |> HTTP.post(%{id: record.id}, to_document(record))
  end

  def insert!(record) do
    record.__struct__
    |> to_index_url()
    |> HTTP.post!(%{id: record.id}, to_document(record))
  end

  def update(record) do
    record
    |> to_document_url()
    |> HTTP.put(to_document(record))
  end

  def update!(record) do
    record
    |> to_document_url()
    |> HTTP.put!(to_document(record))
  end

  def delete(record) do
    record
    |> to_document_url()
    |> HTTP.delete!
  end

  def delete!(record) do
    record
    |> to_document_url()
    |> HTTP.delete!
  end

  def insert_all(schema, records) when is_list(records) do
    with {:ok, 200, response} <- bulk_index(schema, records),
         {:ok, 200, _} <- Index.refresh(schema.__elastic_sync__),
         do: {:ok, 200, response}
  end

  def bulk_index(schema, records) when is_list(records) do
    data = Enum.map(records, &to_reindex_document/1)
    Index.load(schema.__elastic_sync__, data)
  end

  def to_search_url(schema) do
    url_for(:_search, schema)
  end

  def to_index_url(schema) do
    url_for(:index, schema)
  end

  def to_document_url(record) do
    url_for(:doc, record.__struct__, [record.id])
  end

  defp url_for(fun_name, schema, paths \\ []) do
    index = schema.__elastic_sync__
    apply(API, fun_name, [index.name, index.type] ++ paths)
  end

  def to_document(record) do
    record.__struct__.to_search_document(record)
  end

  # Tirexs only accepts a list for bulk
  defp to_reindex_document(record) do
    document = to_document(record)

    cond do
      is_list(document) ->
        document
      true ->
        Enum.into(document, [])
    end
  end
end
