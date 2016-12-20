defmodule WebGib.Bus.Commanding.BatchRefresh do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  The refresh works in two aspects:
    1. Most up-to-date ibGib in its timeline, i.e. "latest".
    2. Find 1-way rel8ns to ibGibs that are not recriprocal, i.e. "adjunct".

  The "latest" is pretty straight-forward. Whenever an ibGib is mut8d or rel8d
  to another ibGib, there is a "new" one that is created for that ibGib's
  timeline. This query will get the most recent one of those according to the
  insert timestamp.

  The "adjunct" is something that I'm using for getting comments made by other
  user's. Since those users don't have authorization to make comments directly
  on a given user's ibGibs, then their comment rel8ns can only be stated 1-way -
  until the given user rel8s them on the owner's end explicitly. I'm thinking
  that the owner will either say "ok", "spam", "inappropriate", "illegal", etc.,
  in which case the direct corresponding rel8n can be created (optionally).

  This is only a temporary approach to this problem, as on down the road the
  queries will become unwieldy. This will need to be an autonomous service (yes
  I'm going back to the term that I used before hearing "micro-service", because
  it is slightly different and I have the whiteboard next to me right now).

  ---

  ## Acknowledge

  Let us acknowledge the Lord;
  &nbsp;&nbsp;let us press on to acknowledge Him.
  As surely as the sun rises,
  &nbsp;&nbsp;He will appear.
  He will come to us like the winter rains,
  &nbsp;&nbsp;like the spring rains that water the earth.

  ---

  This entire module definitely has room for optimization at scale. I am
  copy/paste coding the adjunct parts with duplicate happenings all over -
  so not very DRY at the moment.
  """

  require Logger

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import WebGib.Bus.Commanding.Helper
  use IbGib.Constants, :ib_gib

  def handle_cmd(%{"ib_gibs" => ib_gibs} = data,
                 _metadata,
                 msg,
                 %{assigns:
                   %{ib_identity_ib_gibs: identity_ib_gibs}
                 } = socket) when is_list(ib_gibs) do
    _ = Logger.debug("snarky. ib_gibs: #{ib_gibs}" |> ExChalk.blue |> ExChalk.bg_yellow)
    with(
      # Validate
      {:ib_gibs, true} <-
        validate_input(:ib_gibs, ib_gibs, "At least one invalid ibGib."),

      # Execute
      {:ok, {latest_ib_gibs, adjunct_ib_gibs}} <- exec_impl(identity_ib_gibs, ib_gibs),

      # Broadcast any newer ib_gib versions found (if any)
      {:ok, :ok} <- broadcast_if_necessary(:latest, latest_ib_gibs),

      # Broadcast any "adjunct" ib_gibs found (if any)
      {:ok, :ok} <- broadcast_if_necessary(:adjunct, adjunct_ib_gibs),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(latest_ib_gibs, adjunct_ib_gibs)
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
  def handle_cmd(_data, _metadata, msg, socket) do
    handle_cmd_error(:error, "No clause match. ib_gibs not a list?", msg, socket)
  end

  defp exec_impl(identity_ib_gibs, ib_gibs) do
    with(
      # Will use identity in possibly tight loop, so brought out here, which
      # is why...
      {:ok, identity} <-
        (identity_ib_gibs
         |> Enum.at(0)
         |> IbGib.Expression.Supervisor.start_expression()),

      # ...most of the work is done here...meh. Win some, lose some ^\_o_/^
      {:ok, latest_ib_gibs} <-
        get_latest_ib_gibs(identity_ib_gibs, identity, ib_gibs),
      {:ok, adjunct_ib_gibs} <-
        get_adjunct_ib_gibs(identity_ib_gibs, identity, ib_gibs)
    ) do
      {:ok, {latest_ib_gibs, adjunct_ib_gibs}}
    else
      error -> default_handle_error(error)
    end
  end

  # Get the entire list of latest ib_gibs, which is a map of
  # old_ib_gib => new_ib_gib (if different)
  # Returns an empty map if none are different.
  defp get_latest_ib_gibs(identity_ib_gibs, identity, ib_gibs) do
    latest_ib_gibs_or_error =
      ib_gibs
      |> Enum.uniq()
      |> Enum.reduce_while(%{}, fn(ib_gib, acc) ->
           case get_latest(identity_ib_gibs, identity, ib_gib) do
             {:ok, latest_ib_gib} when latest_ib_gib === ib_gib ->
               {:cont, acc}

             {:ok, latest_ib_gib} ->
               {:cont, Map.put(acc, ib_gib, latest_ib_gib)}

             {:error, reason} ->
               {:halt, reason}
           end
         end)

    if is_map(latest_ib_gibs_or_error) do
      # is a map of ib_gib => latest ib_gib (or empty, which is fine)
      {:ok, latest_ib_gibs_or_error}
    else
      # is an error (reason)
      {:error, latest_ib_gibs_or_error}
    end
  end

  # Gets the latest ib_gib for a single given `ib_gib`.
  # We will query off of the `query_src`, which is based on the calling user's
  # identity. However, the search itself must be using the credentials of
  # **that** ibgib's identities, i.e. in that timeline.
  defp get_latest(identity_ib_gibs, query_src, ib_gib) do
    with(
      {:ok, ib_gib_process} <-
        IbGib.Expression.Supervisor.start_expression(ib_gib),
      {:ok, ib_gib_info} <- ib_gib_process |> get_info(),
      {:ok, ib_gib_identity_ib_gibs} <-
        get_ib_gib_identity_ib_gibs(ib_gib_info),

      # Build the query options
      query_opts <-
        build_query_opts_latest(ib_gib_identity_ib_gibs, ib_gib),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <- query_src |> query(identity_ib_gibs, query_opts),

      # Return the query_result result ib^gib
      {:ok, query_result_info} <- query_result |> get_info(),
      {:ok, result_ib_gib} <-
        extract_latest_ib_gib(ib_gib, query_result_info)
    ) do
      {:ok, result_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  # Gets "adjunct" ib^gibs, meaning ib^gibs that have a 1-way rel8n with the
  # given `ib_gibs`. The `rel8ns` parameter is for determining which rel8ns to
  # look for.
  defp get_adjunct_ib_gibs(identity_ib_gibs, identity, ib_gibs) do
    adjunct_ib_gibs_or_error =
      ib_gibs
      |> Enum.uniq()
      |> Enum.reduce_while(%{}, fn(ib_gib, acc) ->
           case get_adjuncts(identity_ib_gibs, identity, ib_gib) do
            # Adjunct_ib_gibs should be a list of ib^gibs or nil if none found.
             {:ok, nil} ->
               {:cont, acc}

             {:ok, adjunct_ib_gibs} ->
               {:cont, Map.put(acc, ib_gib, adjunct_ib_gibs)}

             {:error, reason} ->
               {:halt, reason}
           end
         end)

    if is_map(adjunct_ib_gibs_or_error) do
      # is a map of ib_gib => adjunct ib_gib (or empty, which is fine)
      {:ok, adjunct_ib_gibs_or_error}
    else
      # is an error (reason)
      {:error, adjunct_ib_gibs_or_error}
    end
  end

  defp get_adjuncts(identity_ib_gibs, query_src, ib_gib) do
    with(
      {:ok, ib_gib_process} <-
        IbGib.Expression.Supervisor.start_expression(ib_gib),
      {:ok, ib_gib_info} <- ib_gib_process |> get_info(),
      {:ok, ib_gib_identity_ib_gibs} <-
        get_ib_gib_identity_ib_gibs(ib_gib_info),
      {:ok, temporal_junction_ib_gib} <- get_temporal_junction(ib_gib_info),

      # Build the query options
      query_opts <- build_query_opts_adjunct(temporal_junction_ib_gib),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <- query_src |> query(identity_ib_gibs, query_opts),

      # Return the query_result result (non-root) ib^gibs, if any
      # Returns {:ok, nil} if none found
      {:ok, query_result_info} <- query_result |> get_info(),
      {:ok, adjunct_ib_gibs} <- extract_adjunct_ib_gibs(query_result_info)
    ) do
      {:ok, adjunct_ib_gibs}
    else
      error -> default_handle_error(error)
    end
  end

  defp get_ib_gib_identity_ib_gibs(ib_gib_info) do
    _ = Logger.debug("ib_gib_info:\n#{inspect ib_gib_info}" |> ExChalk.magenta)
    rel8ns = ib_gib_info[:rel8ns]
    _ = Logger.debug("rel8ns:\n#{inspect rel8ns}" |> ExChalk.magenta)
    identities = rel8ns["identity"]
    _ = Logger.debug("identities:\n#{inspect identities}" |> ExChalk.magenta)
    {:ok, identities}
  end

  defp build_query_opts_latest(identity_ib_gibs, ib_gib) do
    non_root_identities = Enum.filter(identity_ib_gibs, &(&1 != @root_ib_gib))

    do_query()
    |> where_rel8ns("identity", "withany", "ibgib", non_root_identities)
    |> where_rel8ns("past", "withany", "ibgib", [ib_gib])
    |> most_recent_only()
  end

  defp build_query_opts_adjunct(temporal_junction_ib_gib) do
    do_query()
    |> where_rel8ns("adjunct_to", "with", "ibgib", temporal_junction_ib_gib)
  end

  defp extract_latest_ib_gib(src_ib_gib, query_result_info) do
    result_data = query_result_info[:rel8ns]["result"]
    result_count = Enum.count(result_data)
    case result_count do
      1 ->
        # Not found (1 result is root), so the "latest" is the one that we're
        # search off of (has no past)
        {:ok, src_ib_gib}

      2 ->
        # First is always root, so get second
        {:ok, Enum.at(result_data, 1)}

      _ ->
        _ = Logger.error "unknown result count: #{result_count}"
        {:ok, @root_ib_gib}
    end
  end

  defp extract_adjunct_ib_gibs(query_result_info) do
    result_data = query_result_info[:rel8ns]["result"]
    result_count = Enum.count(result_data)
    case result_count do
      0 ->
        # 0 results is unexpected. Should at least return the root (1 result)
        _ = Logger.error "unknown result count: #{result_count}"
        {:ok, nil}

      1 ->
        # Not found (1 result is root)
        {:ok, nil}

      _ ->
        # At least one non-root result found
        [_root, adjunct_ib_gibs] = result_data
        {:ok, adjunct_ib_gibs}
    end
  end

  defp broadcast_if_necessary(:latest, latest_ib_gibs)
    when is_map(latest_ib_gibs) and map_size(latest_ib_gibs) > 0 do
    # Broadcast any newer ib_gib versions found (if any)
    Enum.each(latest_ib_gibs, fn({old_ib_gib, latest_ib_gib}) ->
      _ = EventChannel.broadcast_ib_gib_update(old_ib_gib, latest_ib_gib)
    end)
    {:ok, :ok}
  end
  defp broadcast_if_necessary(:latest, _latest_ib_gibs) do
    # nothing is newer, so nothing to broadcast
    {:ok, :ok}
  end
  defp broadcast_if_necessary(:adjunct, adjunct_ib_gibs)
    when is_map(adjunct_ib_gibs) and map_size(adjunct_ib_gibs) > 0 do
    # In the form of %{"ib^gib1" => %{"rel8n1" => ["adjunct^1", "adjunct^2"]}}

    # Enum.each(adjunct_ib_gibs, fn({ib_gib, adjunct_rel8ns}) ->
    #
    #
    #   impl this here thing yo
    #   _ = EventChannel.broadcast_ib_gib_implications(ib_gib, adjunct_rel8ns)
    # end)
    {:ok, :ok}
  end
  defp broadcast_if_necessary(:adjunct, _adjunct_ib_gibs) do
    # no adjunct ib^gibs, so nothing to broadcast
    {:ok, :ok}
  end

  defp get_reply_msg(latest_ib_gibs, adjunct_ib_gibs) do
    # If there aren't any adjunct ib_gibs, then nil it. (null on js side) f***!
    adjunct_ib_gibs =
      if map_size(adjunct_ib_gibs) > 0, do: adjunct_ib_gibs, else: nil

    reply_msg =
      %{
        "data" => %{
          "latest_ib_gibs" => latest_ib_gibs,
          "adjunct_ib_gibs" => adjunct_ib_gibs
        }
      }
    {:ok, reply_msg}
  end
end
