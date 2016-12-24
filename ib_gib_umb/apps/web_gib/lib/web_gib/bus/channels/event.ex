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

  require Logger
  use Phoenix.Channel

  import IbGib.{Expression, Helper, Macros}
  use IbGib.Constants, :error_msgs

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


  @doc """
  Generates a msg from the given `msg_type` and `msg_info` and broadcasts it
  on the event bus.

  ## :update

  Creates an update msg and broadcasts it on the event bus.

  This will first get the "first" ib^gib corresponding to the given `old_ib_gib`
  timeline, i.e. the first (non-root) ib^gib in the "past" rel8n.

  For example, let's pretend that we have A^XYZ which is the 500th mut8n
  of the A timeline since it was first forked. In order for other references
  to each step in its history, we would have to broadcast 499 different update
  msgs to let each one know that there is an update. Obviously this is no good.
  So we just get the first A^123 (or whatever the gib hash is) and broadcast
  on that channel. This way, we don't have to subscribe to the event bus for
  every single ib^gib to get its changes, we just have to subscribe to its
  first ib^gib. We also don't have to unsubscribe and resubscribe every time
  that there is a change.

  ## :adjuncts

  Broadcasts a msg that states the given `adjunct_ib_gibs` are the **complete**
  set of adjuncts for the given `ib_gib`.

  ## :adjunct_rel8d

  Broadcasts a msg that states the given

  """
  def broadcast_ib_gib_event(:update = msg_type,
                             {old_ib_gib, new_ib_gib} = msg_info) do
    with(
      {:ok, temp_junc_ib_gib} <- get_temporal_junction_ib_gib(old_ib_gib),
      {:ok, msg} <- get_broadcast_msg(msg_type, {temp_junc_ib_gib, old_ib_gib, new_ib_gib}),
      # Not interested if the broadcast errors. It is possible that the topic
      # doesn't even exist (no one is signed up to hear it).
      _ <-
        WebGib.Endpoint.broadcast("event:" <> temp_junc_ib_gib, Atom.to_string(msg_type), msg)
    ) do
      {:ok, :ok}
    else
      error -> default_handle_error(error)
    end
  end
  def broadcast_ib_gib_event(:adjuncts = msg_type,
                             {ib_gib, adjunct_ib_gibs} = msg_info) do
    with(
      # temp_junc_ib_gib _should_ be redundant, as the incoming ib_gib should be
      # the temporal junction point.
      {:ok, temp_junc_ib_gib} <- get_temporal_junction_ib_gib(ib_gib),
      {:ok, msg} <- get_broadcast_msg(msg_type, {temp_junc_ib_gib, ib_gib, adjunct_ib_gibs}),
      # Not interested if the broadcast errors. It is possible that the topic
      # doesn't even exist (no one is signed up to hear it).
      _ <-
        WebGib.Endpoint.broadcast("event:" <> temp_junc_ib_gib, Atom.to_string(msg_type), msg)
    ) do
      {:ok, :ok}
    else
      error -> default_handle_error(error)
    end
  end
  def broadcast_ib_gib_event(:adjunct_rel8d = msg_type,
                             {adjunct_ib_gib,
                              old_target_ib_gib,
                              new_target_ib_gib} = msg_info) do
    with(
      # temp_junc_ib_gib _should_ be redundant, as the incoming ib_gib should be
      # the temporal junction point.
      {:ok, temp_junc_ib_gib} <- get_temporal_junction_ib_gib(old_target_ib_gib),
      {:ok, msg} <- get_broadcast_msg(msg_type,
                                      {temp_junc_ib_gib,
                                       adjunct_ib_gib,
                                       old_target_ib_gib,
                                       new_target_ib_gib}),
      # Not interested if the broadcast errors. It is possible that the topic
      # doesn't even exist (no one is signed up to hear it).
      _ <-
        WebGib.Endpoint.broadcast("event:" <> temp_junc_ib_gib, Atom.to_string(msg_type), msg)
    ) do
      {:ok, :ok}
    else
      error -> default_handle_error(error)
    end
  end

  defp get_broadcast_msg(:update = msg_type,
                         {temp_junc_ib_gib,
                          old_ib_gib,
                          new_ib_gib} = _msg_info)
    when is_bitstring(temp_junc_ib_gib) and temp_junc_ib_gib !== "" and
         is_bitstring(old_ib_gib) and old_ib_gib !== "" and
         is_bitstring(new_ib_gib) and new_ib_gib !== "" do
    msg = %{
      "data" => %{
        "old_ib_gib" => old_ib_gib,
        "new_ib_gib" => new_ib_gib,
      },
      "metadata" => %{
        "name" => Atom.to_string(msg_type),
        "temp_junc_ib_gib" => temp_junc_ib_gib,
        "src" => "server",
        "timestamp" => "#{:erlang.system_time(:milli_seconds)}"
      }
    }
    {:ok, msg}
  end
  defp get_broadcast_msg(:adjuncts = msg_type,
                         {temp_junc_ib_gib,
                          ib_gib,
                          adjunct_ib_gibs} = _msg_info)
    when is_list(adjunct_ib_gibs) and length(adjunct_ib_gibs) > 0 do
    msg = %{
      "data" => %{
        "ib_gib" => ib_gib,
        "adjunct_ib_gibs" => adjunct_ib_gibs
      },
      "metadata" => %{
        "name" => Atom.to_string(msg_type),
        "temp_junc_ib_gib" => temp_junc_ib_gib,
        "src" => "server",
        "timestamp" => "#{:erlang.system_time(:milli_seconds)}"
      }
    }
    {:ok, msg}
  end
  defp get_broadcast_msg(:adjunct_rel8d = msg_type,
                         {temp_junc_ib_gib,
                          adjunct_ib_gib,
                          old_target_ib_gib,
                          new_target_ib_gib} = _msg_info) do
    msg = %{
      "data" => %{
        "adjunct_ib_gib" => adjunct_ib_gib,
        "old_target_ib_gib" => old_target_ib_gib,
        "new_target_ib_gib" => new_target_ib_gib
      },
      "metadata" => %{
        "name" => Atom.to_string(msg_type),
        "temp_junc_ib_gib" => temp_junc_ib_gib,
        "src" => "server",
        "timestamp" => "#{:erlang.system_time(:milli_seconds)}"
      }
    }
    {:ok, msg}
  end
  defp get_broadcast_msg(msg_type, msg_info) do
    invalid_args([msg_type, msg_info])
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
