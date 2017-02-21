defmodule WebGib.Bus.Commanding.Trash do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)
  """

  import Expat # https://github.com/vic/expat
  require Logger

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  alias IbGib.Auth.Authz
  import IbGib.{Expression, Helper}
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib

  defpat trash_cmd_data_(%{
    "parent_ib_gib" => parent_ib_gib,
    "child_ib_gib" => child_ib_gib,
    "rel8n_name" => rel8n_name
  })

  def handle_cmd(trash_cmd_data_(...) = data,
                 _metadata,
                 msg,
                 %{assigns:
                   %{ib_identity_ib_gibs: identity_ib_gibs}
                 } = socket) do
    _ = Logger.debug("zinnkers. parent_ib_gib: #{parent_ib_gib}\nchild_ib_gib: #{child_ib_gib}\nrel8n_name: #{rel8n_name}" |> ExChalk.blue |> ExChalk.bg_white)
    with(
      # Validate
      {:parent_ib_gib, true} <-
        validate_input(:parent_ib_gib, parent_ib_gib, "Invalid parent ibGib", :ib_gib),
      {:parent_ib_gib, true} <-
        validate_input(:parent_ib_gib,
                       {:simple, parent_ib_gib != @root_ib_gib},
                       "The parent cannot be the root."),
      {:child_ib_gib, true} <-
        validate_input(:child_ib_gib, child_ib_gib, "Invalid child ibGib", :ib_gib),
      {:child_ib_gib, true} <-
        validate_input(:child_ib_gib,
                       {:simple, child_ib_gib != @root_ib_gib},
                       "The child cannot be the root"),
      {:rel8n_name, true} <-
        validate_input(:rel8n_name, rel8n_name, "Invalid parent rel8n_name"),

      # Execute
      {:ok, {parent_ib_gib_temp_junc, new_parent_ib_gib}} <-
        exec_impl(identity_ib_gibs, parent_ib_gib, child_ib_gib, rel8n_name),

      # Broadcast
      {:ok, :ok} <-
        broadcast(parent_ib_gib_temp_junc, new_parent_ib_gib),

      # Reply
      {:ok, reply_msg} <-
        get_reply_msg(adjunct_ib_gib, old_target_ib_gib, new_target_ib_gib)
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

  defp exec_impl(identity_ib_gibs, parent_ib_gib, child_ib_gib, rel8n_name) do
    with(
      # Get the latest parent and latest child in preparation to rel8/unrel8.
      # We'll be updating the parent throughout this function.
      {:ok, {{parent_ib_gib, parent, parent_info}, 
             parent_temp_junc_ib_gib, 
             {child_ib_gib, child, child_info}}} <-
        prepare(identity_ib_gibs, parent_ib_gib, child_ib_gib),

      # Is the user authorized to to rel8 to/unrel8 from the parent?
      {:ok, _} <- 
        Authz.authorize_apply_b(:rel8, parent_info[:rel8ns], identity_ib_gibs),

      # We're going to handle it differently, depending on if the child is
      # directly rel8d or an adjunct. (If neither, then it's an {:error, _}.)
      {:ok, rel8nships} <-
        get_direct_rel8nships(:a_now_b_anytime, parent_info, child_info),
        
      # If it's directly rel8d, then we're going to unrel8 first
      {:ok, {parent_ib_gib, parent, parent_info}} <- 
        unrel8_from_parent(rel8nships, 
                           rel8n_name, 
                           identity_ib_gibs, 
                           {parent_ib_gib, parent, parent_info}, 
                           {child_ib_gib, child, child_info})
      
      {:ok, new_parent_ib_gib} <-
        
      
      # Unrel8 via the rel8n_name
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

  defp prepare(identity_ib_gibs, parent_ib_gib, child_ib_gib) do
    with(
      # Deal with the latest: get a process, info, and temp junc
      {:ok, latest_parent_ib_gib} <-
        IbGib.Common.get_latest_ib_gib(identity_ib_gibs, parent_ib_gib),
      {:ok, latest_parent} <-
        IbGib.Expression.Supervisor.start_expression(latest_parent_ib_gib),
      {:ok, latest_parent_info} <- latest_parent |> get_info(),
      {:ok, parent_temp_junc_ib_gib} <-
        get_temporal_junction_ib_gib(latest_parent_info),
      
      # Child process pid
      {:ok, latest_child_ib_gib} <-
        IbGib.Common.get_latest_ib_gib(identity_ib_gibs, child_ib_gib),
      {:ok, latest_child} <-
        IbGib.Expression.Supervisor.start_expression(latest_child_ib_gib),
      {:ok, latest_child_info} <- latest_child |> get_info(),
    ) do
      {:ok, {{latest_parent_ib_gib, latest_parent, latest_parent_info}, 
             parent_temp_junc_ib_gib, 
             {latest_child_ib_gib, latest_child, latest_child_info}}}
    else
      error -> default_handle_error(error)
    end
  end

  defp directly_rel8d?(a_info, b_info) do
    with(
      {:ok, rel8nships} <-
        get_direct_rel8nships(:a_now_b_anytime, latest_parent_info, child_info)
      directly_rel8d? <- map_size(rel8nships) > 0,
    ) do
      {:ok, directly_rel8d?}
    else
      error -> default_handle_error(error)
    end
  end
  
  defp child_is_adjunct?(latest_parent_info, 
                         parent_temp_junc_ib_gib, 
                         child, 
                         child_ib_gib) do
    with(
      {:ok, rel8n_names} <-
        get_rel8nships(latest_parent_info[:rel8ns], child_ib_gib),
      directly_rel8d? <- rel8n_names !== [],
      
      
        
      {:ok, child_info} <- child |> get_info(),
        
      is_adjunct? <- 
    ) do
      {:ok, is_adjunct?}
    else
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
    # _ = EventChannel.broadcast_ib_gib_event(:adjunct_rel8d,
    #                                         {adjunct_ib_gib,
    #                                          old_target_ib_gib,
    #                                          new_target_ib_gib})

    _ = EventChannel.broadcast_ib_gib_event(:update,
                                            {old_target_ib_gib,
                                             new_target_ib_gib})
    {:ok, :ok}
    # def broadcast_ib_gib_event(:update = msg_type,
    #                            {old_ib_gib, new_ib_gib} = msg_info) do
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
