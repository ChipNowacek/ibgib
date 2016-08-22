defmodule WebGib.PageController do
  use WebGib.Web, :controller
  require Logger

  use IbGib.Constants, :ib_gib
  import IbGib.Helper

  def index(conn, params) do
    Logger.debug "index. params: #{inspect params}"

    # session_id_key = :session_id_huh
    # session_id = get_session(conn, session_id_key)
    # Logger.warn "session_id in controller: #{inspect session_id}"
    # conn = init_session(conn)
    render conn, "index.html"
  end

end
