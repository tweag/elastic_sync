Mix.Task.run "ecto.drop", ["--quiet", "-r", "ElasticSync.TestRepo"]
Mix.Task.run "ecto.create", ["--quiet", "-r", "ElasticSync.TestRepo"]
Mix.Task.run "ecto.migrate", ["-r", "ElasticSync.TestRepo"]

ElasticSync.TestRepo.start_link

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(ElasticSync.TestRepo, :manual)
