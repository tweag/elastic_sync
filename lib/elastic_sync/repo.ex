defmodule ElasticSync.Repo do
  defmacro __using__(_opts) do
    quote do
      import Tirexs.Bulk
      import ElasticSync.Schema, only: [get_config: 2, get_index: 2, get_type: 2]

      alias Tirexs.{HTTP, Resources}

      def insert(record, opts \\ []) do
        record
        |> to_collection_url(opts)
        |> HTTP.post(%{id: record.id}, to_document(record))
      end

      def insert!(record, opts \\ []) do
        record
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
             {:ok, 200, _} <- refresh(schema, opts),
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

      # TODO: Allow developers to control mappings here
      def create_index(name) do
        HTTP.put("/#{name}")
      end

      def remove_index(name) do
        HTTP.delete("/#{name}")
      end

      def swap_alias(index_name, alias_name) do
        HTTP.post("/_aliases", %{
          actions: [
            %{ add: %{ index: alias_name, alias: index_name} }
          ]
        })
      end

      def refresh(schema, opts \\ []) do
        schema
        |> get_index(opts)
        |> Resources.bump._refresh
      end

      def to_collection_url(record, opts \\ []) do
        index = get_index(record.__struct__, opts)
        type = get_type(record.__struct__, opts)
        "/#{index}/#{type}"
      end

      def to_resource_url(record, opts \\ []) do
        "#{to_collection_url(record, opts)}/#{record.id}"
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
  end
end
