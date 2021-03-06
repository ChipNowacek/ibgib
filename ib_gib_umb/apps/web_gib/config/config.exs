# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :web_gib,
  ecto_repos: [WebGib.Data.Repo]

# Configures the endpoint
config :web_gib, WebGib.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "9XT1nsOFIe3do91obz7xOeNM6u/B0rR/22yRH+uLYUIIIX8YhR7a+rmaZMR01cdQ",
  # render_errors: [view: WebGib.ErrorView, accepts: ~w(html json)],
  pubsub: [name: WebGib.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configure node secret for node identity
config :web_gib, 
  node_id: "default",
  node_id_secret: "SupEr Dup3r S3cr3t"

# Configures Elixir's Logger
config :logger, :console,
  format: "\n[$time $level] $levelpad$metadata\n$message\n",
  metadata: [:request_id, :line, :module, :function, :x]
# config :logger, :console,
#   format: "$time $metadata[$level] $message\n",
#   metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
