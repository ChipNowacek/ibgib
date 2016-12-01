defmodule WebGib.Bus.Commanding do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)
  """

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  import IbGib.Expression
  import IbGib.Helper

  # fork command
  def handle_cmd("fork" = cmd_name,
                  %{"dest_ib" => dest_ib,
                    "src_ib_gib" => src_ib_gib} = data,
                  metadata,
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

    handle_cmd(cmd_name, data, metadata, msg, socket)
  end
  def handle_cmd("fork" = cmd_name,
                 %{"dest_ib" => dest_ib,
                   "src_ib_gib" => src_ib_gib} = data,
                 _metadata,
                 msg,
                 %{assigns:
                   %{ib_identity_ib_gibs: identity_ib_gibs}
                 } = socket) do
    _ = Logger.debug("yoooo" |> ExChalk.blue |> ExChalk.bg_white)
    with(
      {:dest_ib, true}      <- validate_input(:dest_ib, dest_ib),
      {:src_ib_gib, true}   <- validate_input(:src_ib_gib, src_ib_gib),
      {:ok, forked_ib_gib}  <- fork_impl(identity_ib_gibs, dest_ib, src_ib_gib),
      {:ok, reply_msg} <- get_reply_msg("fork", forked_ib_gib)
    ) do
      {:reply, reply_msg, socket}
    else
      # {:dest_ib, error} ->
      #   handle_cmd_error(:dest_ib, "Invalid destination ib", msg, socket)
      # {:src_ib_gib, error} ->
      #   handle_cmd_error(:src_ib_gib, "Invalid source ibGib", msg, socket)
      # {:error, reason} ->
      #   handle_cmd_error(:error, inspect reason, msg, socket)
      error ->
        handle_cmd_error(:error, inspect error, msg, socket)
    end
  end

  defp fork_impl(identity_ib_gibs, src_ib_gib, dest_ib) do
    with(
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, forked_pid} <-
        src |> fork(identity_ib_gibs, dest_ib, @default_transform_options),
      {:ok, forked_info} <- get_info(forked_pid),
      {:ok, forked_ib_gib} <- get_ib_gib(forked_info)
    ) do
      {:ok, forked_ib_gib}
    else
      error ->  default_handle_error(error)
    end
  end

  defp get_reply_msg("fork", forked_ib_gib) do
    %{
      "data" => %{
        "forked_ib_gib" => "forked_ib_gib"
      }
    }
  end

  # ------------------------------------------------------------------------
  # Error
  # ------------------------------------------------------------------------

  def handle_cmd_error(:error, reason, msg, socket) do
    # stub - do nothing right now :-/
    _ = Logger.error("error reason: #{inspect reason}.\nmsg: #{inspect msg}\nsocket: #{inspect socket}")
    error_msg = %{
      "errors" => [
        %{
          "id" => "General Gibberish",
          "title" => "Generic Error Msg Oh No! :-?",
          "detail" => reason
        }
      ]
    }
    {:reply, {:error, error_msg}, socket}
  end

  # ------------------------------------------------------------------------
  # Helper
  # ------------------------------------------------------------------------

  # Convenience wrapper that wraps validate call for use in `with` statement
  # error pattern matching.
  defp validate_input(name, value, emsg) do
    {name, validate(name, value)}
  end
end
