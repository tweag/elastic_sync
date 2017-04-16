defmodule ElasticSync.TestRepo do
  use Ecto.Repo, otp_app: :elastic_sync
end

defmodule ElasticSync.TestSyncRepo do
  use ElasticSync.SyncRepo,
    ecto: ElasticSync.TestRepo
end

defmodule ElasticSync.Thing do
  use Ecto.Schema
  import Ecto.Changeset
  use ElasticSync.Schema, index: "elastic_sync_test"

  schema "things" do
    field :name, :string
  end

  def to_search_document(record) do
    Map.take(record, [:id, :name])
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
