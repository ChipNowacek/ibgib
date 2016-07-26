defmodule WebGib.PageController do
  use WebGib.Web, :controller
  require Logger
  import IbGib.Helper

  @delim "^"
  @root_ib_gib "ib#{@delim}gib"


  def index(conn, %{"src_ib_gib" => src_ib_gib, "action" => action} = params) do
    case action do
      "fork" ->
        Logger.info "fork it yo"
        {:ok, forked_thing} = fork(src_ib_gib)
        Logger.info "forked_thing: #{inspect forked_thing}"
      _ ->
        Logger.warn "Unknown action: #{action}"
    end
    Logger.warn "doesn't exist huh: #{inspect get_session(conn, :never_put)}"

    Logger.debug "start inspect conn"
    Logger.info "#{inspect conn}"
    Logger.debug "end inspect conn"

    Logger.warn "old session message: #{inspect get_session(conn, :message)}"
    conn = put_session(conn, :message, "session msg yo: #{new_id}")
    Logger.warn "new session message: #{inspect get_session(conn, :message)}"
    Logger.warn "session id: #{inspect get_session(conn, :id)}"
    # message = get_session(conn, :message)
    # text conn, message

    render conn, "index.html"
  end
  def index(conn, params) do
    Logger.warn "yooooo index huh"
    render conn, "index.html"
  end

  defp fork(dest_ib \\ new_id, src_ib_gib \\ @root_ib_gib)
  defp fork(dest_ib, src_ib_gib) do
    src =
      if (src_ib_gib === "") do
        {:ok, root} = IbGib.Expression.Supervisor.start_expression()
        root
      else
        {:ok, thing} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
        thing
      end

    src |> IbGib.Expression.fork(dest_ib)
  end
end
