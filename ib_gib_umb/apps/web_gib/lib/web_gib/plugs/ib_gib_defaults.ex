defmodule WebGib.Plugs.IbGibDefaults do
  @moduledoc """
  Injects default common info used with ib_gib functions.
  """

  require Logger

  import Plug.Conn

  use WebGib.Constants, :keys

  @doc """
  This options is created at "compile time" (when there is a request).
  It is then passed to the `call/2` function, so whatever is returned here
  will be used at runtime there.

  Returns `:ok` by default.
  """
  def init(options) do
    Logger.debug "inspect options: #{inspect options}"
    options
  end

  @doc """
  Inject the root ib ("ib^gib") into conn assigns.
  """
  def call(conn, options) do
    Logger.debug("conn: #{inspect conn}")
    Logger.debug "inspect options: #{inspect options}"
    {:ok, root} = IbGib.Expression.Supervisor.start_expression
    Logger.debug "assigning root in plug. root: #{inspect root}"
    conn = assign(conn, :root, root)

    session_id = get_session(conn, @ib_gib_session_id_key)
    Logger.warn "1 session_id: #{inspect session_id}"
    {session_id, conn} =
      if session_id == nil do
        session_id = IbGib.Helper.new_id
        Logger.warn "Session did not exist. Putting new session id: #{session_id}"
        put_session(conn, @ib_gib_session_id_key, session_id)
        {session_id, conn}
      else
        Logger.warn "Session existed. session id: #{session_id}"
        {session_id, conn}
      end
      Logger.warn "222222222222"
    conn = case IbGib.Identity.start_or_resume_session(session_id) do
      {:ok, session_ib_gib} ->
        Logger.warn "2222222222223333333333333333"
        assign(conn, @session_ib_gib_key, session_ib_gib)
      error ->
        raise WebGib.Exceptions.BadSession
    end
    Logger.warn "333333333333333"
    conn
  end
end
