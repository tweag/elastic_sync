defmodule ElasticSync.Mixfile do
  use Mix.Project

  def project do
    [app: :elastic_sync,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application() do
    [applications: app_list(Mix.env)]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:tirexs, "~> 0.8"},
      {:ecto, "~> 2.0.0", optional: true},
      {:ecto, "~> 2.0.0", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ ["test/dummy.exs"]
  defp elixirc_paths(_), do: elixirc_paths()
  defp elixirc_paths(), do: ["lib"]

  defp app_list(:test), do: app_list() ++ [:ecto, :postgrex]
  defp app_list(_), do: app_list()
  defp app_list(), do: [:logger, :tirexs]
end
