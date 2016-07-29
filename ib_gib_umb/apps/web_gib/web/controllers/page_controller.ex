defmodule WebGib.PageController do
  use WebGib.Web, :controller
  require Logger
  import IbGib.Helper

  @delim "^"
  @root_ib_gib "ib#{@delim}gib"

  def index(conn, params) do
    Logger.debug "index. params: #{inspect params}"
    # conn = init_session(conn)
    render conn, "index.html"
  end

end
