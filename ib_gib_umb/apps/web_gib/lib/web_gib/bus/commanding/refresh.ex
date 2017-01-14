defmodule WebGib.Bus.Commanding.Refresh do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.
  """

  require Logger

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib

  def handle_cmd(src_ib_gib_(...) = data,
                 _metadata,
                 msg,
                 assigns_identity_ib_gibs_(...) = socket) do
    _ = Logger.debug("yakker. src_ib_gib: #{src_ib_gib}" |> ExChalk.blue |> ExChalk.bg_yellow)
    with(
      # Validate
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib, src_ib_gib, "Invalid source ibGib", :ib_gib),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib,
                       {:simple, src_ib_gib != @root_ib_gib},
                       "Cannot refresh the root"),

      # Execute
      {:ok, latest_ib_gib} <- exec_impl(identity_ib_gibs, src_ib_gib),

      # latest_is_different <- src_ib_gib !== latest_ib_gib,

      # # I can't just broadcast on the channel, because this will
      # # broadcast to all connected devices (very bad).
      # # Broadcast latest_ib_gib if different
      # _ <- (if latest_is_different,
      #       do: EventChannel.broadcast_ib_gib_event(:update, {src_ib_gib, latest_ib_gib}),
      #       else: :ok),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(src_ib_gib, latest_ib_gib)
    ) do
      {:reply, {:ok, reply_msg}, socket}
    else
      {:error, reason} when is_bitstring(reason) ->
        handle_cmd_error(:error, reason, msg, socket)
      {:error, reason} ->
        handle_cmd_error(:error, inspect(reason), msg, socket)
      error ->
        handle_cmd_error(:error, inspect(error), msg, socket)
    end
  end

  defp exec_impl(identity_ib_gibs, src_ib_gib) do
    IbGib.Common.get_latest_ib_gib(identity_ib_gibs, src_ib_gib)
  end

  defp get_reply_msg(src_ib_gib, latest_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "src_ib_gib" => src_ib_gib,
          "latest_ib_gib" => latest_ib_gib,
          "latest_is_different" => src_ib_gib !== latest_ib_gib
        }
      }
    {:ok, reply_msg}
  end
end
