defmodule WebGib.PageController do
  use WebGib.Web, :controller
  require Logger

  use IbGib.Constants, :ib_gib
  use WebGib.Constants, :keys
  import IbGib.Helper

  def index(conn, params) do
    Logger.debug "index. params: #{inspect params}"

    conn = conn |> add_ib_session_if_needed

    render conn, "index.html"
  end

  defp add_ib_session_if_needed(conn) do
    Logger.warn "session id key: #{@ib_session_id_key}"
    ib_session_id = conn |> get_session(@ib_session_id_key)
    conn =
      if ib_session_id == nil do
        ib_session_id = IbGib.Helper.new_id
        Logger.debug "Session did not exist. Putting new session id: #{ib_session_id}"
        conn = put_session(conn, @ib_session_id_key, ib_session_id)

        conn
      else
        Logger.debug "Session existed. session id: #{ib_session_id}"
        conn
      end
    Logger.warn "conn: #{inspect conn}"
    conn
  end

end
