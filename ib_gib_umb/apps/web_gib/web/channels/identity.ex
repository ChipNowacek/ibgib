defmodule WebGib.Channels.Identity do
  @moduledoc """

  """

  use Phoenix.Channel
  require Logger

  import IbGib.Helper
  import WebGib.Validate

  def join("identity:" <> agg_id_hash, message, socket) do
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

  def handle_in("user_cmd", %{"body" => body}, socket) do
    _ = Logger.debug("in user_cmd.\nbody: #{inspect body}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)

    broadcast! socket, "user_cmd", %{body: body}
    {:noreply, socket}
  end
  def handle_in("user_cmd2", %{"body" => body}, socket) do
    _ = Logger.debug("in user_cmd2 yo.\nbody: #{inspect body}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)

    broadcast! socket, "user_cmd2", %{body: body}
    {:noreply, socket}
  end
  def handle_in(msg_name,
                %{"data" => data,
                  "metadata" => %{"type" => "cmd"} = metadata
                } = msg,
                socket) do
    _ = Logger.debug("msg_name: #{msg_name}\ndata: #{inspect data}\nmetadata: #{inspect metadata}\nmsg: #{inspect msg}\nsocket: #{inspect socket}" |> ExChalk.black |> ExChalk.green)
    handle_cmd(msg_name, data, msg, socket)
  end

  defp handle_cmd("addibgib" = cmd_name,
                  %{"dest_ib" => dest_ib,
                    "src_ib_gib" => src_ib_gib} = data,
                  msg,
                  socket)
    when is_nil(dest_ib) or dest_ib == "" do
    # dest_ib is empty or nil, so fill it with either the src ib or a new id
    dest_ib =
      if valid_ib_gib?(src_ib_gib) do
        {src_ib, _gib} = separate_ib_gib!(src_ib_gib)
        src_ib
      else
        new_id
      end
    data = Map.put(data, "dest_ib", dest_ib)
    msg = Map.put(msg, "data", data)

    handle_cmd(cmd_name, data, msg, socket)
  end
  defp handle_cmd("addibgib" = cmd_name,
                  %{"dest_ib" => dest_ib,
                    "src_ib_gib" => src_ib_gib} = data,
                  msg,
                  %{assigns:
                    %{ib_identity_ib_gibs: identity_ib_gibs}
                  } = socket) do
    _ = Logger.debug("yoooo" |> ExChalk.blue |> ExChalk.bg_white)

    with(
      {:dest_ib, true} <- validate_input(:dest_ib, dest_ib),
      {:src_ib_gib, true} <- validate_input(:src_ib_gib, src_ib_gib),
      {:ok, reply_msg} <- addibgib_impl(identity_ib_gibs, dest_ib, src_ib_gib)
    ) do
      {:reply, reply_msg, socket}
    else
      {:dest_ib, error} ->
        handle_cmd_error(:dest_ib, "Invalid destination ib", msg, socket)
      {:src_ib_gib, error} ->
        handle_cmd_error(:src_ib_gib, "Invalid source ibGib", msg, socket)
      {:error, reason} ->
        handle_cmd_error(:error, inspect reason, msg, socket)
      error ->
        handle_cmd_error(:error, inspect error, msg, socket)
    end
  end

  # Convenience wrapper that calls wraps validate call
  defp validate_input(name, value, emsg) do
    {name, validate(name, value)}
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
