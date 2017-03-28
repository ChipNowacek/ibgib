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
        validate_input(:rel8n_name, rel8n_name, "Invalid rel8n_name"),

      # Execute
      {:ok, {parent_temp_junc_ib_gib, new_parent_ib_gib}} <-
        exec_impl(identity_ib_gibs, parent_ib_gib, child_ib_gib, rel8n_name),

      # Broadcast
      {:ok, :ok} <-
        broadcast(parent_ib_gib, new_parent_ib_gib),

      # Reply
      {:ok, reply_msg} <-
        get_reply_msg(parent_temp_junc_ib_gib, parent_ib_gib, new_parent_ib_gib)
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
        
      # This will remove the "appropriate" rel8nships, depending on rel8n_name,
      #   and add those ib_gib to the "trash" rel8n.
      {:ok, parent_ib_gib} <- 
        trash_rel8nships(rel8nships, 
                         rel8n_name, 
                         identity_ib_gibs, 
                         {parent_ib_gib, parent, parent_info}, 
                         parent_temp_junc_ib_gib,
                         {child_ib_gib, child, child_info})
    ) do
      {:ok, {parent_temp_junc_ib_gib, parent_ib_gib}}
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
      {:ok, latest_child_info} <- latest_child |> get_info()
    ) do
      {:ok, {{latest_parent_ib_gib, latest_parent, latest_parent_info}, 
             parent_temp_junc_ib_gib, 
             {latest_child_ib_gib, latest_child, latest_child_info}}}
    else
      error -> default_handle_error(error)
    end
  end

  defp trash_rel8nships(rel8nships, 
                        rel8n_name, 
                        identity_ib_gibs, 
                        parent_stuff, 
                        parent_temp_junc_ib_gib,
                        child_stuff) 
  defp trash_rel8nships(rel8nships, 
                        _rel8n_name, 
                        identity_ib_gibs, 
                        {_parent_ib_gib, parent, parent_info}, 
                        parent_temp_junc_ib_gib,
                        {_child_ib_gib, child, child_info}) 
    when map_size(rel8nships) === 0 do
    # rel8nships is empty, so we have nothing to unrel8
    # We need to ensure that the child is actually an adjunct to the parent.
    # Once ensured, we will put the child_ib_gib in the parent's "trash" rel8n.
    with(
      {:ok, :ok} <- ensure_is_adjunct(parent_temp_junc_ib_gib, child_info),
      {:ok, parent} <- parent |> rel8(child, identity_ib_gibs, ["trash"]),
      {:ok, parent_info} <- parent |> get_info(),
      {:ok, parent_ib_gib} <- get_ib_gib(parent_info)
    ) do 
      {:ok, parent_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end
  defp trash_rel8nships(rel8nships, 
                        rel8n_name, 
                        identity_ib_gibs, 
                        {parent_ib_gib, parent, parent_info}, 
                        parent_temp_junc_ib_gib,
                        {child_ib_gib, child, child_info}) 
    when rel8n_name == @root_ib_gib or map_size(rel8nships) === 1 do
    # rel8n_name is ib^gib (or it's only one rel8nship), 
    #   so unrel8 **all** rel8nships.
    #   But right now, rel8nships is mapped by rel8n_name keys. 
    # We actually _want_ it by child_ib_gib keys so we can unrel8/rel8 each one
    #   in a single pass. So we invert the map first. 
    #   See IbGib.Helper.invert_flat_map/1
    _ = Logger.debug("rel8nships: #{inspect rel8nships}" |> ExChalk.bg_green |> ExChalk.blue)
    with(
      new_parent when new_parent != nil <-
        rel8nships
        |> invert_flat_map()
        |> Enum.reduce_while(parent, fn({ib_gib, rel8n_names}, acc) ->
             # unrel8 via -rel8n, and rel8 to "trash"
               if rel8n_names === ["trash"] do
                 {:halt, nil}
                #  {:cont, acc}
               else 
                 rel8ns = (rel8n_names |> Enum.map(&("-" <> &1))) ++ ["trash"]
                 _ = Logger.debug("rel8ns: #{inspect rel8ns}" |> ExChalk.bg_green |> ExChalk.blue)
                 {result_tag, result} = exec_unrel8_rel8(identity_ib_gibs, parent, ib_gib, rel8ns)
                 if result_tag === :ok do
                   {:cont, result}
                 else
                   {:halt, nil}
                 end
               end
           end),
      {:ok, new_parent_info} <- new_parent |> get_info(),
      {:ok, new_parent_ib_gib} <- get_ib_gib(new_parent_info)
    ) do
      {:ok, new_parent_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end
  defp trash_rel8nships(rel8nships, 
                        rel8n_name, 
                        identity_ib_gibs, 
                        {parent_ib_gib, parent, parent_info}, 
                        parent_temp_junc_ib_gib,
                        {child_ib_gib, child, child_info}) 
    when map_size(rel8nships) === 2 do
    # We've specified a non-ib^gib rel8n_name and know there are 2 rel8nships.
    # If the other rel8nship is ib^gib, then we're going to remove all
    #   rel8nships via calling this recursively but with rel8n_name === ib^gib.
    # Else we'll cull rel8nships to only this rel8n and call recursively with 
    #   with the modified rel8nships where map_size will === 1.
    other_rel8n_name = 
      rel8nships 
      |> Map.keys 
      |> Enum.filter(&(&1 != rel8n_name)) 
      |> Enum.at(0)
      
    if other_rel8n_name === @root_ib_gib do
      trash_rel8nships(rel8nships,
                       @root_ib_gib, 
                       identity_ib_gibs, 
                       {parent_ib_gib, parent, parent_info}, 
                       parent_temp_junc_ib_gib,
                       {child_ib_gib, child, child_info})
    else
      only_rel8n_name_map = 
        rel8nships 
        |> Enum.filter(fn({k,v}) -> k === rel8n_name end) 
        |> Enum.into(%{})
      if map_size(only_rel8n_name_map) === 1 do
        trash_rel8nships(only_rel8n_name_map,
                         rel8n_name,
                         identity_ib_gibs,
                         {parent_ib_gib, parent, parent_info},
                         parent_temp_junc_ib_gib,
                         {child_ib_gib, child, child_info})
      else
        # This should NOT happen. I'm only putting it here juuuuust in case.
        emsg = "trash_rel8nships problem mapping to the given rel8n_name (#{rel8n_name}). What up wit dat?"
        _ = Logger.error(emsg)
        {:error, emsg}
      end
    end
  end
  defp trash_rel8nships(rel8nships, 
                        rel8n_name, 
                        identity_ib_gibs, 
                        {parent_ib_gib, parent, parent_info}, 
                        parent_temp_junc_ib_gib,
                        {child_ib_gib, child, child_info}) do
    # We've specified a non-ib^gib rel8n_name and know there are more than 2
    # So we'll cull rel8nships to only this rel8n and call recursively with 
    #   with the modified rel8nships where map_size will === 1.
    only_rel8n_name_map = 
      rel8nships 
      |> Enum.filter(fn({k,v}) -> k === rel8n_name end) 
      |> Enum.into(%{})
    if map_size(only_rel8n_name_map) === 1 do
      trash_rel8nships(only_rel8n_name_map,
                       rel8n_name,
                       identity_ib_gibs,
                       {parent_ib_gib, parent, parent_info},
                       parent_temp_junc_ib_gib,
                       {child_ib_gib, child, child_info})
    else
      # This should NOT happen. I'm only putting it here juuuuust in case.
      emsg = "trash_rel8nships problem mapping to the given rel8n_name (#{rel8n_name}). What up wit dat?"
      _ = Logger.error(emsg)
      {:error, emsg}
    end
  end
  
  defp exec_unrel8_rel8(identity_ib_gibs, parent, child_ib_gib, rel8ns) do
    with(
      {:ok, child} <-
        IbGib.Expression.Supervisor.start_expression(child_ib_gib),
      {:ok, new_parent} <- 
        parent |> rel8(child, identity_ib_gibs, rel8ns)
    ) do
      {:ok, new_parent}
    else
      error -> 
        _ = Logger.error(inspect error)
        error
    end
  end
  
  # For now, this just checks to see if the child's rel8ns includes an 
  # "adjunct_to" rel8n that includes the parent_temp_junc_ib_gib. 
  defp ensure_is_adjunct(parent_temp_junc_ib_gib, child_info) do
    if child_info[:rel8ns]["adjunct_to"] != nil and 
       Enum.member?(child_info[:rel8ns]["adjunct_to"], parent_temp_junc_ib_gib) do
      {:ok, :ok}
    else
      {:error, "The child is not an adjunct to the parent. There is no rel8n named \"adjunct_to\" that contains the parent_temp_junc_ib_gib: #{parent_temp_junc_ib_gib}"}
    end
  end

  defp broadcast(old_parent_ib_gib, new_parent_ib_gib) do
    
    _ = EventChannel.broadcast_ib_gib_event(:update,
                                            {old_parent_ib_gib,
                                             new_parent_ib_gib})
    {:ok, :ok}
  end

  defp get_reply_msg(parent_temp_junc_ib_gib, 
                     old_parent_ib_gib, 
                     new_parent_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "parent_temp_junc_ib_gib" => parent_temp_junc_ib_gib,
          "old_parent_ib_gib" => old_parent_ib_gib,
          "new_parent_ib_gib" => new_parent_ib_gib
        }
      }
    {:ok, reply_msg}
  end
end
