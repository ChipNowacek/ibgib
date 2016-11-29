defmodule WebGib.IbGibChannel do
  use Phoenix.Channel
  require Logger

  @moduledoc """
  http://www.phoenixframework.org/docs/channels

  > broadcast!/3 will notify all joined clients on this socket's topic and invoke their handle_out/3 callbacks. handle_out/3 isn't a required callback, but it allows us to customize and filter broadcasts before they reach each client. By default, handle_out/3 is implemented for us and simply pushes the message on to the client, just like our definition. We included it here because hooking into outgoing events allows for powerful message customization and filtering. Let's see how.
  """

  def join("ibgib:lobby", _message, socket) do
    # Anyone can join this one. I think we'll end up commenting this one out.
    {:ok, socket}
  end
  def join("ibgib:" <> user_token, _params, socket) do
    # Explore this when we've got it set up, because we need to authorize
    # channels.
    {:ok, socket}
    # {:error, %{reason: "unauthorized"}}
  end
  def join("ibgib:" <> _private_room_id, _params, _socket) do
    # Explore this when we've got it set up, because we need to authorize
    # channels.
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end

  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end
end
