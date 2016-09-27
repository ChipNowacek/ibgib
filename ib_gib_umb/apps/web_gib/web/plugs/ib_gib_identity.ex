defmodule WebGib.Plugs.IbGibIdentity do
  @moduledoc """
  "Logs in" a user based on session info.
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
    Logger.debug "uh huh hrm....whaaa"
    identity_ib_gibs = get_session(conn, @ib_identity_ib_gibs_key)

    if identity_ib_gibs == nil do
      Logger.debug "no identity ib gibs (nil)"

      session_ib_gib = get_session_ib_gib(conn)
      {priv_data, pub_data} = get_priv_and_pub_data(conn, session_ib_gib)
      get_and_put_session_identity(conn, priv_data, pub_data)
    else
      # identity_ib_gibs is not nil, so just return the connection
      conn
    end
  end

  defp get_session_ib_gib(conn) do
    # Must be a current valid session.
    session_ib_gib = get_session(conn, @ib_session_id_key)

    # This shouldn't happen, since we have WebGib.Plugs.EnsureIbGibSession
    # But I'm checking anyway.
    if session_ib_gib == nil do
      Logger.error @emsg_invalid_session
      raise WebGib.Errors.SessionError
    end
    session_ib_gib
  end

  defp get_priv_and_pub_data(conn, session_ib_gib) do
    priv_data = %{
      @ib_session_ib_gib_key => session_ib_gib
    }

    # Thanks http://blog.danielberkompas.com/elixir/2015/06/16/rate-limiting-a-phoenix-api.html
    ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    pub_data = %{
      "ip" => ip
    }

    {priv_data, pub_data}
  end

  # This creates a new session identity ib_gib, then stores it in BOTH the
  # @session_ib_gib_key and @identity_ib_gibs_key (array).
  defp get_and_put_session_identity(conn, priv_data, pub_data) do
    case Identity.get_identity(priv_data, pub_data) do
      {:ok, identity_ib_gib} ->
        Logger.warn "putting identity_ib_gib into session. identity_ib_gib: #{identity_ib_gib}"
        # {:ok, identity} = Expression.Supervisor.start_expression(identity_ib_gib)

        conn
        |> put_session(@ib_session_ib_gib_key, identity_ib_gib)
        |> put_session(@ib_identity_ib_gibs_key,
                       [@root_ib_gib, identity_ib_gib])

      {:error, reason} when is_bitstring(reason) ->
        Logger.error "Error with identity. Reason: #{reason}"
        raise WebGib.Errors.IdentityError

      {:error, reason} ->
        Logger.error "Error with identity. Reason: #{inspect reason}"
        raise WebGib.Errors.IdentityError

      error ->
        Logger.error "Error with identity. Reason: #{inspect error}"
        raise WebGib.Errors.IdentityError
    end
  end
end
