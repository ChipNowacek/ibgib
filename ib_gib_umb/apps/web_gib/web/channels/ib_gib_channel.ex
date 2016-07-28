# defmodule WebGib.IbGibChannel do
#   use Phoenix.Channel
#   require Logger
#
#   @moduledoc """
#   http://www.phoenixframework.org/docs/channels
#
#   > broadcast!/3 will notify all joined clients on this socket's topic and invoke their handle_out/3 callbacks. handle_out/3 isn't a required callback, but it allows us to customize and filter broadcasts before they reach each client. By default, handle_out/3 is implemented for us and simply pushes the message on to the client, just like our definition. We included it here because hooking into outgoing events allows for powerful message customization and filtering. Let's see how.
#   """
#
#   @doc """
#   updates include ib_gib that have been mut8d or related.
#   """
#   def join("update:updates", _message, socket) do
#     Logger.debug "ibgib:updates"
#     {:ok, socket}
#   end
#   # def join("room:" <> _private_room_id, _params, _socket) do
#   #   Logger.debug "join error"
#   #   {:error, %{reason: "unauthorized"}}
#   # end
#
#   def handle_in("updates", %{"ib" => ib, "gib" => gib} = updated_ib_gib, socket)
#     when is_list(ib) and is_list(gib) do
#     broadcast! socket, "updates", updated_ib_gib
#     {:noreply, socket}
#   end
#
#   @doc """
#   Filter outgoing messages
#   """
#   def handle_out("updates", payload, socket) do
#     push socket, "updates", payload
#     {:noreply, socket}
#   end
# end
