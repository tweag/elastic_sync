defmodule ElasticSync.TestRepo.Migrations.MigrateAll do
  use Ecto.Migration

  def change do
    create table(:things) do
      add :name, :string
    end
  end
end
