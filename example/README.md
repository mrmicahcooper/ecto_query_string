# Example app for using EctoQueryString

## Installation

`mix deps.get`

`mix ecto.setup`

`mix example.populate`

`iex -S mix`

```elixir
query = from user in User
queryString = EctoQueryString.query(query, "username=foo@example.com,select=email,username")
Example.Repo.all(querystring)
```
