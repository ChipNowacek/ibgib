defmodule IbGibUmb.Mixfile do
  @moduledoc """
  Umbrella mix config. 
  Not much here, except bare umbrella stuff and distillery!
  """
  
  use Mix.Project

  def project() do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.99.99"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps() do
    [{:distillery, "~> 0.10"}]
  end
end
