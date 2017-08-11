defmodule ElasticSync.SyncRepo do
  alias ElasticSync.{Repo, Reindex}

  defmacro __using__(opts) do
    ecto = Keyword.fetch!(opts, :ecto)

    quote do
      @ecto unquote(ecto)

      def __elastic_sync__(:ecto), do: @ecto

      def insert(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.insert(@ecto, struct_or_changeset, opts)
      end

      def insert!(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.insert!(@ecto, struct_or_changeset, opts)
      end

      def update(changeset, opts \\ []) do
        ElasticSync.SyncRepo.update(@ecto, changeset, opts)
      end

      def update!(changeset, opts \\ []) do
        ElasticSync.SyncRepo.update!(@ecto, changeset, opts)
      end

      def delete(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.delete(@ecto, struct_or_changeset, opts)
      end

      def delete!(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.delete!(@ecto, struct_or_changeset, opts)
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        ElasticSync.SyncRepo.insert_all(@ecto, schema_or_source, entries, opts)
      end

      def reindex(schema, opts \\ []) do
        ElasticSync.SyncRepo.reindex(@ecto, schema, opts)
      end
    end
  end

  def insert(ecto, struct_or_changeset, opts \\ []) do
    sync_one(ecto, :insert, [struct_or_changeset, opts])
  end

  def insert!(ecto, struct_or_changeset, opts \\ []) do
    sync_one!(ecto, :insert!, [struct_or_changeset, opts])
  end

  def update(ecto, changeset, opts \\ []) do
    sync_one(ecto, :update, [changeset, opts])
  end

  def update!(ecto, changeset, opts \\ []) do
    sync_one!(ecto, :update!, [changeset, opts])
  end

  def delete(ecto, struct_or_changeset, opts \\ []) do
    sync_one(ecto, :delete, [struct_or_changeset, opts])
  end

  def delete!(ecto, struct_or_changeset, opts \\ []) do
    sync_one!(ecto, :delete!, [struct_or_changeset, opts])
  end

  def insert_all(ecto, schema_or_source, entries, opts \\ []) do
    with {:ok, records} <- ecto.insert_all(schema_or_source, entries, opts),
         {:ok, _, _} <- Repo.insert_all(schema_or_source, records),
         do: {:ok, records}
  end

  def reindex(ecto, schema, opts \\ []) do
    Reindex.run(ecto, schema, opts)
  end

  defp sync_one(ecto, action, args) do
    with {:ok, record} <- apply(ecto, action, args),
         {:ok, _, _} <- apply(Repo, action, [record]),
         do: {:ok, record}
  end

  defp sync_one!(ecto, action, args) do
    result = apply(ecto, action, args)
    apply(Repo, action, [result])
    result
  end
end
