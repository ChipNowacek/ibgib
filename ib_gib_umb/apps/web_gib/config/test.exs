use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_gib, WebGib.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :debug

# Configure your database
config :web_gib, WebGib.Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "web_gib_test",
  hostname: "172.17.0.2",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox

  # To create the postgres container
  # `docker run --name postgres-ctr -e [POSTGRES_USER=postgres,POSTGRES_PASSWORD=postgres,POSTGRES_DB=web_gib_test] -d postgres`
  # --name names the container
  # -e : environment variables
  # -d runs in detached mode
  #   * So the terminal can be used for something else.
  #
  # To psql into the container.
  # `docker run -it --rm --link postgres-ctr:postgres postgres psql -d hello_phoenix_dev -h postgres -U postgres`
