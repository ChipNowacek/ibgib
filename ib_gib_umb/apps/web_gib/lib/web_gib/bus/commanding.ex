defmodule WebGib.Bus.Commanding do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)
  """

  require Logger

  alias WebGib.Bus.Commanding.{Fork, Comment, Refresh}

  def handle_cmd(cmd_name, data, metadata, msg, socket) do
    _ = Logger.debug("cmd_name: #{cmd_name}\ndata: #{inspect data}\nmetadata: #{inspect metadata}\nmsg: #{inspect msg}\nsocket: #{inspect socket}" |> ExChalk.bg_cyan |> ExChalk.red)

    handle_cmd_impl(cmd_name, data, metadata, msg, socket)
  end

  defp handle_cmd_impl("fork", data,  metadata, msg, socket) do
    Fork.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("comment", data,  metadata, msg, socket) do
    Comment.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("refresh", data,  metadata, msg, socket) do
    Refresh.handle_cmd(data, metadata, msg, socket)
  end
end
