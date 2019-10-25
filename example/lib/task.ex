defmodule Example.Task do
  use Ecto.Schema

  schema "tasks" do
    field(:name, :string)
    field(:description, :string)
    field(:metadata, :map)
    belongs_to(:project, Example.Project)

    timestamps()
  end
end
