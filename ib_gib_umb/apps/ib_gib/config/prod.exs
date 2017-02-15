use Mix.Config

# Do not print debug messages in production
config :logger, 
  level: :info
  # compile_time_purge_level: :warn # I think I need this but need to check it later
  
# Finally import the config/prod.secret.exs
# which should be versioned separately.
import_config "prod.secret.exs"
