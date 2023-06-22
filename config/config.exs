import Config

config :ecto_query_string, Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ecto_query_string_foo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

if config_env() == :test do
  import_config "test.exs"
end
