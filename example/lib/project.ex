defmodule Example.Project do
  use Ecto.Schema

  schema "projects" do
    field :name, :string
    field :description, :string
    belongs_to :user, Example.User
    has_many :tasks, Example.Task

    timestamps()
  end
end
