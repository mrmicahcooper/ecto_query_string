defmodule Foo do
  use Ecto.Schema

  schema "foos" do
    field(:foo, :integer)
    field(:title, :string)
    field(:description, :string)
    has_many(:bars, Bar)
  end
end
