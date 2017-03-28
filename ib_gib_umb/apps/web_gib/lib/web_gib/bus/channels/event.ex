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
  require OK
  use Phoenix.Channel

  alias IbGib.Auth.Authz
  import IbGib.{Expression, Helper, Macros}
  use IbGib.Constants, :error_msgs
  use WebGib.Constants, :keys

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


  ## :update
  
  An update to an ibGib has occurred. Broadcasts the old and new ib^gibs on
  the corresponding `temp_junc_ib_gib` event channel.

  ## :new_adjunct
  
  A new adjunct has been created for the given target. 
  This is broadcasted on the given `temp_junc_ib_gib` event channel.

  ## :ident_email/unident_email

  The user has added/removed identity. Broadcasts on the user's `session_ib_gib`
  event channel.
  
  ## :oy
  
  A new oy! notification ibGib has been created. Broadcasts on each of the 
  email identity channels. Does not broadcast on a node, session, or any other
  channel. (ATOW 2017/03/14 email is the only non-anonymous identity 
  authorization tier available to the user.)

  """
  def broadcast_ib_gib_event(:update = msg_type,
                             {old_ib_gib, new_ib_gib} = msg_info) do
    OK.with do
      temp_junc_ib_gib <- get_temporal_junction_ib_gib(old_ib_gib)
      _ = Logger.debug("update: old_ib_gib: #{old_ib_gib}\nnew_ib_gib: #{new_ib_gib}\ntemp_junc_ib_gib: #{temp_junc_ib_gib}")
      msg <- get_broadcast_msg(msg_type, 
                               {temp_junc_ib_gib, old_ib_gib, new_ib_gib})
      
      # Store in cache with timestamp
      :ok <- 
        IbGib.Data.Cache.put(@query_cache_prefix_key <> old_ib_gib,
                             %{latest: new_ib_gib, 
                               timestamp: :erlang.system_time(:milli_seconds)})

      # Not interested if the broadcast errors. It is possible that the topic
      # doesn't even exist (no one is signed up to hear it).
      _ = WebGib.Endpoint.broadcast("event:" <> temp_junc_ib_gib,
                                    Atom.to_string(msg_type), msg)

      OK.success :ok
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def broadcast_ib_gib_event(:new_adjunct = msg_type,
                             {temp_junc_ib_gib,
                              adjunct_ib_gib,
                              target_ib_gib} = msg_info) do
    with(
      {:ok, msg} <- get_broadcast_msg(msg_type,
                                      {temp_junc_ib_gib,
                                       adjunct_ib_gib,
                                       target_ib_gib}),
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
  def broadcast_ib_gib_event(:ident_email = msg_type,
                             {session_ib_gib,
                              ident_ib_gib} = msg_info) do
    _ = Logger.debug("Broadcasting ident_email sir. session_ib_gib: #{session_ib_gib}" |> ExChalk.yellow |> ExChalk.bg_blue)
    with(
      {:ok, msg} <- get_broadcast_msg(msg_type,
                                      {session_ib_gib,
                                       ident_ib_gib}),
      # Not interested if the broadcast errors. It is possible that the topic
      # doesn't even exist (no one is signed up to hear it).
      result <-
        WebGib.Endpoint.broadcast("event:" <> session_ib_gib, Atom.to_string(msg_type), msg),
      _ <- Logger.debug("broadcast result: #{inspect result}" |> ExChalk.yellow |> ExChalk.bg_blue)
    ) do
      {:ok, :ok}
    else
      error -> default_handle_error(error)
    end
  end
  def broadcast_ib_gib_event(:unident_email = msg_type,
                             {session_ib_gib,
                              ident_ib_gib} = msg_info) do
    _ = Logger.debug("Broadcasting #{msg_type} sir. msg_info: #{inspect msg_info}" |> ExChalk.yellow |> ExChalk.bg_blue)
    with(
      {:ok, msg} <- get_broadcast_msg(msg_type,
                                      {session_ib_gib,
                                       ident_ib_gib}),
      # Not interested if the broadcast errors. It is possible that the topic
      # doesn't even exist (no one is signed up to hear it).
      result <-
        WebGib.Endpoint.broadcast("event:" <> session_ib_gib, Atom.to_string(msg_type), msg),
      _ <- Logger.debug("broadcast result: #{inspect result}" |> ExChalk.yellow |> ExChalk.bg_blue)
    ) do
      {:ok, :ok}
    else
      error -> 
        Logger.error("whaaa funkfunk")
        default_handle_error(error)
    end
  end
  def broadcast_ib_gib_event(:oy = msg_type,
                             {oy_kind = :adjunct, 
                              oy_name, 
                              oy_ib_gib, 
                              adjunct_identities,
                              target_email_identities} = msg_info) do
    _ = Logger.debug("Broadcasting #{msg_type} sir. msg_info: #{inspect msg_info}" |> ExChalk.yellow |> ExChalk.bg_blue)
    OK.with do
      # Get the msg. The same message will be broadcasted on all email channels.
      # So if the user is logged in with multiple emails, then the user will
      # get multiple oys for that device. (They could only have one or the other
      # on any given device at a time, so must "spam" all of them.)
      msg <- 
        get_broadcast_msg(msg_type, {oy_kind, 
                                     oy_name, 
                                     oy_ib_gib, 
                                     adjunct_identities,
                                     target_email_identities})
        
      # Broadcast to each email identity event channel.
      :ok <-
        target_email_identities
        |> Enum.reduce({:ok, :ok}, fn(identity_ib_gib, _acc) -> 
             # Not interested if the broadcast errors. It is possible that the
             # topic doesn't even exist (no one is signed up to hear it).
             _ = WebGib.Endpoint.broadcast("event:" <> identity_ib_gib,
                                           Atom.to_string(msg_type), 
                                           msg)
             {:ok, :ok}
           end)
           
      OK.success :ok
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
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
  # A new adjunct has just been added to a target
  defp get_broadcast_msg(:new_adjunct = msg_type,
                         {temp_junc_ib_gib,
                          adjunct_ib_gib,
                          target_ib_gib} = _msg_info) do
    msg = %{
      "data" => %{
        "adjunct_ib_gib" => adjunct_ib_gib,
        "target_ib_gib" => target_ib_gib
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
  # An adjunct has just been directly rel8d to a target
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
  defp get_broadcast_msg(:ident_email = msg_type,
                         {session_ib_gib,
                          ident_ib_gib} = _msg_info) do
    msg = %{
      "data" => %{
        "session_ib_gib" => session_ib_gib,
        "ident_ib_gib" => ident_ib_gib
      },
      "metadata" => %{
        "name" => Atom.to_string(msg_type),
        "session_ib_gib" => session_ib_gib,
        "src" => "server",
        "timestamp" => "#{:erlang.system_time(:milli_seconds)}"
      }
    }
    {:ok, msg}
  end
  defp get_broadcast_msg(:unident_email = msg_type,
                         {session_ib_gib,
                          ident_ib_gib} = _msg_info) do
    msg = %{
      "data" => %{
        "session_ib_gib" => session_ib_gib,
        "ident_ib_gib" => ident_ib_gib
      },
      "metadata" => %{
        "name" => Atom.to_string(msg_type),
        "session_ib_gib" => session_ib_gib,
        "src" => "server",
        "timestamp" => "#{:erlang.system_time(:milli_seconds)}"
      }
    }
    {:ok, msg}
  end
  defp get_broadcast_msg(:oy = msg_type,
                         {oy_kind = :adjunct, 
                          oy_name, 
                          oy_ib_gib, 
                          adjunct_identities,
                          target_email_identities} = msg_info) do
    #
    msg = %{
      "data" => %{
        "oy_ib_gib" => oy_ib_gib,
        "adjunct_identities" => adjunct_identities,
        "target_email_identities" => target_email_identities
      },
      "metadata" => %{
        "name" => Atom.to_string(msg_type),
        "oy_name" => oy_name,
        "oy_kind" => oy_kind,
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
