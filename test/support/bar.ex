defmodule Bar do
  use Ecto.Schema

  schema "bars" do
    field(:bar, :integer)
    field(:title, :string)
    field(:description, :string)
    belongs_to(:foo, Foo)
  end
end
