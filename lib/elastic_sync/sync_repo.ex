defmodule ElasticSync.SyncRepo do
  alias ElasticSync.{Repo, Schema, Index}

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

  def insert_all(mod, schema_or_source, entries, opts \\ []) do
    ecto = mod.__elastic_sync__(:ecto)

    with {:ok, records} <- ecto.insert_all(schema_or_source, entries, opts),
         {:ok, _, _} <- Repo.insert_all(schema_or_source, records),
         do: {:ok, records}
  end

  def reindex(mod, schema) do
    ecto = mod.__elastic_sync__(:ecto)

    schema
    |> Schema.get_index()
    |> Index.transition(fn alias_name ->
      normalize ecto.transaction(fn ->
        schema
        |> ecto.stream(max_rows: 500)
        |> Stream.chunk(500)
        |> Stream.each(&Repo.bulk_index(schema, &1, index: alias_name))
        |> Stream.run()
      end)
    end)
  end

  defp normalize({:ok, :ok}), do: :ok
  defp normalize(other), do: other

  defp sync_one(mod, action, args) do
    ecto = mod.__elastic_sync__(:ecto)

    with {:ok, record} <- apply(ecto, action, args),
         {:ok, _, _} <- apply(Repo, action, [record]),
         do: {:ok, record}
  end

  defp sync_one!(mod, action, args) do
    ecto = mod.__elastic_sync__(:ecto)
    result = apply(ecto, action, args)
    apply(Repo, action, [result])
    result
  end
end
