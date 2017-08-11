defmodule ElasticSync.SyncRepo do
  alias ElasticSync.{Repo, Index}

  @batch_size 500

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
    Index.HTTP.transition(schema.__elastic_sync__, fn index ->
      mod.__elastic_sync__(:ecto)
      |> each_batch(schema, &Repo.load(index, &1))
      |> normalize_stream()
    end)
  end

  defp each_batch(ecto, schema, fun) do
    ecto.transaction(fn ->
      schema
      |> ecto.stream(max_rows: @batch_size)
      |> Stream.chunk(@batch_size, @batch_size, [])
      |> Stream.each(fun)
      |> Stream.run
    end)
  end

  defp normalize_stream({:ok, :ok}), do: :ok
  defp normalize_stream(other), do: other

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
