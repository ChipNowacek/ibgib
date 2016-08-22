defmodule WebGib.Plugs.IbGibSession do
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
    options
  end

  @doc """
  Initialize ib_gib session logic:
    Get the session id
    If it doesn't exist create it and store it.
    Create/resume actual ib_gib for session.
    Inject the session ib^gib into assigns.
  """
  def call(conn, options) do
    session_id = get_session(conn, @session_id_key)
    {session_id, conn} =
      if session_id == nil do
        session_id = IbGib.Helper.new_id
        Logger.debug "Session did not exist. Putting new session id: #{session_id}"
        conn = put_session(conn, @session_id_key, session_id)
        {session_id, conn}
      else
        Logger.debug "Session existed. session id: #{session_id}"
        {session_id, conn}
      end
    conn = case IbGib.Identity.start_or_resume_session(session_id) do
      {:ok, session_ib_gib} ->
        assign(conn, @session_ib_gib_key, session_ib_gib)
      error ->
        raise WebGib.Exceptions.BadSession
    end

    conn
  end
end
