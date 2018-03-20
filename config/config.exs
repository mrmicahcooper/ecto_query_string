# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ecto_query_string, Foo,
  adapter: Ecto.Adapters.Postgres,
  database: "ecto_query_string_foo",
  username: "user",
  password: "pass",
  hostname: "localhost"
