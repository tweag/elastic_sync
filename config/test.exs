use Mix.Config

config :elastic_sync,
  ecto_repos: [ElasticSync.TestRepo]

config :elastic_sync, ElasticSync.TestRepo,
  hostname: "localhost",
  database: "elastic_sync_test",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
