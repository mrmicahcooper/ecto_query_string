defmodule Foo do
  use Ecto.Schema

  schema "foos" do
    field(:foo, :integer)
    field(:title, :string)
    field(:description, :string)
  end
end
