defmodule WebGib.Session do
  @moduledoc """
  Functions pertaining to the current session of a user.
  
  This is not just the session object itself via Plug. This refers to the
  ib session information, e.g. ib_session_id, ib_session_ib_gib, etc.
  """

  import Plug.Conn
  require Logger

  alias IbGib.Auth.Identity
  import IbGib.{Expression, Helper, Macros}
  use WebGib.Constants, :keys
  
  @doc """
  Gets the current node's identity.
  """
  def get_current_session_identity(conn) do
    _ = Logger.debug("get_current_session_identity. conn: #{inspect conn}")
    with(
      {:ok, identity_ib_gib} <- get_current_session_identity_ib_gib(conn),
      {:ok, identity} <-
        IbGib.Expression.Supervisor.start_expression(identity_ib_gib)
    ) do
      {:ok, identity}
    else
      error -> default_handle_error(error)
    end
  end

  def get_current_session_identity_ib_gib(conn) do
    _ = Logger.debug("get_current_session_identity_ib_gib. conn: #{inspect conn}")
    with(
      {:ok, {priv_data, pub_data}} <- get_priv_and_pub_data(conn),
      {:ok, ib_gib} <- Identity.get_identity(priv_data, pub_data)
    ) do
      {:ok, ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  def get_ib_session_id(conn) do
    _ = Logger.debug("get_ib_session_id. conn: #{inspect conn}")
    ib_session_id = get_session(conn, @ib_session_id_key)
    
    if ib_session_id === nil do
      {:error, "No ib_session_id found in conn."}
    else
      {:ok, ib_session_id}
    end
  end
  
  def get_ib_session_id!(conn) do
    bang(get_ib_session_id(conn))
  end
  
  def set_ib_session_id(conn, ib_session_id) do
    _ = Logger.debug("set_ib_session_id. conn: #{inspect conn}")
    {:ok, put_session(conn, @ib_session_id_key, ib_session_id)}
  end

  def set_ib_session_id!(conn, ib_session_id) do
    bang(set_ib_session_id(conn, ib_session_id))
  end

  def get_ib_username(conn) do
    _ = Logger.debug("get_ib_username. conn: #{inspect conn}")
    ib_username = get_session(conn, @ib_username_key)
    
    if ib_username === nil do
      {:error, "No ib_username found in conn."}
    else
      {:ok, ib_username}
    end
  end

  def get_ib_username!(conn) do
    bang(get_ib_username(conn))
  end

  defp get_priv_and_pub_data(conn) do
    _ = Logger.debug("get_priv_and_pub_data. conn: #{inspect conn}")
    with(
      # priv_data
      {:ok, ib_session_id} <- get_ib_session_id(conn),
      {:ok, priv_data} <- {:ok, %{@ib_session_id_key => ib_session_id}},

      # pub_data
      {:ok, ib_username} <- get_ib_username(conn),
      {:ok, pub_data} <- 
        {:ok, %{"type" => "session",
                "username" => ib_username}}
    ) do
      {:ok, {priv_data, pub_data}}
    else
      error -> default_handle_error(error)
    end
  end

end
