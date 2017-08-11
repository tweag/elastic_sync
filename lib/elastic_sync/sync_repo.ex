defmodule ElasticSync.SyncRepo do
  alias ElasticSync.{Repo, Reindex}

  defmacro __using__(opts) do
    ecto = Keyword.fetch!(opts, :ecto)

    quote do
      def __elastic_sync__(:ecto), do: unquote(ecto)

      def insert(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.insert(__MODULE__, struct_or_changeset, opts)
      end

      def insert!(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.insert!(__MODULE__, struct_or_changeset, opts)
      end

      def update(changeset, opts \\ []) do
        ElasticSync.SyncRepo.update(__MODULE__, changeset, opts)
      end

      def update!(changeset, opts \\ []) do
        ElasticSync.SyncRepo.update!(__MODULE__, changeset, opts)
      end

      def delete(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.delete(__MODULE__, struct_or_changeset, opts)
      end

      def delete!(struct_or_changeset, opts \\ []) do
        ElasticSync.SyncRepo.delete!(__MODULE__, struct_or_changeset, opts)
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        ElasticSync.SyncRepo.insert_all(__MODULE__, schema_or_source, entries, opts)
      end

      def reindex(schema, opts \\ []) do
        ElasticSync.SyncRepo.reindex(__MODULE__, schema, opts)
      end
    end
  end

  def insert(sync_repo, struct_or_changeset, opts \\ []) do
    sync_one(sync_repo, :insert, [struct_or_changeset, opts])
  end

  def insert!(sync_repo, struct_or_changeset, opts \\ []) do
    sync_one!(sync_repo, :insert!, [struct_or_changeset, opts])
  end

  def update(sync_repo, changeset, opts \\ []) do
    sync_one(sync_repo, :update, [changeset, opts])
  end

  def update!(sync_repo, changeset, opts \\ []) do
    sync_one!(sync_repo, :update!, [changeset, opts])
  end

  def delete(sync_repo, struct_or_changeset, opts \\ []) do
    sync_one(sync_repo, :delete, [struct_or_changeset, opts])
  end

  def delete!(sync_repo, struct_or_changeset, opts \\ []) do
    sync_one!(sync_repo, :delete!, [struct_or_changeset, opts])
  end

  def insert_all(sync_repo, schema_or_source, entries, opts \\ []) do
    ecto = sync_repo.__elastic_sync__(:ecto)

    with {:ok, records} <- ecto.insert_all(schema_or_source, entries, opts),
         {:ok, _, _} <- Repo.insert_all(schema_or_source, records),
         do: {:ok, records}
  end

  def reindex(sync_repo, schema, opts \\ []) do
    ecto = sync_repo.__elastic_sync__(:ecto)
    Reindex.run(ecto, schema, opts)
  end

  defp sync_one(sync_repo, action, args) do
    ecto = sync_repo.__elastic_sync__(:ecto)

    with {:ok, record} <- apply(ecto, action, args),
         {:ok, _, _} <- apply(Repo, action, [record]),
         do: {:ok, record}
  end

  defp sync_one!(sync_repo, action, args) do
    ecto   = sync_repo.__elastic_sync__(:ecto)
    result = apply(ecto, action, args)

    apply(Repo, action, [result])
    result
  end
end
