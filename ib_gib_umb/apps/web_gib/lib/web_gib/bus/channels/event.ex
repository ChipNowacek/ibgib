defmodule WebGib.Bus.Channels.Event do
  @moduledoc """
  Channel used for **events** sent from the server to the client.

  On the `WebGib.Bus.Channels.Command` command channel, there can still be
  "events" in the sense that the command gets back a reply. But ATOW
  (2016/12/03), the events only flow from the server the client.

  ## General Idea - Events

  So the idea is that the client has ibGib on their ibScape(s). These ibGib
  need to know when they are "updated", either via a `mut8`, `rel8`, or `plan`
  that contains `mut8`/`rel8`. To enable this, we create a topic:subtopic for
  each ibGib in the form of "event:{ib_gib}". Some examples would be:

  `"event:ib^123ABC"`
  `"event:House^456DEF"`
  `"event:WaffleGib^789GHI"`

  So when a command is received and handled on the server, it returns a reply
  containing any _new_ ibGib directly to the client of origin. Any _existing_
  ibGib that are updated in the process have a corresponding event broadcasted
  on the possible channel for the entire endpoint.

  ## Authorization (or lack thereof)

  Since everyone has authorization to read notifications on all ibGib, and this
  channel only goes from the server to the client, these will be public
  channels, i.e. no authorization required.
  """

  use Phoenix.Channel
  require Logger

  import IbGib.Helper

  # intercept ["user_cmd", "user_cmd2"]

  @doc """
  Joins the channel.

  See `WebGib.Bus.Channels.Event` module documentation for more info.
  """
  def join(topic, message, socket)
  def join("event:" <> ib_gib, message, socket) do
    _ = Logger.debug("event:#{ib_gib}.\nmessage: #{inspect message}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
    {:ok, socket}
  end
  def join(topic, message, socket) do
    _ = Logger.error("unknown topic: #{topic}.\nmessage: #{inspect message}\nsocket: #{inspect socket}")
    {:error, %{reason: "unmatched topic hrmm"}}
  end

  @doc """
  Replies with an error, because this channel is designed only to send messages
  from the server to the client.

  See `WebGib.Bus.Channels.Event` module documentation for more info.
  """
  def handle_in(msg_name, msg, socket) do
    _ = Logger.debug("msg_name: #{msg_name}\nmsg: #{inspect msg}\nsocket: #{inspect socket}" |> ExChalk.bg_red |> ExChalk.black)
    emsg = "This channel only broadcasts from the server to the client."
    {:reply, {:error, emsg}, socket}
  end


  def broadcast_ib_gib_update(old_ib_gib, new_ib_gib) do
    msg_name = "update"
    msg = %{
      "data" => %{
        "old_ib_gib" => old_ib_gib,
        "new_ib_gib" => new_ib_gib,
      },
      "metadata" => %{
        "name" => msg_name,
        "timestamp" => "#{:erlang.system_time(:milli_seconds)}"
      }
    }
    # I don't care if the broadcast errors. It is possible that the topic
    # doesn't even exist.
    broadcast_result =
      WebGib.Endpoint.broadcast("event:" <> old_ib_gib, msg_name, msg)
    Logger.debug("broadcast_result:\n#{inspect broadcast_result}" |> ExChalk.bg_cyan |> ExChalk.black)
    Logger.debug("old_ib_gib:\n#{old_ib_gib}\nmsg: #{inspect msg}" |> ExChalk.bg_cyan |> ExChalk.black)

    {:ok, :ok}
  end
  # @doc """
  # http://www.phoenixframework.org/docs/channels
  #
  # > broadcast!/3 will notify all joined clients on this socket's topic and invoke their handle_out/3 callbacks. handle_out/3 isn't a required callback, but it allows us to customize and filter broadcasts before they reach each client. By default, handle_out/3 is implemented for us and simply pushes the message on to the client, just like our definition. We included it here because hooking into outgoing events allows for powerful message customization and filtering. Let's see how.
  # """
  # def handle_out("user_cmd", payload, socket) do
  #   _ = Logger.debug("out user_cmd.\npayload: #{inspect payload}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
  #
  #   push socket, "user_cmd", payload
  #   {:noreply, socket}
  # end
  # def handle_out("user_cmd2", payload, socket) do
  #   _ = Logger.debug("out user_cmd2 yoooo.\npayload: #{inspect payload}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
  #
  #   push socket, "user_cmd2", payload
  #   {:noreply, socket}
  # end
end
