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
      {:ok, {priv_data, pub_data}} <- get_priv_and_pub_data(),
      {:ok, identity} <- Identity.get_identity(priv_data, pub_data)
    ) do
      {:ok, identity}
    else
      error -> default_handle_error(error)
    end
  end

  def get_current_node_identity_ib_gib() do
    with(
      {:ok, identity} <- get_current_node_identity(),
      {:ok, info} <- get_info(identity),
      {:ok, ib_gib} <- get_ib_gib(info)
    ) do
      {:ok, ib_gib}
    else
      error -> default_handle_error(error)
    end
  end
  
  def get_current_node_id() do
    id = Application.get_env(:web_gib, :node_id)
    if id === nil do
      {:error, "No node id found"}
    else
      {:ok, id}
    end
  end

  def get_current_node_secret() do
    secret = Application.get_env(:web_gib, :node_id_secret)
    if secret === nil do
      {:error, "No node secret found"}
    else
      {:ok, secret}
    end
  end
  
  defp get_priv_and_pub_data() do
    _ = Logger.debug("get_priv_and_pub_data")
    
    priv_data = %{
      @ib_node_id_secret_key => get_current_node_secret()
    }

    pub_data = %{
      "type" => "node",
      "id" => get_current_node_id()
    }

    {:ok, {priv_data, pub_data}}
  end

end
