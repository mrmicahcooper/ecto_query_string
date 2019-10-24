use Mix.Config

config :example, ecto_repos: [Example.Repo]

config :example, Example.Repo,
  database: "example_repo",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
