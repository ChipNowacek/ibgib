defmodule WebGib.Bus.Commanding.Fork do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)
  """
  
  import Expat # https://github.com/vic/expat
  require Logger

  # alias IbGib.Transform.Plan.Factory, as: PlanFactory
  
  alias WebGib.Adjunct
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper}
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
    with(
      # Validate
      {:dest_ib, true} <-
        validate_input(:dest_ib, dest_ib, "Invalid destination ib."),
      {:context_ib_gib, true} <-
        validate_input(:context_ib_gib, context_ib_gib, "Invalid context ibGib", :ib_gib),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib, src_ib_gib, "Invalid source ibGib", :ib_gib),

      # Execute
      {:ok, {forked_ib_gib, new_context_ib_gib_or_nil}} <-
        exec_impl(identity_ib_gibs, src_ib_gib, dest_ib, context_ib_gib),

      # Broadcast updated src_ib_gib if different
      _ <- (if context_ib_gib !== new_context_ib_gib_or_nil and
            new_context_ib_gib_or_nil != nil do
              EventChannel.broadcast_ib_gib_event(:update, {context_ib_gib, new_context_ib_gib_or_nil})
            else
              _ = Logger.debug("new context is nil. not broadcasting.")
              :ok
            end),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(forked_ib_gib, new_context_ib_gib_or_nil)
    ) do
      {:ok, reply_msg}
    else
      {:error, reason} when is_bitstring(reason) ->
        handle_cmd_error(:error, reason, msg, socket)
      {:error, reason} ->
        handle_cmd_error(:error, inspect(reason), msg, socket)
      error ->
        handle_cmd_error(:error, inspect(error), msg, socket)
    end
  end

  defp exec_impl(identity_ib_gibs, src_ib_gib, dest_ib, context_ib_gib) do
    with(
      {:ok, src} <-
        IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, forked_pid} <-
        src |> fork(identity_ib_gibs, dest_ib, @default_transform_options),
      {:ok, forked_info} <- get_info(forked_pid),
      {:ok, forked_ib_gib} <- get_ib_gib(forked_info),
      
      {:ok, new_context_ib_gib_or_nil} <-
        get_new_context_ib_gib(
          identity_ib_gibs, 
          context_ib_gib, 
          forked_pid
        )
    ) do
      {:ok, {forked_ib_gib, new_context_ib_gib_or_nil}}
    else
      error -> default_handle_error(error)
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
    with(
      {:ok, context} <- 
        IbGib.Expression.Supervisor.start_expression(context_ib_gib),
      {:ok, new_context} <-
        Adjunct.rel8_target_to_other_if_authorized(
          context, 
          forked_pid, 
          identity_ib_gibs, 
          @default_rel8ns
        ),
      _ = Logger.debug("yooo what up not authzd"),
      {:ok, new_context_info} <- 
        (if new_context, do: get_info(new_context), else: {:ok, nil}),
      _ = Logger.debug("yooo what up not authzd2"),
      {:ok, new_context_ib_gib_or_nil} <-
        (if new_context_info, do: get_ib_gib(new_context_info), else: {:ok, nil})
    ) do
      _ = Logger.debug("yooo what up...new_context_ib_gib_or_nil: #{inspect new_context_ib_gib_or_nil}")
      {:ok, new_context_ib_gib_or_nil}
    else
      error -> default_handle_error(error)
    end
  end

  # defp rel8_context_to_fork(identity_ib_gibs, context_ib_gib, forked_pid) do
  #   if context_ib_gib === @root_ib_gib do
  #     # The root context never changes.
  #     {:ok, @root_ib_gib}
  #   else
  #     _ = Logger.debug("waazaaap" |> ExChalk.bg_cyan |> ExChalk.black)
  #     with(
  #       {:ok, context} <-
  #         IbGib.Expression.Supervisor.start_expression(context_ib_gib),
  #       {:ok, new_context} <-
  #         context |> rel8(forked_pid, identity_ib_gibs, @default_rel8ns),
  #       {:ok, new_context_info} <- get_info(new_context),
  #       {:ok, new_context_ib_gib} <- get_ib_gib(new_context_info)
  #     ) do
  #       {:ok, new_context_ib_gib}
  #     else
  #       error -> default_handle_error(error)
  #     end
  #   end
  # end

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
