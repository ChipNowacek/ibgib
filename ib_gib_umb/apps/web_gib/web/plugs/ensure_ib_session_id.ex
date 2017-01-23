defmodule WebGib.Plugs.EnsureIbSessionId do
  @moduledoc """
  Ensures that there is an existing ib_gib session id (not just a "proper"
  session which every request has). If none is found, then redirects to the
  home page for the user to read.
  """

  require Logger
  import Plug.Conn
  import Phoenix.Controller

  import WebGib.Gettext
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
    If it doesn't exist, redirect the user to the home page.
  """
  def call(conn, options) do
    _ = Logger.debug "ensure ib_gib_identity plug yo."
    ib_session_id = conn |> get_session(@ib_session_id_key)
    if ib_session_id == nil do
      _ = Logger.debug "current ib session is nil"
      conn
      |> put_flash(:info, gettext "Please read ibGib's Vision and Privacy Caution before continuing. Thanks :-)")
      |> put_session(@path_before_redirect_key, conn.request_path)
      |> redirect(to: "/")
      |> halt
    else
      _ = Logger.debug "current ib session id exists"
      conn
    end
  end
end
