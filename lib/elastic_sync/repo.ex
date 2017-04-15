defmodule ElasticSync.Repo do
  import Tirexs.Bulk
  import ElasticSync.Schema, only: [get_config: 2, get_index: 2, get_type: 2]

  alias ElasticSync.Index
  alias Tirexs.HTTP

  def search(queryable, query, opts \\ [])
  def search(queryable, query, opts) when is_binary(query) do
    queryable
    |> to_search_url(opts)
    |> HTTP.get(%{q: query})
  end
  def search(queryable, [search: query] = dsl, opts) do
    opts =
      dsl
      |> Keyword.take([:index, :type])
      |> Keyword.merge(opts)

    search(queryable, query, opts)
  end
  def search(queryable, query, opts) do
    queryable
    |> to_search_url(opts)
    |> HTTP.post(query)
  end

  def insert(record, opts \\ []) do
    record.__struct__
    |> to_collection_url(opts)
    |> HTTP.post(%{id: record.id}, to_document(record))
  end

  def insert!(record, opts \\ []) do
    record.__struct__
    |> to_collection_url(opts)
    |> HTTP.post!(%{id: record.id}, to_document(record))
  end

  def update(record, opts \\ []) do
    record
    |> to_resource_url(opts)
    |> HTTP.put(to_document(record))
  end

  def update!(record, opts \\ []) do
    record
    |> to_resource_url(opts)
    |> HTTP.put!(to_document(record))
  end

  def delete(record, opts \\ []) do
    record
    |> to_resource_url(opts)
    |> HTTP.delete!
  end

  def delete!(record, opts \\ []) do
    record
    |> to_resource_url(opts)
    |> HTTP.delete!
  end

  def insert_all(schema, records, opts \\ []) when is_list(records) do
    with {:ok, 200, response} <- bulk_index(schema, records, opts),
         {:ok, 200, _} <- Index.refresh(get_index(schema, opts)),
         do: {:ok, 200, response}
  end

  def bulk_index(schema, records, opts \\ []) when is_list(records) do
    data = Enum.map(records, &to_reindex_document/1)

    payload =
      schema
      |> get_config(opts)
      |> bulk(do: index(data))

    Tirexs.bump!(payload)._bulk()
  end

  def to_search_url(queryable, opts \\ []) do
    to_collection_url(queryable, opts) <> "/_search"
  end

  def to_collection_url(queryable, opts \\ []) do
    index = get_index(queryable, opts)
    type = get_type(queryable, opts)
    "/#{index}/#{type}"
  end

  def to_resource_url(record, opts \\ []) do
    "#{to_collection_url(record.__struct__, opts)}/#{record.id}"
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
