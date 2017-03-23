defmodule WebGib.Bus.Commanding.Fork do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)
  """
  
  import Expat # https://github.com/vic/expat
  import OK, only: ["~>>": 2]
  require Logger
  require OK

  alias WebGib.Adjunct
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper}
  import IbGib.Macros, only: [handle_ok_error: 2]
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib

  defpat fork_data_(
    dest_ib_() =
    context_ib_gib_() =
    src_ib_gib_()
  )
  
  def handle_cmd(fork_data_(...) = data,
                 metadata,
                 msg,
                 socket)
    when is_nil(dest_ib) or dest_ib == "" do
    _ = Logger.debug("shook this path yo" |> ExChalk.blue |> ExChalk.bg_white)

    # dest_ib is empty or nil, so fill it with either the src ib or a new id
    dest_ib =
      if valid_ib_gib?(src_ib_gib) do
        {src_ib, _gib} = separate_ib_gib!(src_ib_gib)
        src_ib
      else
        new_id()
      end
    data = Map.put(data, "dest_ib", dest_ib)
    msg = Map.put(msg, "data", data)

    handle_cmd(data, metadata, msg, socket)
  end
  def handle_cmd(fork_data_(...) = _data,
                 _metadata,
                 msg,
                 %{assigns:
                   %{ib_identity_ib_gibs: identity_ib_gibs}
                 } = socket) do
    _ = Logger.debug("yakkerzz. src_ib_gib: #{src_ib_gib}" |> ExChalk.blue |> ExChalk.bg_white)
    OK.with do
      # Validate
      true <- validate_input({:ok, :dest_ib}, 
                             dest_ib, 
                             "Invalid destination ib.")
      true <- validate_input({:ok, :context_ib_gib},
                             context_ib_gib, 
                             "Invalid context ibGib", 
                             :ib_gib)
      true <- validate_input({:ok, :src_ib_gib}, 
                             src_ib_gib, 
                             "Invalid source ibGib", 
                             :ib_gib)
                             
      # Execute
      {forked_ib_gib, new_context_ib_gib_or_nil} <-
       exec_impl(identity_ib_gibs, src_ib_gib, dest_ib, context_ib_gib)

      # Broadcast updated src_ib_gib if different
      _ = if context_ib_gib !== new_context_ib_gib_or_nil and
             new_context_ib_gib_or_nil != nil do
            EventChannel.broadcast_ib_gib_event(
              :update, 
              {context_ib_gib, new_context_ib_gib_or_nil}
            )
          else
            _ = Logger.debug("new context is nil. not broadcasting.")
            :ok
          end

      # Reply
      reply_msg <- get_reply_msg(forked_ib_gib, new_context_ib_gib_or_nil)
      
      OK.success reply_msg
    else
      reason -> handle_cmd_error(:error, reason, msg, socket)
    end
  end

  defp exec_impl(identity_ib_gibs, src_ib_gib, dest_ib, context_ib_gib) do
    OK.with do
      forked_pid <-
        {:ok, src_ib_gib}
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> fork(identity_ib_gibs, dest_ib, @default_transform_options)

      forked_ib_gib <- 
        {:ok, forked_pid}
        ~>> get_info()
        ~>> get_ib_gib()
      
      new_context_ib_gib_or_nil <-
        get_new_context_ib_gib(identity_ib_gibs, context_ib_gib, forked_pid)
        
      OK.success {forked_ib_gib, new_context_ib_gib_or_nil}
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end

  # If the context is the root, returns {:ok, nil}
  # If the user is authzd to rel8 to context, returns {:ok, new_ib_gib}
  # If the user NOT authzd to rel8 to context, returns {:ok, nil}
  defp get_new_context_ib_gib(identity_ib_gibs, 
                              context_ib_gib, 
                              forked_pid)
  defp get_new_context_ib_gib(identity_ib_gibs, 
                              @root_ib_gib, 
                              forked_pid) do
    # context_ib_gib is the root, so return nil
    {:ok, nil}
  end
  defp get_new_context_ib_gib(identity_ib_gibs, 
                              context_ib_gib, 
                              forked_pid) do
    OK.with do
      new_context <- 
        {:ok, context_ib_gib}
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> Adjunct.rel8_target_to_other_if_authorized(
              forked_pid, 
              identity_ib_gibs, 
              @default_rel8ns
            )
            
      new_context_info <- 
        if new_context, do: get_info(new_context), else: {:ok, nil}
        
      new_context_ib_gib_or_nil <-
        if new_context_info, do: get_ib_gib(new_context_info), else: {:ok, nil}
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end

  defp get_reply_msg(forked_ib_gib, new_context_ib_gib_or_nil) do
    reply_msg =
      %{
        "data" => %{
          "forked_ib_gib" => forked_ib_gib,
          "new_context_ib_gib_or_nil" => new_context_ib_gib_or_nil
        }
      }
    {:ok, reply_msg}
  end

end
