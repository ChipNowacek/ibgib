defmodule WebGib.Plugs.IbGibIdentity do
  @moduledoc """
  Checks to see that the current user has identity information in session.
  This includes both session and node identity ib_gibs, and the 
  identity_ib_gibs key itself in session.
  
  If it doesn't, then raises a `WebGib.Errors.IdentityError`.
  """

  require Logger
  import Plug.Conn

  use IbGib.Constants, :ib_gib
  use WebGib.Constants, :keys
  use WebGib.Constants, :error_msgs
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
    _ = Logger.debug "identity plug uh huh hrm....whaaa"
    identity_ib_gibs = get_session(conn, @ib_identity_ib_gibs_key)

    if identity_ib_gibs == nil do
      _ = Logger.debug "no identity ib gibs (nil)"

      with(
        {:ok, session_identity_ib_gib} <-
          WebGib.Session.get_current_session_identity_ib_gib(conn),
        {:ok, node_identity_ib_gib} <-
          WebGib.Node.get_current_node_identity_ib_gib(),
        {:ok, conn} <- 
          add_identities(conn, session_identity_ib_gib, node_identity_ib_gib)
      ) do
        conn
      else
        error -> 
          emsg = "Error in identity plug: #{inspect error}"
          _ = Logger.error(emsg)
          raise WebGib.Errors.IdentityError
      end
    else
      # identity_ib_gibs is not nil, so just return the connection
      conn
    end
  end

  defp add_identities(conn, session_identity_ib_gib, node_identity_ib_gib) 
    when session_identity_ib_gib !== nil and node_identity_ib_gib !== nil do
    conn = 
      conn
      |> put_session(@ib_session_ib_gib_key, session_identity_ib_gib)
      |> put_session(@ib_node_ib_gib_key, node_identity_ib_gib)
      |> put_session(@ib_identity_ib_gibs_key,
                     [@root_ib_gib,
                      node_identity_ib_gib,
                      session_identity_ib_gib])
    {:ok, conn}
  end
  defp add_identities(conn, session_identity_ib_gib, node_identity_ib_gib) do
    {:error, "Invalid identity ib_gibs. session_identity_ib_gib: #{inspect session_identity_ib_gib}, node_identity_ib_gib: #{inspect node_identity_ib_gib}"}
  end


end
