defmodule Searchkex.Repo do
  import Tirexs.{Bulk, HTTP}

  defmacro __using__(_opts) do
    quote do
      import Searchkex.Repo
    end
  end

  def insert(record) do
    record
    |> to_url
    |> post(%{id: record.id}, to_payload(record))
  end

  def insert!(record) do
    record
    |> to_url
    |> post!(%{id: record.id}, to_payload(record))
  end

  def update(record) do
    record
    |> to_url([record.id])
    |> put(to_payload(record))
  end

  def update!(record) do
    record
    |> to_url([record.id])
    |> put!(to_payload(record))
  end

  def insert_all(schema, records) when is_list(records) do
    payload = bulk([
      index: schema.searchkex_index_name,
      type: schema.searchkex_index_type
    ]) do
      index Enum.map(records, &to_reindex_payload/1)
    end

    Tirexs.bump!(payload)._bulk()
  end

  def refresh(schema) do
    Tirexs.Resources.bump._refresh(schema.searchkex_index_name)
  end

  def to_url(record, extra) when is_list(extra) do
    to_url(record) <> "/" <> Enum.join(extra, "/")
  end
  def to_url(record) do
    "/#{get_index_name(record)}/#{get_index_type(record)}"
  end

  defp get_index_name(record) do
    record.__struct__.searchkex_index_name
  end

  defp get_index_type(record) do
    record.__struct__.searchkex_index_type
  end

  defp to_payload(record) do
    record.__struct__.searchkex_serialize(record)
  end

  # Tirexs only accepts a list for bulk
  defp to_reindex_payload(record) do
    payload = to_payload(record)

    cond do
      is_list(payload) ->
        payload
      true ->
        Enum.into(payload, [])
    end
  end
end
