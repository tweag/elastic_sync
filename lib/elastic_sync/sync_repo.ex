defmodule ElasticSync.SyncRepo do
  import ElasticSync.Schema, only: [get_index: 1, get_alias: 1]

  defmacro __using__(opts) do
    ecto = Keyword.fetch!(opts, :ecto)
    search = Keyword.get(opts, :search, ElasticSync.Repo)

    quote do
      @ecto unquote(ecto)
      @search unquote(search)

      def __elastic_sync__(:ecto), do: @ecto
      def __elastic_sync__(:search), do: @search

      def insert(struct_or_changeset, opts \\ []) do
        sync(:insert, [struct_or_changeset, opts])
      end

      def insert!(struct_or_changeset, opts \\ []) do
        sync(:insert!, [struct_or_changeset, opts])
      end

      def update(changeset, opts \\ []) do
        sync(:update, [changeset, opts])
      end

      def update!(changeset, opts \\ []) do
        sync(:update!, [changeset, opts])
      end

      def delete(struct_or_changeset, opts \\ []) do
        sync(:delete, [struct_or_changeset, opts])
      end

      def delete!(struct_or_changeset, opts \\ []) do
        sync(:delete!, [struct_or_changeset, opts])
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        ElasticSync.SyncRepo.insert_all(__MODULE__, schema_or_source, entries, opts)
      end

      def reindex(schema) do
        ElasticSync.SyncRepo.reindex(__MODULE__, schema)
      end

      defp sync(action, args) do
        apply(ElasticSync.SyncRepo, action, [__MODULE__] ++ args)
      end
    end
  end

  def insert(mod, struct_or_changeset, opts \\ []) do
    sync_one(:insert, mod, [struct_or_changeset, opts])
  end

  def insert!(mod, struct_or_changeset, opts \\ []) do
    sync_one!(:insert!, mod, [struct_or_changeset, opts])
  end

  def update(mod, changeset, opts \\ []) do
    sync_one(:update, mod, [changeset, opts])
  end

  def update!(mod, changeset, opts \\ []) do
    sync_one!(:update!, mod, [changeset, opts])
  end

  def delete(mod, struct_or_changeset, opts \\ []) do
    sync_one(:delete, mod, [struct_or_changeset, opts])
  end

  def delete!(mod, struct_or_changeset, opts \\ []) do
    sync_one!(:delete!, mod, [struct_or_changeset, opts])
  end

  def insert_all(mod, schema_or_source, entries, opts \\ []) do
    {ecto, search} = get_repos(mod)

    with {:ok, records} <- ecto.insert_all(schema_or_source, entries, opts),
         {:ok, _, _} <- search.insert_all(schema_or_source, records),
         do: {:ok, records}
  end

  def reindex(mod, schema) do
    {ecto, search} = get_repos(mod)

    records = ecto.all(schema)
    index_name = get_index(schema)
    alias_name = get_alias(schema)

    # Create a new index with the name of the alias
    {:ok, _, _} = search.create_index(alias_name)

    # Populate the new index
    {:ok, _, _} = search.bulk_index(schema, records, index: alias_name)

    # Refresh the index
    {:ok, _, _} = search.refresh(schema, index: alias_name)

    # Alias our new index as the old index
    {:ok, _, _} = search.swap_alias(index_name, alias_name)
  end

  defp sync_one(action, mod, args) do
    {ecto, search} = get_repos(mod)

    with {:ok, record} <- apply(ecto, action, args),
         {:ok, _, _} <- apply(search, action, [record]),
         do: {:ok, record}
  end

  defp sync_one!(action, mod, args) do
    {ecto, search} = get_repos(mod)
    result = apply(ecto, action, args)
    apply(search, action, [result])
    result
  end

  defp get_repos(mod) do
    {mod.__elastic_sync__(:ecto), mod.__elastic_sync__(:search)}
  end
end
