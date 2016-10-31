use Mix.Config

config :logger, level: :debug

# Configure your database
config :ib_gib, IbGib.Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  username:  System.get_env("POSTGRES_USER") || "${POSTGRES_USER}",
  password:  System.get_env("POSTGRES_PASSWORD") || "${POSTGRES_PASSWORD}",
  database:  System.get_env("PG_WEBGIB_DB") || "${PG_WEBGIB_DB}",
  hostname:  "postgres", # name in docker-compose.yml
  port:      System.get_env("PG_PORT") || "${PG_PORT}",  # standard is 5432
  pool_size: 20
