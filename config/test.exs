use Mix.Config

config :searchkex,
  ecto_repos: [Searchkex.TestRepo]

config :searchkex, Searchkex.TestRepo,
  hostname: "localhost",
  database: "searchkex_test",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
