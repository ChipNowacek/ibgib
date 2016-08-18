defmodule IbGib.Mixfile do
  use Mix.Project

  def project do
    [app: :ib_gib,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     aliases: aliases]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # [applications: [:postgrex, :ecto, :logger, :random_gib],
    [applications: [:postgrex, :ecto, :logger, :random_gib, :poison],
     mod: {IbGib, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "== 2.0.2"}, # frozen at this point because ecto migrate fails at 2.0.4
      {:poison, "~> 2.1"},
      {:random_gib, in_umbrella: true}
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate"],
    # ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    "test":       ["ecto.reset", "test"]]
  end

end
