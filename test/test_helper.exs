# Mix.Tasks.Ecto.Drop.run(["--quiet"])
# Mix.Tasks.Ecto.Create.run(["--quiet"])
Mix.Task.run "ecto.drop", ["--quiet", "-r", "Searchkex.TestRepo"]
Mix.Task.run "ecto.create", ["--quiet", "-r", "Searchkex.TestRepo"]
Mix.Task.run "ecto.migrate", ["-r", "Searchkex.TestRepo"]

Searchkex.TestRepo.start_link

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Searchkex.TestRepo, :manual)
