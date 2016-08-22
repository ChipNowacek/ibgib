defmodule WebGib.Plugs.IbGibIdentity do
  @moduledoc """
  "Logs in" a user based on session info.
  """

  require Logger
  import Plug.Conn

  use WebGib.Constants, :keys
  alias IbGib.Auth.Identity
  import IbGib.{Expression, Helper}

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
  Initialize ib_gib identity logic.
  """
  def call(conn, options) do
    identity_ib_gibs = get_session(conn, @identity_ib_gibs_key)

    conn =
      if identity_ib_gibs == nil do
        # Must be a current valid session.
        session_ib_gib = get_session(conn, @session_ib_gib_key)
        if session_ib_gib == nil, do: raise WebGib.Errors.SessionError
        session_id = get_session(conn, @session_id_key)
        if session_id == nil, do: raise WebGib.Errors.SessionError
        conn
        # with {:ok, identity} <- Identity.get_identity(:session, session_id),
        #   {:ok, identity_info} <- identity |> get_info,
        #   {:ok, identity_ib_gib} <- identity_info |> get_ib_gib do
        #     conn = put_session(conn, @identity_ib_gibs_key, [identity_ib_gib])
        #   end
        # else
        #   raise WebGib.Errors.AuthenticationError
        # end
      else
        conn
      end

    conn
  end
end
