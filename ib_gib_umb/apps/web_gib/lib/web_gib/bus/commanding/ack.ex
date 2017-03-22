defmodule WebGib.Bus.Commanding.Ack do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  Ack is how to acknowledge an adjunct ibGib, allowing it to be rel8d to the
  user's own ibGib. So if user A has ibGib a, and user B makes comment b on it,
  then it will be an adjunct and will *not* be automatically rel8d to a 
  (ATOW 2017/03/21 This is true now, but in the future there is the possibility
  of an "auto-ack" preference). If user A acks b, then we will rel8 b
  **directly** to a via the rel8n specified in the adjunct. 
  
  The user will also have other options, currently the only one being to
  "trash" the adjunct.
  """

  import OK, only: ["~>>": 2]
  require Logger

  alias IbGib.Auth.Authz
  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  alias WebGib.Oy
  import IbGib.{Expression, Helper}
  import IbGib.Macros, only: [handle_ok_error: 2]
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
    OK.with do
      # Validate
      true <- validate_input({:ok, :adjunct_ib_gib}, 
                             adjunct_ib_gib, 
                             "Invalid adjunct ibGib", 
                             :ib_gib)
      true <- validate_input({:ok, :adjunct_ib_gib},
                              {:simple, adjunct_ib_gib != @root_ib_gib},
                              "The root ib not an adjunct ibGib.")

      # Execute
      {old_target_ib_gib, new_target_ib_gib} <-
        exec_impl(identity_ib_gibs, adjunct_ib_gib)

      # update oy
      _ = Oy.update_oy(identity_ib_gibs, 
                        :adjunct, 
                        %{"action" => "ack", 
                          "adjunct_ib_gib" => adjunct_ib_gib})

      # Broadcast
      _ = broadcast(adjunct_ib_gib, old_target_ib_gib, new_target_ib_gib)

      # Reply
      reply_msg <-
        get_reply_msg(adjunct_ib_gib, old_target_ib_gib, new_target_ib_gib)

      OK.success reply_msg
    else
      reason -> handle_cmd_error(:error, reason, msg, socket)
    end
  end

  defp exec_impl(identity_ib_gibs, adjunct_ib_gib) do
    OK.with do
      # Get the adjunct and target in preparation to rel8
      {adjunct, adjunct_target_rel8n, target} <-
        prepare(identity_ib_gibs, adjunct_ib_gib)

      target_ib_gib <- 
        {:ok, target}
        ~>> get_info()
        ~>> get_ib_gib()

      # If authorized, rel8 the adjunct directly to the target
      new_target_ib_gib <-
        {:ok, target}
        ~>> rel8_to_target_if_authorized(adjunct,
                                         adjunct_target_rel8n,
                                         identity_ib_gibs)
        ~>> get_info()
        ~>> get_ib_gib()
      
      OK.success {target_ib_gib, new_target_ib_gib}
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
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
    OK.with do
      target_info <- target |> get_info()
      # authorize if identity_ib_gibs are allowed to execute rel8 on target
      {authz_result, _} = 
        Authz.authorize_apply_b(:rel8, target_info[:rel8ns], identity_ib_gibs)
        
      new_target <-
        if authz_result === :ok do
          _ = Logger.debug("authz is ok. allower is authorized to rel8 to the target.\nadjunct_target_rel8n: #{adjunct_target_rel8n}" |> ExChalk.yellow |> ExChalk.bg_blue)
          target |> rel8(adjunct, identity_ib_gibs, [adjunct_target_rel8n])
        else
          _ = Logger.debug("authz is NOT ok. adjuncter is NOT authorized to rel8 to the target." |> ExChalk.yellow |> ExChalk.bg_red)
          # Not authorized, so this is a user adjuncting on someone else's
          # ibGib
          {:error, "Not authorized to rel8 the adjunct to the target.\ntarget_info: #{inspect target_info}\nidentity_ib_gibs: #{inspect identity_ib_gibs}\nadjunct_target_rel8n: #{adjunct_target_rel8n}"}
        end
      
      OK.success new_target
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
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
