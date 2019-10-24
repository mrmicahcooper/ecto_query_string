defmodule Example.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext"
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    create table(:users) do
      add :username, :string
      add :email, :citext
      add :age, :integer

      timestamps()
    end

    create table(:projects) do
      add :name, :string, null: false
      add :description, :text
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create table(:tasks) do
      add :name, :string, null: false
      add :description, :text
      add :metadata, :map, default: "{}"
      add :project_id, references(:projects, on_delete: :delete_all)

      timestamps()
    end

  end

end
