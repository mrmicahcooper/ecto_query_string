# EctoQueryString

Compose an `Ecto.Query` with a querystring

## Installation

Add `:ecto_query_string` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_query_string, "~> 0.1.0"}
  ]
end
```

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

You can do things like this:
```elixir
query = Ecto.Query.from(user in User)
query_string =  "username=mrmicahcooper&greater:age=18&limit=10"
EctoQueryString.query(query, query_string)
```
And get:
```elixir
Ecto.Query.from(u0 in User,
  where: u0.age > ^"18",
  where: u0.username == ^"mrmicahcooper",
  limit: ^"10"
)
```

Here is the full DSL

```elixir
# Basic Queries
"name=micah"                => where: foo.name = ^"micah"
"name=micah,bob"            => where: foo.name in ^["micah", "bob"]
"!name=micah"               => where: foo.name != ^"micah"
"!name=micah,bob"           => where: foo.name not in ^["micah", "bob"]
"like:foo=bar*"             => where: like(x.foo, ^"bar%")
"like:foo=*bar"             => where: like(x.foo, ^"%bar")
"like:name=*micah*"         => where: like(foo.name, ^"%micah%")
"ilike:name=micah*"         => where: ilike(foo.name, ^"micah%")
"ilike:name=*micah"         => where: ilike(foo.name, ^"%micah")
"ilike:foo=*bar*"           => where: ilike(x.foo, ^"%bar%")
"less:age=99"               => where: foo.age < 99
"greater:age=40"            => where: foo.age > 40
"range:age=40:99"           => where: foo.age < 99 and foo.age > 40
"or:name=micah"             => or_where: foo.name = ^"micah"
"or:name=micah,bob"         => or_where: foo.name in ^["micah", "bob"]
"!or:name=bar"              => or_where: foo.name != ^"bar"
"!or:name=micah,bob"        => or_where: foo.name not in ^["bar", "baz"]
"select=foo,bar"            => select: [:foo, :bar]
"fields=foo,bar"            => select: [:foo, :bar]
"limit=.:99"                => limit: 99
"offset=40:."               => offset: 40
"between=40:99"             => offset: 40, limit: 99
"order=foo,-bar,baz"        => order_by: [asc: :foo, desc: :bar, asc: :baz]
#Incorporating Associated Tables
"bars.title=micah"          => join: bars in assoc(foo, :bars), where: bars.title = ^"micah"
"bars.title=micah,bob"      => join: bars in assoc(foo, :bars), where: bars.title in ^["micah", "bob"]
"!bars.title=micah"         => join: bars in assoc(foo, :bars), where: bars.title != ^"micah")
"!bars.title=micah,bob"     => join: bars in assoc(foo, :bars), where: bars.title not in ^["micah", "bob"])
"like:bars.title=micah*"    => join: bars in assoc(foo, :bars), where: like(bars.title, ^"bar%")
"like:bars.title=*micah"    => join: bars in assoc(foo, :bars), where: like(bars.title, ^"%bar")
"like:bars.title=*micah*"   => join: bars in assoc(foo, :bars), where: like(bars.title, ^"%bar%")
"ilike:bars.title=micah*"   => join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"micah%")
"ilike:bars.title=*micah"   => join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"%micah")
"ilike:bars.title=*micah* " => join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"%micah%")
"less:bars.likes=99"        => join: bars in assoc(foo, :bars), where: bars.likes < 99
"greater:bars.likes=99"     => join: bars in assoc(foo, :bars), where: bars.likes > 99
"range:bars.likes=40:99"    => join: bars in assoc(foo, :bars), where: bars.likes< 99 and bars.likes > 40
"or:bars.title=micah"       => join: bars in assoc(foo, :bars), or_where: bars.title == ^"micah"
"or:bars.title=micah,bob"   => join: bars in assoc(foo, :bars), or_where: bars.title in ^["micah", "bob"
"!or:bars.title=micah"      => join: bars in assoc(foo, :bars), or_where: bars.title != ^"micah"
"!or:bars.title=micah,bob"  => join: bars in assoc(foo, :bars), or_where: bars.title not in ^["micah", "bob"
"select=email,bars.title"   => join: bars in assoc(foo, :bars), select: [{:bars, [:title]}, :email], preload: [:bars]
  ```


## Caveats

When using `select` - In order to hydrate the schema, you _must always_ at least `select=id` from every schema. Even nested schemas would need at least `select=id,foos.id` 

When using `order` - You cannot not (currently) order by nested fields. 
