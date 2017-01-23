defmodule WebGib.Endpoint do
  use Phoenix.Endpoint, otp_app: :web_gib
  use IbGib.Constants, :ib_gib
  use WebGib.Constants, :config

  socket "/ibgibsocket", WebGib.IbGibSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :web_gib, gzip: false,
    only: ~w(css fonts images js files favicon.ico favicon-32x32.png favicon-16x16.png favicon48x48.ico apple-touch-icon.png manifest.json safari-pinned-tab.svg android-chrome-192x192.png android-chrome-512x512.png browserconfig.xml mstile-150x150.png robots.txt glyphicons-halflings-regular.woff2 fontawesome-webfont.woff2?v=4.6.3)

  plug Plug.Static,
    at: "files/", from: @upload_files_path, gzip: false

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison,
    length: @max_data_size - 1_024_000,
    read_length: 1_024_000,
    read_timeout: 30_000

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.

  plug Plug.Session,
    store: :cookie,
    key: "_web_gib_key",
    signing_salt: "/EWwmO80",
    # max_age: thanks SO! http://stackoverflow.com/questions/34578163/implementing-remember-me-in-phoenix
    max_age: 2_592_000 # 60*60*24*30 = 30 days

  plug WebGib.Router
end
