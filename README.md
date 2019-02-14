# EctoQueryString

A simple DSL for creating ecto queries with a query string

## Usage

You can chain the following in any order that makes sense for your query:

Query String        | Ecto Query
---------------     | -----------
`foo=bar`           | `where(x.foo = ^"bar")`
`foo=bar,baz`       | `where(x.foo in ^["bar", "baz"])`
`!foo=bar`          | `where(x.foo != ^"bar")`
`!foo=bar,baz`      | `where(x.foo not in ^["bar", "baz"])`
`like:foo=bar*`     | `where: like(x.foo, ^"bar%")`
`like:foo=*bar`     | `where: like(x.foo, ^"%bar")`
`like:foo=*bar*`    | `where: like(x.foo, ^"%bar%")`
`ilike:foo=bar*`    | `where: ilike(x.foo, ^"bar%")`
`ilike:foo=*bar`    | `where: ilike(x.foo, ^"%bar")`
`ilike:foo=*bar*`   | `where: ilike(x.foo, ^"%bar%")`
`less:foo=.:99`     | `where(x.foo < 99)`
`greater:foo=40:.`  | `where(x.foo > 40)`
`range:foo=40:99`   | `where(x.foo < 99 and x.foo > 40)`
`or:foo=bar`        | `or_where(x.foo = ^"bar")`
`or:foo=bar,baz`    | `or_where(x.foo in ^["bar", "baz"])`
`!or:foo=bar`       | `or_where(x.foo != ^"bar")`
`!or:foo=bar,baz`   | `or_where(x.foo not in ^["bar", "baz"])`
`limit=.:99`        | `limit: 99`
`offset=40:.`       | `offset: 40`
`between=40:99`     | `offset: 40, limit: 99`
`select=foo,bar`    | `select([:foo, :bar])`
`ascend=foo,bar`    | `order_by([:foo, :bar])`
`descend=foo,bar`   | `order_by([desc: :foo, desc: :bar])`
`sort=foo,-bar,baz` | `order_by([asc: :foo, desc: :bar, asc: :baz])`
