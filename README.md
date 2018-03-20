# EctoQueryString

A simple DSL for creating ecto queries from with a query string

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_query_string` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_query_string, "~> 0.1.0"}
  ]
end
```

## Usage

You can chain the following in in order tha makes sense for your query:

Query String    | Ecto Query
--------------- | -----------
`foo=bar`       | `where(x.foo = ^"bar")`
`foo=bar,baz`   | `where(x.foo in ^["bar", "baz"])`
`!foo=bar`      | `where(x.foo != ^"bar")`
`!foo=bar,baz`  | `where(x.foo not in ^["bar", "baz"])`
`@=foo,bar`     | `select([:foo, :bar])`
`...=.:99`      | `limit: 99`
`...=40:.`      | `offset: 40`
`...=40:99`     | `offset: 40, limit: 99`
`...foo=.:99`   | `where(x.foo < 99)`
`...foo=40:.`   | `where(x.foo > 40)`
`...foo=40:99`  | `where(x.foo < 99 and x.foo > 40)`
`...foo=40:99`  | `where(x.foo < 99 and x.foo > 40)`
`~foo=bar`      | `where(x.foo, like("bar")`
`i~foo=bar`     | `where(x.foo, ilike("bar")`
`$asc=foo,bar`  | `order_by([:foo, :bar])`
`$desc=foo,bar` | `order_by([desc: :foo, desc: :bar])`


