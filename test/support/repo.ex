defmodule Repo do
  use Ecto.Repo,
    otp_app: :ecto_query_string,
    adapter: Ecto.Adapters.Postgres
end
