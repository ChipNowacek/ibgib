use Mix.Config

config :web_gib, WebGib.Endpoint,
  https: [port: {:system, "PORT"},
          otp_app: :web_gib,
          keyfile: System.get_env("SSL_KEY_PATH") || "${SSL_KEY_PATH}",
          certfile: System.get_env("SSL_CERT_PATH") || "${SSL_CERT_PATH}"],
  force_ssl: [hsts: false],
  debug_errors: false,
  code_reloader: false,

  url: [host: "www.ibgib.com"],
  # url: [host: "www.ibgib.com", port: {:system, "PORT"}],

  # Path to a manifest containing the digested version of static files. This
  # manifest is generated by the mix phoenix.digest task which you typically
  # run after static files are built.
  cache_static_manifest: "priv/static/manifest.json",

  
  # Needed for the websocket with phoenix channels
  # https://github.com/phoenixframework/phoenix/issues/1359
  check_origin: false,
  # Couldn't get this to work
  # check_origin: [
  #   "//ibgib.com", "//www.ibgib.com", # not sure if these do anything
  #   # "//192.168.99.1", # for local docker-machine
  #   # "//192.168.99.100", # for local docker-machine
  #   "//192.168.99.101", # for local docker-machine
  #   
  #   # Shotgunning the following IPs to try to ensure that they are allowed
  #   # for phoenix channels, because I don't want to troubleshoot it in prod
  #   # and I figure this is already better than check_origin: false.
  #   "//172.17.0.1", # These are the ips that are assigned per docker networks...
  #   "//172.17.0.2", # These are the ips that are assigned per docker networks...
  #   "//172.17.0.3", # These are the ips that are assigned per docker networks...
  #   "//172.18.0.1", # shotgun approach...
  #   "//172.18.0.2", # shotgun approach...
  #   "//172.18.0.3", # shotgun approach...
  #   "//172.19.0.1",  # ...
  #   "//172.19.0.2",  # ...
  #   "//172.19.0.3"  # ...
  # ],

  # For hot code upgrading (?)
  root: ".",

  # Needed to start the server in production
  server: true

# Do not print debug messages in production
config :logger, level: :info

# Finally import the config/prod.secret.exs
# which should be versioned separately.
import_config "prod.secret.exs"
