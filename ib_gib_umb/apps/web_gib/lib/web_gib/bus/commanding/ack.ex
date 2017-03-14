defmodule WebGib.Bus.Commanding.Ack do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)
  """

  require Logger

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  alias IbGib.Auth.Authz
  import IbGib.{Expression, Helper}
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib

  def handle_cmd(adjunct_ib_gib_(...) = data,
                 _metadata,
                 msg,
                 %{assigns:
                   %{ib_identity_ib_gibs: identity_ib_gibs}
                 } = socket) do
    _ = Logger.debug("conkers. adjunct_ib_gib: #{adjunct_ib_gib}" |> ExChalk.blue |> ExChalk.bg_white)
    with(
      # Validate
      {:adjunct_ib_gib, true} <-
        validate_input(:adjunct_ib_gib, adjunct_ib_gib, "Invalid adjunct ibGib", :ib_gib),
      {:adjunct_ib_gib, true} <-
        validate_input(:adjunct_ib_gib,
                       {:simple, adjunct_ib_gib != @root_ib_gib},
                       "The root ib not an adjunct ibGib."),

      # Execute
      {:ok, {old_target_ib_gib, new_target_ib_gib}} <-
        exec_impl(identity_ib_gibs, adjunct_ib_gib),

      # Broadcast
      {:ok, :ok} <-
        broadcast(adjunct_ib_gib, old_target_ib_gib, new_target_ib_gib),

      # Reply
      {:ok, reply_msg} <-
        get_reply_msg(adjunct_ib_gib, old_target_ib_gib, new_target_ib_gib)
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

  defp exec_impl(identity_ib_gibs, adjunct_ib_gib) do
    with(
      # Get the adjunct and target in preparation to rel8
      {:ok, {adjunct, adjunct_target_rel8n, target}} <-
        prepare(identity_ib_gibs, adjunct_ib_gib),

      {:ok, target_info} <- get_info(target),
      {:ok, target_ib_gib} <- get_ib_gib(target_info),

      # If authorized, rel8 the adjunct directly to the target
      {:ok, new_target} <-
        rel8_to_target_if_authorized(target,
                                     adjunct,
                                     adjunct_target_rel8n,
                                     identity_ib_gibs),
      {:ok, new_target_info} <- get_info(new_target),
      {:ok, new_target_ib_gib} <- get_ib_gib(new_target_info)
    ) do
      {:ok, {target_ib_gib, new_target_ib_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  # Get the adjunct and target in preparation to rel8
  defp prepare(identity_ib_gibs, adjunct_ib_gib) do
    with(
      {:ok, adjunct} <-
        IbGib.Expression.Supervisor.start_expression(adjunct_ib_gib),
      {:ok, adjunct_info} <- adjunct |> get_info(),
      adjunct_rel8n when adjunct_rel8n !== nil <-
        adjunct_info[:data]["adjunct_rel8n"],
      adjunct_target_rel8n when adjunct_target_rel8n !== nil <-
        adjunct_info[:data]["adjunct_target_rel8n"],
      {:adjunct_rel8n, true} <-
        validate_input(:adjunct_rel8n,
                       adjunct_rel8n,
                       "The adjunct_rel8n (#{adjunct_rel8n}) is invalid."),
      {:adjunct_target_rel8n, true} <-
        validate_input(:adjunct_target_rel8n,
                       adjunct_target_rel8n,
                       "The adjunct_target_rel8n (#{adjunct_target_rel8n}) is invalid.",
                       :adjunct_rel8n),
      _ <- Logger.debug("adjunct_info: #{inspect adjunct_info, pretty: true}"),
      target_ib_gib <- Enum.at(adjunct_info[:rel8ns][adjunct_rel8n], 0),

      # We can't just attach the adjunct to the target_ib_gib exactly, since it
      # may have changed. In case the branches have split, we get the temporal
      # junction point of the ibGib and get the latest from that. This will
      # ensure that we are working on a single timeline (even if it messes
      # things up a bit). I don't really know and am just groping here.
      {:ok, temp_junc_ib_gib} <- get_temporal_junction_ib_gib(target_ib_gib),

      {:ok, latest_target_ib_gib} <-
        IbGib.Common.get_latest_ib_gib(identity_ib_gibs, temp_junc_ib_gib),
      {:ok, target} <-
        IbGib.Expression.Supervisor.start_expression(latest_target_ib_gib)
    ) do
      {:ok, {adjunct, adjunct_target_rel8n, target}}
    else
      error -> default_handle_error(error)
    end
  end

  # Only relate the adjunct if they're actually authorized to rel8 on the
  # target. This is intended to be called by the target owner.
  # If not authorized, returns :error tuple.
  defp rel8_to_target_if_authorized(target,
                                    adjunct,
                                    adjunct_target_rel8n,
                                    identity_ib_gibs) do
    with(
      {:ok, target_info} <- target |> get_info(),
      # authorize if identity_ib_gibs are allowed to execute rel8 on target
      {authz_result, _} <- Authz.authorize_apply_b(:rel8, target_info[:rel8ns], identity_ib_gibs),
      {:ok, new_target} <-
        (
          if authz_result === :ok do
            _ = Logger.debug("authz is ok. allower is authorized to rel8 to the target.\nadjunct_target_rel8n: #{adjunct_target_rel8n}" |> ExChalk.yellow |> ExChalk.bg_blue)
            target |> rel8(adjunct, identity_ib_gibs, [adjunct_target_rel8n])
          else
            _ = Logger.debug("authz is NOT ok. adjuncter is NOT authorized to rel8 to the target." |> ExChalk.yellow |> ExChalk.bg_red)
            # Not authorized, so this is a user adjuncting on someone else's
            # ibGib
            {:error, "Not authorized to rel8 the adjunct to the target.\ntarget_info: #{inspect target_info}\nidentity_ib_gibs: #{inspect identity_ib_gibs}\nadjunct_target_rel8n: #{adjunct_target_rel8n}"}
          end
        )
    ) do
      {:ok, new_target}
    else
      error -> default_handle_error(error)
    end
  end

  defp broadcast(adjunct_ib_gib, old_target_ib_gib, new_target_ib_gib) do
    _ = EventChannel.broadcast_ib_gib_event(:update,
                                            {old_target_ib_gib,
                                             new_target_ib_gib})
    {:ok, :ok}
  end

  defp get_reply_msg(adjunct_ib_gib, old_target_ib_gib, new_target_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "adjunct_ib_gib" => adjunct_ib_gib,
          "old_target_ib_gib" => old_target_ib_gib,
          "new_target_ib_gib" => new_target_ib_gib,
        }
      }
    {:ok, reply_msg}
  end
end
