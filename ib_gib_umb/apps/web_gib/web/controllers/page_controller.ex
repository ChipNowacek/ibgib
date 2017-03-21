defmodule WebGib.PageController do
  use IbGib.Constants, :ib_gib

  use WebGib.Web, :controller
  require Logger

  use WebGib.Constants, :keys
  import IbGib.Helper

  def index(conn, params) do
    _ = Logger.debug "index. params: #{inspect params}"

    conn = conn |> add_ib_session_if_needed

    render conn, "index.html"
  end

  defp add_ib_session_if_needed(conn) do
    _ = Logger.debug "session id key: #{@ib_session_id_key}"
    ib_session_id = conn |> get_session(@ib_session_id_key)
    conn =
      if ib_session_id == nil do
        ib_session_id = new_id()
        _ = Logger.debug "Session did not exist. Putting new session id: #{ib_session_id}"
        conn = put_session(conn, @ib_session_id_key, ib_session_id)

        conn
      else
        _ = Logger.debug "Session existed. session id: #{ib_session_id}"
        conn
      end
    _ = Logger.debug "conn: #{inspect conn}"
    conn
  end

  # I'm not using this right now?
  defp add_ib_node_identity_if_needed(conn) do
    _ = Logger.debug "node id key: #{@ib_node_id_key}"
    ib_node_id = conn |> get_session(@ib_node_id_key)
    conn =
      if ib_node_id == nil do
        ib_node_id = WebGib.Node.get_current_node_id()
        _ = Logger.debug "Session did not exist. Putting new node id: #{ib_node_id}"
        conn = put_session(conn, @ib_node_id_key, ib_node_id)

        conn
      else
        _ = Logger.debug "Session existed. node id: #{ib_node_id}"
        conn
      end
    _ = Logger.debug "conn: #{inspect conn}"
    conn
  end

end
