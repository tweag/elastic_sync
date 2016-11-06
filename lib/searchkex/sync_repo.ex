defmodule Searchkex.SyncRepo do
  defmacro __using__([ecto: ecto, search: search]) do
    quote do
      @ecto unquote(ecto)
      @search unquote(search)

      def __searchkex__(:ecto), do: @ecto
      def __searchkex__(:search), do: @search

      def insert(struct_or_changeset, opts \\ []) do
        sync_one(:insert, 201, struct_or_changeset, opts)
      end

      def insert!(struct_or_changeset, opts \\ []) do
        sync_one!(:insert!, 201, struct_or_changeset, opts)
      end

      def update(changeset, opts \\ []) do
        sync_one(:update, 200, changeset, opts)
      end

      def update!(changeset, opts \\ []) do
        sync_one!(:update!, 200, changeset, opts)
      end

      def delete(struct_or_changeset, opts \\ []) do
        sync_one(:delete, 200, struct_or_changeset, opts)
      end

      def delete!(struct_or_changeset, opts \\ []) do
        sync_one!(:delete!, 200, struct_or_changeset, opts)
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        with {:ok, records} <- @ecto.insert_all(schema_or_source, entries, opts),
             {:ok, 200, _} <- @search.insert_all(schema_or_source, records),
             do: {:ok, records}
      end

      defp sync_one(action, status, struct_or_changeset, opts \\ []) do
        with {:ok, record} <- apply(@ecto, action, [struct_or_changeset, opts]),
             {:ok, ^status, response} <- apply(@search, action, [record]),
            do: {:ok, record}
      end

      defp sync_one!(action, status, struct_or_changeset, opts \\ []) do
        result = apply(@ecto, action, [struct_or_changeset, opts])
        apply(@search, action, [result])
        result
      end
    end
  end
end
