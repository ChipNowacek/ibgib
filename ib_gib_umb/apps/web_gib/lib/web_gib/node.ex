defmodule WebGib.Node do
  @moduledoc """
  Functions pertaining to the node the current web_gib application is running 
  on.
  """

  require Logger
  
  alias IbGib.Auth.Identity
  import IbGib.{Expression, Helper}
  use WebGib.Constants, :keys
  
  @doc """
  Gets the current node's identity.
  """
  def get_current_node_identity() do
    with(
      {:ok, identity_ib_gib} <- get_current_node_identity_ib_gib(),
      {:ok, identity} <-
        IbGib.Expression.Supervisor.start_expression(identity_ib_gib)
    ) do
      {:ok, identity}
    else
      error -> default_handle_error(error)
    end
  end

  def get_current_node_identity_ib_gib() do
    with(
      {:ok, {priv_data, pub_data}} <- get_priv_and_pub_data(),
      {:ok, ib_gib} <- Identity.get_identity(priv_data, pub_data)
    ) do
      {:ok, ib_gib}
    else
      error -> default_handle_error(error)
    end
  end
  
  def get_current_node_id() do
    id = Application.get_env(:web_gib, :node_id)
    _ = Logger.debug("node id: #{inspect id}")
    if id === nil do
      {:error, "No node id found"}
    else
      {:ok, id}
    end
  end

  def get_current_node_secret() do
    secret = Application.get_env(:web_gib, :node_id_secret)
    _ = Logger.debug("node secret: #{inspect secret}")
    if secret === nil do
      {:error, "No node secret found"}
    else
      {:ok, secret}
    end
  end
  
  defp get_priv_and_pub_data() do
    _ = Logger.debug("get_priv_and_pub_data")
    with(
      # priv_data
      {:ok, node_secret} <- get_current_node_secret(),
      {:ok, priv_data} <- {:ok, %{@ib_node_id_secret_key => node_secret}},

      # pub_data
      {:ok, node_id} <- get_current_node_id(),
      {:ok, pub_data} <- 
        {:ok, %{"type" => "node",
                "id" => node_id}}
    ) do
      {:ok, {priv_data, pub_data}}
    else
      error -> default_handle_error(error)
    end
  end

end
