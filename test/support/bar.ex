defmodule Bar do
  use Ecto.Schema

  schema "bars" do
    field(:bar, :integer)
    field(:name, :string)
    field(:content, :string)
    belongs_to(:foo, Foo)
  end
end
