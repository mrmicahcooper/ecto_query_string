defmodule EctoQueryString.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_query_string,
      version: "0.1.0",
      description: "Easy querying with ecto and query string params",
      elixir: "~> 1.8",
      name: "EctoQueryString",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      source_url: "http://github.com/mrmicahcooper/ecto_query_string",
      deps: deps(),
      package: package(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["test --trace"]
    ]
  end

  defp package do
    [
      maintainers: ["Micah Cooper"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/mrmicahcooper/ecto_query_string"}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md"
      ]
    ]
  end
end
