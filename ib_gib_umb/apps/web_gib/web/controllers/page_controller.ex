defmodule WebGib.PageController do
  use WebGib.Web, :controller
  require Logger
  import IbGib.Helper

  @delim "^"
  @root_ib_gib "ib#{@delim}gib"

  def index(conn, %{"action" => "fork", "src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib} = params) do
    Logger.debug "index. params: #{inspect params}"
    do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
  end
  def index(conn, %{"action" => "fork", "src_ib_gib" => src_ib_gib} = params) do
    Logger.debug "index. params: #{inspect params}"
    do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => new_id})
  end
  def index(conn, params) do
    Logger.debug "index. params: #{inspect params}"
    # conn = init_session(conn)
    render conn, "index.html"
  end

  defp do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib}) do
    Logger.info "fork it yo"
    case fork_impl(conn.assigns[:root], src_ib_gib, dest_ib) do
      {:ok, forked_thing} ->
        Logger.info "forked_thing: #{inspect forked_thing}"
      other ->
        Logger.debug "didn't fork thing.  other: #{inspect other}"
    end
    # Logger.debug "doesn't exist huh: #{inspect get_session(conn, :never_put)}"

    # Logger.debug "start inspect conn"
    # Logger.info "#{inspect conn}"
    # Logger.debug "end inspect conn"

    # Logger.debug "old session message: #{inspect get_session(conn, :message)}"
    # conn = put_session(conn, :message, "session msg yo: #{new_id}")
    # Logger.debug "new session message: #{inspect get_session(conn, :message)}"
    # Logger.debug "session id: #{inspect get_session(conn, :id)}"
    # message = get_session(conn, :message)
    # text conn, message

    render conn, "index.html"
  end

  defp fork_impl(root, src_ib_gib \\ @root_ib_gib, dest_ib \\ new_id)
  defp fork_impl(root, src_ib_gib, dest_ib)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) and
         src_ib_gib !== "" and src_ib_gib !== "" do
    Logger.debug "dest_ib: #{dest_ib}"
    src =
      if (src_ib_gib === "" or src_ib_gib === @root_ib_gib) do
        root
      else
        {:ok, thing} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
        thing
      end

    src |> IbGib.Expression.fork(dest_ib)
  end
end
