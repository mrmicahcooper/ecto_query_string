defmodule Bar do
  use Ecto.Schema

  schema "bars" do
    field(:bar, :integer)
    field(:title, :string)
    field(:description, :string)
  end
end
