defmodule Searchkex.Repo do
  import Tirexs.{Bulk, HTTP}
  import Searchkex.Schema, only: [get_config: 1, get_index: 1]

  defmacro __using__(_opts) do
    quote do
      import Searchkex.Repo
    end
  end

  def insert(record) do
    record
    |> to_collection_url
    |> post(%{id: record.id}, to_document(record))
  end

  def insert!(record) do
    record
    |> to_collection_url
    |> post!(%{id: record.id}, to_document(record))
  end

  def update(record) do
    record
    |> to_resource_url
    |> put(to_document(record))
  end

  def update!(record) do
    record
    |> to_resource_url
    |> put!(to_document(record))
  end

  def insert_all(schema, records) when is_list(records) do
    data = Enum.map(records, &to_reindex_document/1)
    payload =
      schema
      |> get_config
      |> bulk(do: index(data))

    Tirexs.bump!(payload)._bulk()
    refresh(schema)
  end

  def refresh(schema) do
    schema
    |> get_index
    |> Tirexs.Resources.bump._refresh
  end

  def to_collection_url(record) do
    config = get_config(record.__struct__)
    "/#{config.index}/#{config.type}"
  end

  def to_resource_url(record) do
    "#{to_collection_url(record)}/#{record.id}"
  end

  def to_document(record) do
    record.__struct__.search_data(record)
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
