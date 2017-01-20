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
    _ = Logger.debug "uh huh hrm....whaaa"
    identity_ib_gibs = get_session(conn, @ib_identity_ib_gibs_key)

    if identity_ib_gibs == nil do
      _ = Logger.debug "no identity ib gibs (nil)"

      {session_priv_data, session_pub_data} = 
        get_priv_and_pub_data(conn, :session)
      conn
      |> get_and_put_identity(:session, session_priv_data, session_pub_data)
      # get_and_put_session_identity(conn, priv_data, pub_data)
    else
      # identity_ib_gibs is not nil, so just return the connection
      conn
    end
  end

  defp get_ib_session_id!(conn) do
    # Must be a current valid session.
    ib_session_id = get_session(conn, @ib_session_id_key)

    # This shouldn't happen, since we have WebGib.Plugs.EnsureIbSessionId
    # But I'm checking anyway.
    if ib_session_id == nil do
      _ = Logger.error @emsg_invalid_session
      raise WebGib.Errors.SessionError
    end
    _ = Logger.debug("ib_session_id: #{ib_session_id}" |> ExChalk.bg_cyan |> ExChalk.black)
    ib_session_id
  end

  defp get_priv_and_pub_data(conn, :session) do
    _ = Logger.debug("get_priv_and_pub_data conn: #{inspect conn}")
    ib_session_id = get_ib_session_id!(conn)

    priv_data = %{
      @ib_session_id_key => ib_session_id
    }

    # # Thanks http://blog.danielberkompas.com/elixir/2015/06/16/rate-limiting-a-phoenix-api.html
    # mix_env = System.get_env("MIX_ENV")

    # ip =
    #   if mix_env == "dev" or mix_env == nil do
    #     conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    #   else
    #     {_, ip} =
    #       conn.req_headers
    #       |> Enum.filter(fn({header_key, header_value}) ->
    #            header_key == "x-real-ip"
    #          end)
    #       |> Enum.at(0)
    #     ip
    #   end
    pub_data = %{
      "type" => "session",
      "username" => conn |> get_session(@ib_username_key)
    }

    {priv_data, pub_data}
  end
  defp get_priv_and_pub_data(conn, :node, ib_session_id) do
    priv_data = %{
      @ib_node_secret_key => WebGib.Node.get_current_node_secret()
    }

    # # Thanks http://blog.danielberkompas.com/elixir/2015/06/16/rate-limiting-a-phoenix-api.html
    # mix_env = System.get_env("MIX_ENV")

    # ip =
    #   if mix_env == "dev" or mix_env == nil do
    #     conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    #   else
    #     {_, ip} =
    #       conn.req_headers
    #       |> Enum.filter(fn({header_key, header_value}) ->
    #            header_key == "x-real-ip"
    #          end)
    #       |> Enum.at(0)
    #     ip
    #   end
    pub_data = %{
      "type" => "node",
      "id" => WebGib.Node.get_current_node_id()
      # "ip" => ip
    }

    {priv_data, pub_data}
  end

  # This creates a new session identity ib_gib, then stores it in BOTH the
  # @session_ib_gib_key and @identity_ib_gibs_key (array).
  defp get_and_put_identity(conn, :session, priv_data, pub_data) do
    case Identity.get_identity(priv_data, pub_data) do
      {:ok, identity_ib_gib} ->
        _ = Logger.warn "putting identity_ib_gib into session. identity_ib_gib: #{identity_ib_gib}"
        # {:ok, identity} = Expression.Supervisor.start_expression(identity_ib_gib)

        conn
        |> put_session(@ib_session_ib_gib_key, identity_ib_gib)
        |> put_session(@ib_identity_ib_gibs_key,
                       [@root_ib_gib, identity_ib_gib])


      {:error, reason} when is_bitstring(reason) ->
        _ = Logger.error "Error with identity. Reason: #{reason}"
        raise WebGib.Errors.IdentityError
      {:error, reason} ->
        _ = Logger.error "Error with identity. Reason: #{inspect reason}"
        raise WebGib.Errors.IdentityError
      error ->
        _ = Logger.error "Error with identity. Reason: #{inspect error}"
        raise WebGib.Errors.IdentityError
    end
  end
  
  # # This creates a new node identity ib_gib, then stores it in BOTH the
  # # @session_ib_gib_key and @identity_ib_gibs_key (array).
  # defp get_and_put_node_identity(conn, priv_data, pub_data) do
  #   case Identity.get_identity(priv_data, pub_data) do
  #     {:ok, identity_ib_gib} ->
  #       _ = Logger.warn "putting identity_ib_gib into session. identity_ib_gib: #{identity_ib_gib}"
  #       # {:ok, identity} = Expression.Supervisor.start_expression(identity_ib_gib)
  # 
  #       conn
  #       |> put_session(@ib_session_ib_gib_key, identity_ib_gib)
  #       |> put_session(@ib_identity_ib_gibs_key,
  #                      [@root_ib_gib, identity_ib_gib])
  # 
  # 
  #     {:error, reason} when is_bitstring(reason) ->
  #       _ = Logger.error "Error with identity. Reason: #{reason}"
  #       raise WebGib.Errors.IdentityError
  #     {:error, reason} ->
  #       _ = Logger.error "Error with identity. Reason: #{inspect reason}"
  #       raise WebGib.Errors.IdentityError
  #     error ->
  #       _ = Logger.error "Error with identity. Reason: #{inspect error}"
  #       raise WebGib.Errors.IdentityError
  #   end
  # end

end
