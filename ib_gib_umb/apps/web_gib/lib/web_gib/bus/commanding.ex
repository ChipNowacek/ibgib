defmodule WebGib.Bus.Commanding do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)

  Could probably simplify this with a macro, but typing it out is easy and it
  gives me time to chug on things in the brain.
  """

  require Logger

  alias WebGib.Bus.Commanding.{Fork, Comment, Refresh, BatchRefresh, Ack, GetAdjuncts, Mut8Comment, Link, Tag, Trash, GetOys}
  import WebGib.Bus.Commanding.Helper

  def handle_cmd(cmd_name, data, metadata, msg, socket) do
    _ = Logger.debug("cmd_name: #{cmd_name}\ndata: #{inspect data}\nmetadata: #{inspect metadata}\nmsg: #{inspect msg}\nsocket: #{inspect socket}" |> ExChalk.bg_cyan |> ExChalk.red)
    # Wrapping in `try` b/c we absolutely don't want to crash when handling cmd.
    # We always want to return a response to the client.
    try do
      cmd_result = 
        case handle_cmd_impl(cmd_name, data, metadata, msg, socket) do
          {:ok, reply_msg} when is_map(reply_msg) -> 
            {:ok, reply_msg}
            
          {:ok, improper_reply} -> 
            emsg = "Reply msg must be a map. (ok)"
            Logger.error emsg
            {:error, %{"error" => emsg}}
          
          {:error, error_map} when is_map(error_map) ->
            {:error, error_map}
            
          {:error, error} when is_bitstring(error) ->
            {:error, %{"error" => error}}

          {:error, error} ->
            {:error, %{"error" => inspect(error)}}
          
          other ->
            emsg = "Reply msg must be an ok/error tuple. (other)"
            Logger.error emsg
            {:error, %{"error" => emsg}}
        end
        
      {:reply, cmd_result, socket}
    rescue
      error ->  
        emsg = "Exception raised. error: #{inspect error}"
        {
          :reply, 
          {:error, %{"error" => emsg, "details" => inspect(error)}}, 
          socket
        }
    end
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
  defp handle_cmd_impl("batchrefresh", data,  metadata, msg, socket) do
    BatchRefresh.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("ack", data,  metadata, msg, socket) do
    Ack.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("getadjuncts", data,  metadata, msg, socket) do
    GetAdjuncts.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("mut8comment", data,  metadata, msg, socket) do
    Mut8Comment.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("link", data,  metadata, msg, socket) do
    Link.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("tag", data,  metadata, msg, socket) do
    Tag.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("trash", data,  metadata, msg, socket) do
    Trash.handle_cmd(data, metadata, msg, socket)
  end
  defp handle_cmd_impl("getoys", data,  metadata, msg, socket) do
    result = GetOys.handle_cmd(data, metadata, msg, socket)
    Logger.debug "result: #{inspect result}"
    result
  end
  defp handle_cmd_impl(cmd_name, data, metadata, msg, socket) do
    emsg = "Unknown command params. cmd_name: #{inspect cmd_name}"
    handle_cmd_error(:error, emsg, msg, socket)
  end
end
