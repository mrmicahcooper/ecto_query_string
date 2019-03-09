# EctoQueryString

Compose an `Ecto.Query` with a querystring

## Usage

Say you have the following schemas:

```elixir
defmodule Foo do
  use Ecto.Schema

  schema "foos" do
    field(:name, :string)
    field(:age, :integer)
    has_many(:bars, Bar)
  end
end

defmodule Bar do
  use Ecto.Schema

  schema "bars" do
    field(:title, :string)
    field(:likes, :integer)
    belongs_to(:foo, Foo)
  end
end

```
And you have a base query like this:

```elixir
query = Ecto.Query.from(foo in Foo)
```

You can call
```elixir
EctoQueryString.query(query, "name=foo&sort=-age,inserted-at")
```

Where the second argument is a querystrying using the following DSL:

```
Query String               | Ecto Query
---------------            | -----------
`name=micah`               | `where: foo.name = ^"micah"`
`bars.title=micah`         | `join: bars in assoc(foo, :bars),where: bars.title = ^"micah"`
`name=micah,bob`           | `where(foo.name in ^["micah", "bob"])`
`bars.title=micah,bob`     | `join: bars in assoc(foo, :bars), where: bars.title in ^["micah", "bob"]`
`!name=micah`              | `where(foo.name != ^"micah")`
`!bars.title=micah`        | `join: bars in assoc(foo, :bars), where(bars.title != ^"micah")`
`!name=micah,bob`          | `where(foo.name not in ^["micah", "bob"])`
`!bars.title=micah,bob`    | `join: bars in assoc(foo, :bars), where(bars.title not in ^["micah", "bob"])`
`like:foo=bar*`            | `where: like(x.foo, ^"bar%")`
`like:bars.title=micah*`   | `join: bars in assoc(foo, :bars), where: like(bars.title, ^"bar%")`
`like:foo=*bar`            | `where: like(x.foo, ^"%bar")`
`like:bars.title=*micah`   | `join: bars in assoc(foo, :bars), where: like(bars.title, ^"%bar")`
`like:name=*micah*`        | `where: like(foo.name, ^"%micah%")`
`like:bars.title=*micah*`  | `join: bars in assoc(foo, :bars), where: like(bars.title, ^"%bar%")`
`ilike:name=micah*`        | `where: ilike(foo.name, ^"micah%")`
`ilike:bars.title=micah*`  | `join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"micah%")`
`ilike:name=*micah`        | `where: ilike(foo.name, ^"%micah")`
`ilike:bars.title=*micah`  | `join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"%micah")`
`ilike:foo=*bar*`          | `where: ilike(x.foo, ^"%bar%")`
`ilike:bars.title=*micah*` | `join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"%micah%")`
`less:age=99`              | `where(foo.age < 99)`
`less:bars.likes=99`       | `join: bars in assoc(foo, :bars), where(bars.likes < 99)`
`greater:age=40`           | `where(foo.age > 40)`
`greater:bars.likes=99`    | `join: bars in assoc(foo, :bars), where(bars.likes > 99)`
`range:age=40:99`          | `where(foo.age < 99 and foo.age > 40)`
`range:bars.likes=40:99`   | `join: bars in assoc(foo, :bars), where(bars.likes< 99 and bars.likes > 40)`
`or:name=micah`            | `or_where(foo.name = ^"micah")`
`or:bars.title=micah`      | `join: bars in assoc(foo, :bars), or_where: bars.title == ^"micah"`
`or:name=micah,bob`        | `or_where(foo.name in ^["micah", "bob"])`
`or:bars.title=micah,bob`  | `join: bars in assoc(foo, :bars), or_where: bars.title in ^["micah", "bob"`
`!or:foo=bar`              | `or_where(x.foo != ^"bar")`
`!or:bars.title=micah`     | `join: bars in assoc(foo, :bars), or_where: bars.title != ^"micah"`
`!or:foo=bar,baz`          | `or_where(x.foo not in ^["bar", "baz"])`
`!or:bars.title=micah,bob` | `join: bars in assoc(foo, :bars), or_where: bars.title not in ^["micah", "bob"`
`limit=.:99`               | `limit: 99`
`offset=40:.`              | `offset: 40`
`between=40:99`            | `offset: 40, limit: 99`
`select=foo,bar`           | `select([:foo, :bar])`
`fields=foo,bar`           | `select([:foo, :bar])`
`order=foo,-bar,baz`       | `order_by([asc: :foo, desc: :bar, asc: :baz])`
```
