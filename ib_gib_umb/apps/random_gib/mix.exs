defmodule RandomGib.Mixfile do
  use Mix.Project

  @version "0.0.7"

  @description "Standalone app for some simple (not crypto strong) random things, e.g. RandomGib.Get.some_letters(5), RandomGib.Get.one_of(src), RandomGib.Get.some_of(src), RandomGib.Get.some_characters(100)"

  @ibgib_repo_url "https://github.com/ibgib/ibgib"
  @random_gib_url "https://github.com/ibgib/ibgib/tree/master/ib_gib_umb/apps/random_gib"

  def project do
    [app: :random_gib,
     version: @version,

     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.2",

     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,

     deps: deps,

     # Hex
     package: hex_package,
     description: @description,
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {RandomGib, []}]
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
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 0.4", only: [:dev, :test]}
    ]
  end

  def hex_package do
    [maintainers: ["Bill Raiford", "ibgib@ibgib.com"],
     licenses: ["MIT"],
     links: %{
              "RandomGib App" => @random_gib_url,
              "IbGib Repo" => @ibgib_repo_url
            }
   ]
  end

end
