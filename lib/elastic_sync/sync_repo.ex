defmodule ElasticSync.SyncRepo do
  import ElasticSync.Schema, only: [get_index: 1, get_alias: 1]

  defmacro __using__(opts) do
    ecto = Keyword.fetch!(opts, :ecto)
    search = Keyword.get(opts, :search, ElasticSync.Repo)

    quote do
      def __elastic_sync__(:ecto), do: unquote(ecto)
      def __elastic_sync__(:search), do: unquote(search)

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

      def reindex(schema) do
        ElasticSync.SyncRepo.reindex(__MODULE__, schema)
      end
    end
  end

  def insert(mod, struct_or_changeset, opts \\ []) do
    sync_one(mod, :insert, [struct_or_changeset, opts])
  end

  def insert!(mod, struct_or_changeset, opts \\ []) do
    sync_one!(mod, :insert!, [struct_or_changeset, opts])
  end

  def update(mod, changeset, opts \\ []) do
    sync_one(mod, :update, [changeset, opts])
  end

  def update!(mod, changeset, opts \\ []) do
    sync_one!(mod, :update!, [changeset, opts])
  end

  def delete(mod, struct_or_changeset, opts \\ []) do
    sync_one(mod, :delete, [struct_or_changeset, opts])
  end

  def delete!(mod, struct_or_changeset, opts \\ []) do
    sync_one!(mod, :delete!, [struct_or_changeset, opts])
  end

  def insert_all(mod, schema_or_source, entries, opts \\ [])
  def insert_all({ecto, search}, schema_or_source, entries, opts) do
    with {:ok, records} <- ecto.insert_all(schema_or_source, entries, opts),
         {:ok, _, _} <- search.insert_all(schema_or_source, records),
         do: {:ok, records}
  end
  def insert_all(mod, schema_or_source, entries, opts) do
    mod
    |> get_repos()
    |> insert_all(schema_or_source, entries, opts)
  end

  def reindex({ecto, search}, schema) do
    records = ecto.all(schema)
    index_name = get_index(schema)
    alias_name = get_alias(schema)

    with {:ok, _, _} <- search.create_index(alias_name),
         {:ok, _, _} <- search.bulk_index(schema, records, index: alias_name),
         {:ok, _, _} <- search.refresh(schema, index: alias_name),
         {:ok, _, _} <- search.swap_alias(index_name, alias_name),
         do: :ok
  end
  def reindex(mod, schema) do
    mod
    |> get_repos()
    |> reindex(schema)
  end

  defp sync_one({ecto, search}, action, args) do
    with {:ok, record} <- apply(ecto, action, args),
         {:ok, _, _} <- apply(search, action, [record]),
         do: {:ok, record}
  end
  defp sync_one(mod, action, args) do
    mod
    |> get_repos()
    |> sync_one(action, args)
  end

  defp sync_one!({ecto, search}, action, args) do
    result = apply(ecto, action, args)
    apply(search, action, [result])
    result
  end
  defp sync_one!(mod, action, args) do
    mod
    |> get_repos()
    |> sync_one!(action, args)
  end

  defp get_repos(mod) do
    {mod.__elastic_sync__(:ecto), mod.__elastic_sync__(:search)}
  end
end
