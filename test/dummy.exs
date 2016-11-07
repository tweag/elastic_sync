defmodule ElasticSync.TestRepo do
  use Ecto.Repo, otp_app: :elastic_sync
end

defmodule ElasticSync.TestSearchRepo do
  use ElasticSync.Repo
end

defmodule ElasticSync.TestSyncRepo do
  use ElasticSync.SyncRepo,
    ecto: ElasticSync.TestRepo,
    search: ElasticSync.TestSearchRepo
end
