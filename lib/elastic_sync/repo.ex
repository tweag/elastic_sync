defmodule ElasticSync.Repo do
  import Tirexs.Bulk

  alias ElasticSync.Index
  alias Tirexs.HTTP
  alias Tirexs.Resources.APIs, as: API

  def search(schema, query, opts \\ [])
  def search(schema, query, opts) when is_binary(query) do
    schema
    |> to_search_url(opts)
    |> HTTP.get(%{q: query})
  end
  def search(schema, [search: query] = dsl, opts) do
    opts =
      dsl
      |> Keyword.take([:index, :type])
      |> Keyword.merge(opts)

    search(schema, query, opts)
  end
  def search(schema, query, opts) do
    schema
    |> to_search_url(opts)
    |> HTTP.post(query)
  end

  def insert(record, opts \\ []) do
    record.__struct__
    |> to_index_url(opts)
    |> HTTP.post(%{id: record.id}, to_document(record))
  end

  def insert!(record, opts \\ []) do
    record.__struct__
    |> to_index_url(opts)
    |> HTTP.post!(%{id: record.id}, to_document(record))
  end

  def update(record, opts \\ []) do
    record
    |> to_document_url(opts)
    |> HTTP.put(to_document(record))
  end

  def update!(record, opts \\ []) do
    record
    |> to_document_url(opts)
    |> HTTP.put!(to_document(record))
  end

  def delete(record, opts \\ []) do
    record
    |> to_document_url(opts)
    |> HTTP.delete!
  end

  def delete!(record, opts \\ []) do
    record
    |> to_document_url(opts)
    |> HTTP.delete!
  end

  def insert_all(schema, records, opts \\ []) when is_list(records) do
    index_name =
      schema.__elastic_sync__
      |> Index.merge(opts)
      |> Index.to_list
      |> Keyword.get(:index)

    with {:ok, 200, response} <- bulk_index(schema, records, opts),
         {:ok, 200, _} <- Index.refresh(index_name),
         do: {:ok, 200, response}
  end

  def bulk_index(schema, records, opts \\ []) when is_list(records) do
    data = Enum.map(records, &to_reindex_document/1)

    payload =
      schema.__elastic_sync__
      |> Index.merge(opts)
      |> Map.take([:index, :type])
      |> Map.to_list()
      |> bulk(do: index(data))

    Tirexs.bump!(payload)._bulk()
  end

  def to_search_url(schema, opts \\ []) do
    url_for(:_search, schema, opts)
  end

  def to_index_url(schema, opts \\ []) do
    url_for(:index, schema, opts)
  end

  def to_document_url(record, opts \\ []) do
    url_for(:doc, record.__struct__, opts, [record.id])
  end

  def to_document(record) do
    record.__struct__.to_search_document(record)
  end

  defp url_for(fun_name, schema, opts, paths \\ []) do
    index = Index.merge(schema.__elastic_sync__, opts)
    apply(API, fun_name, [index.name, index.type] ++ paths)
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
