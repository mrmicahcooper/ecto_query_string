defmodule User do
  use Ecto.Schema

  schema "users" do
    field(:username, :string)
    field(:email, :string)
    field(:age, :integer)
    field(:password, :string, virtual: true)
    field(:password_digest, :string)
    has_many(:bars, Bar)
    has_many(:foos, Foo)
    has_many(:foobars, through: [:foos, :bars])
    timestamps()
  end
end
