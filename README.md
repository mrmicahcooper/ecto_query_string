# EctoQueryString

A simple DSL for creating ecto queries with a query string

## Usage

You can chain the following in any order that makes sense for your query:

Query String    | Ecto Query
--------------- | -----------
`foo=bar`       | `where(x.foo = ^"bar")`
`foo=bar,baz`   | `where(x.foo in ^["bar", "baz"])`
`!foo=bar`      | `where(x.foo != ^"bar")`
`!foo=bar,baz`  | `where(x.foo not in ^["bar", "baz"])`
`~foo=bar*`     | `where: like(x.foo, ^"bar%")`
`~foo=*bar`     | `where: like(x.foo, ^"%bar")`
`~foo=*bar*`    | `where: like(x.foo, ^"%bar%")`
`i~foo=bar*`    | `where: ilike(x.foo, ^"bar%")`
`i~foo=*bar`    | `where: ilike(x.foo, ^"%bar")`
`i~foo=*bar*`   | `where: ilike(x.foo, ^"%bar%")`
`...foo=.:99`   | `where(x.foo < 99)`
`...foo=40:.`   | `where(x.foo > 40)`
`...foo=40:99`  | `where(x.foo < 99 and x.foo > 40)`
`...foo=40:99`  | `where(x.foo < 99 and x.foo > 40)`
`...=.:99`      | `limit: 99`
`...=40:.`      | `offset: 40`
`...=40:99`     | `offset: 40, limit: 99`
`@=foo,bar`     | `select([:foo, :bar])`
`$asc=foo,bar`  | `order_by([:foo, :bar])`
`$desc=foo,bar` | `order_by([desc: :foo, desc: :bar])`
