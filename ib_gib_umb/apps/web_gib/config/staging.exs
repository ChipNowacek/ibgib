use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :web_gib, WebGib.Endpoint,
  # http: [port: 4000],
  https: [port: {:system, "PORT"},
          otp_app: :web_gib,
          keyfile: System.get_env("SSL_KEY_PATH") || "${SSL_KEY_PATH}",
          certfile: System.get_env("SSL_CERT_PATH") || "${SSL_CERT_PATH}"],
  debug_errors: true,
  check_origin: false,
  root: ".",
  server: true

# Do not include metadata nor timestamps in development logs
# config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
# config :phoenix, :stacktrace_depth, 20

# Configure your database
config :web_gib, WebGib.Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "web_gib_dev",
  hostname: "172.17.0.2",
  port: 5432,
  pool_size: 10

  # Do not print debug messages in production
  config :logger, level: :debug

import_config "staging.secret.exs"
