use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :web_gib, WebGib.Endpoint,
  http: [port: 4000],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
config :web_gib, WebGib.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
# config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
# config :phoenix, :stacktrace_depth, 20

# Configure your database
config :web_gib, WebGib.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "web_gib_dev",
  hostname: "172.17.0.2",
  port: 5432,
  pool_size: 10

  # Docker Stuff

  # To create the postgres container
  # `docker run --name postgres-ctr -e [POSTGRES_USER=postgres,POSTGRES_PASSWORD=postgres,POSTGRES_DB=web_gib_dev] -d postgres`
  # --name names the container
  # -e : environment variables
  # -d runs in detached mode
  #   * So the terminal can be used for something else.
  #
  # To psql into the container.
  # `docker run -it --rm --link postgres-ctr:postgres postgres psql -d web_gib_dev -h postgres -U postgres`

import_config "dev.secret.exs"
