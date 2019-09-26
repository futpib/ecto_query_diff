defmodule EctoQueryDiff.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_query_diff,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,

      description: description(),
      package: package(),

      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "Diff Ecto Queries"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/futpib/ecto_query_diff"},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:synex, "~> 1.0"},
      {:ecto, "~> 3.2"},
      {:ecto_sql, "~> 3.2"},
      {:map_diff, "~> 1.3"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end
end
