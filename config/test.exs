use Mix.Config

config :elastic_sync,
  ecto_repos: [ElasticSync.TestRepo]

config :elastic_sync, ElasticSync.TestRepo,
  username: "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  database: "elastic_sync_test",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
