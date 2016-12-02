defmodule WebGib.Bus.Channels.Primary do
  @moduledoc """
  Primary channel ATOW (2016/12/01) that operates per aggregate identity (user).
  """

  use Phoenix.Channel
  require Logger

  alias WebGib.Bus.Commanding
  import IbGib.Helper
  import WebGib.Validate

  intercept ["user_cmd", "user_cmd2"]

  def join("primary:" <> agg_id_hash, message, socket) do
    _ = Logger.debug("identity:#{agg_id_hash}.\nmessage: #{inspect message}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
    {:ok, socket}
  end
  def join(topic, message, socket) do
    _ = Logger.debug("unknown topic: #{topic}.\nmessage: #{inspect message}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
    {:error, %{reason: "unmatched topic yo"}}
  end
  # def join("ibgib:" <> user_token, _params, socket) do
  #   # Explore this when we've got it set up, because we need to authorize
  #   # channels.
  #   {:ok, socket}
  #   # {:error, %{reason: "unauthorized"}}
  # end
  # def join("ibgib:" <> _private_room_id, _params, _socket) do
  #   # Explore this when we've got it set up, because we need to authorize
  #   # channels.
  #   {:error, %{reason: "unauthorized"}}
  # end

  # def handle_in("user_cmd", %{"body" => body}, socket) do
  #   _ = Logger.debug("in user_cmd.\nbody: #{inspect body}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
  #
  #   broadcast! socket, "user_cmd", %{body: body}
  #   {:noreply, socket}
  # end
  # def handle_in("user_cmd2", %{"body" => body}, socket) do
  #   _ = Logger.debug("in user_cmd2 yo.\nbody: #{inspect body}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
  #
  #   broadcast! socket, "user_cmd2", %{body: body}
  #   {:noreply, socket}
  # end
  def handle_in(msg_name,
                %{"data" => data,
                  "metadata" => %{"type" => "cmd"} = metadata
                } = msg,
                socket) do
    _ = Logger.debug("msg_name: #{msg_name}\ndata: #{inspect data}\nmetadata: #{inspect metadata}\nmsg: #{inspect msg}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)

    Commanding.handle_cmd(msg_name, data, metadata, msg, socket)
  end

  @doc """
  http://www.phoenixframework.org/docs/channels

  > broadcast!/3 will notify all joined clients on this socket's topic and invoke their handle_out/3 callbacks. handle_out/3 isn't a required callback, but it allows us to customize and filter broadcasts before they reach each client. By default, handle_out/3 is implemented for us and simply pushes the message on to the client, just like our definition. We included it here because hooking into outgoing events allows for powerful message customization and filtering. Let's see how.
  """
  def handle_out("user_cmd", payload, socket) do
    _ = Logger.debug("out user_cmd.\npayload: #{inspect payload}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)

    push socket, "user_cmd", payload
    {:noreply, socket}
  end
  def handle_out("user_cmd2", payload, socket) do
    _ = Logger.debug("out user_cmd2 yoooo.\npayload: #{inspect payload}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)

    push socket, "user_cmd2", payload
    {:noreply, socket}
  end
end
