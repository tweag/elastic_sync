defmodule Searchkex.TestRepo do
  use Ecto.Repo, otp_app: :searchkex
end

defmodule Searchkex.TestSearchRepo do
  use Searchkex.Repo
end

defmodule Searchkex.TestSyncRepo do
  use Searchkex.SyncRepo,
    ecto: Searchkex.TestRepo,
    search: Searchkex.TestSearchRepo
end
