defmodule Example.User do
  use Ecto.Schema

  schema "users" do
    field :username, :string
    field :email, :string
    field :age, :integer
    has_many :projects, Example.Project
    has_many :tasks, through: [:projects, :tasks]

    timestamps()
  end
end

