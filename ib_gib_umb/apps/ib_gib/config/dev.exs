use Mix.Config

config :logger, level: :debug

# Configure your database
config :ib_gib, IbGib.Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ib_gib_db_dev",
  hostname: "172.17.0.2",
  port: 5432,
  pool_size: 10

  # Docker Stuff

  # To create the postgres container
  # `docker run --name postgres-ctr -e [POSTGRES_USER=postgres,POSTGRES_PASSWORD=postgres,POSTGRES_DB=ib_gib_db_dev] -d postgres`
  # --name names the container
  # -e : environment variables
  # -d runs in detached mode
  #   * So the terminal can be used for something else.
  #
  # To psql into the container.
  # `docker run -it --rm --link postgres-ctr:postgres postgres psql -d ib_gib_db_dev -h postgres -U postgres`
