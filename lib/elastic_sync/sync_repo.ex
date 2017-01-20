defmodule ElasticSync.SyncRepo do
  defmacro __using__(opts) do
    ecto = Keyword.fetch!(opts, :ecto)
    search = Keyword.get(opts, :search, ElasticSync.Repo)

    quote do
      import ElasticSync.Schema, only: [get_index: 1, get_alias: 1]

      @ecto unquote(ecto)
      @search unquote(search)

      def __elastic_sync__(:ecto), do: @ecto
      def __elastic_sync__(:search), do: @search

      def insert(struct_or_changeset, opts \\ []) do
        sync_one(:insert, struct_or_changeset, opts)
      end

      def insert!(struct_or_changeset, opts \\ []) do
        sync_one!(:insert!, struct_or_changeset, opts)
      end

      def update(changeset, opts \\ []) do
        sync_one(:update, changeset, opts)
      end

      def update!(changeset, opts \\ []) do
        sync_one!(:update!, changeset, opts)
      end

      def delete(struct_or_changeset, opts \\ []) do
        sync_one(:delete, struct_or_changeset, opts)
      end

      def delete!(struct_or_changeset, opts \\ []) do
        sync_one!(:delete!, struct_or_changeset, opts)
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        with {:ok, records} <- @ecto.insert_all(schema_or_source, entries, opts),
             {:ok, _, _} <- @search.insert_all(schema_or_source, records),
             do: {:ok, records}
      end

      def reindex(schema) do
        records = @ecto.all(schema)
        index_name = get_index(schema)
        alias_name = get_alias(schema)

        # Create a new index with the name of the alias
        {:ok, _, _} = @search.create_index(alias_name)

        # Populate the new index
        {:ok, _, _} = @search.bulk_index(schema, records, index: alias_name)

        # Refresh the index
        {:ok, _, _} = @search.refresh(schema, index: alias_name)

        # Alias our new index as the old index
        {:ok, _, _} = @search.swap_alias(index_name, alias_name)
      end

      defp sync_one(action, struct_or_changeset, opts \\ []) do
        with {:ok, record} <- apply(@ecto, action, [struct_or_changeset, opts]),
             {:ok, _, response} <- apply(@search, action, [record]),
            do: {:ok, record}
      end

      defp sync_one!(action, struct_or_changeset, opts \\ []) do
        result = apply(@ecto, action, [struct_or_changeset, opts])
        apply(@search, action, [result])
        result
      end
    end
  end
end
