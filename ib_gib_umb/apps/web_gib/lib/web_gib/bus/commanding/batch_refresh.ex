defmodule WebGib.Bus.Commanding.BatchRefresh do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  Whenever an ibGib is mut8d or rel8d to another ibGib, there is a "new"
  one that is created for that ibGib's timeline. This query will get the
  most recent one of those according to the insert timestamp.

  ---

  ## Perseverance

  But the seed on good soil stands for those  
  &nbsp;&nbsp; with a noble and good heart,  
  &nbsp;&nbsp; who hear the word,  
  &nbsp;&nbsp; retain it,  
  &nbsp;&nbsp; and by perseverance produce a crop.
  """

  import Expat # https://github.com/vic/expat
  require Logger

  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib
  use WebGib.Constants, :config
  use WebGib.Constants, :keys

  def handle_cmd(ib_gibs_(...) = data,
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
      {:ok, latest_ib_gibs} <- exec_impl(identity_ib_gibs, ib_gibs),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(latest_ib_gibs),
      _ <- Logger.debug("reply_msg yah: #{inspect reply_msg}" |> ExChalk.bg_blue |> ExChalk.white)
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
      {:ok, identity} <-
        (identity_ib_gibs
         |> Enum.reverse
         |> Enum.at(0)
         |> IbGib.Expression.Supervisor.start_expression()),

      {:ok, latest_ib_gibs} <-
        get_latest_ib_gibs(identity_ib_gibs, identity, ib_gibs)
    ) do
      {:ok, latest_ib_gibs}
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
    {:ok, latest_ib_gib_or_nil} <- try_get_cached_latest_ib_gib(ib_gib),
    {:ok, latest_ib_gib} <- 
      (if latest_ib_gib_or_nil === nil do
         query_latest(identity_ib_gibs, query_src, ib_gib)
       else
         {:ok, latest_ib_gib_or_nil}
       end)
    ) do
      _ = Logger.debug("fizzbomb latest_ib_gib: #{latest_ib_gib}")
      {:ok, latest_ib_gib}
    else
      error -> 
        _ = Logger.error("Error get_latest: #{inspect error}")
        default_handle_error(error)
    end
  end
  

  defp try_get_cached_latest_ib_gib(ib_gib) do
    with(
      key <- @query_cache_prefix_key <> ib_gib,
      {:ok, %{latest: latest_ib_gib, timestamp: timestamp_ms}} <- IbGib.Data.Cache.get(key),
      # _ = Logger.debug("Fizzley latest_ib_gib: #{latest_ib_gib}\ntimestamp_ms: #{timestamp_ms}" |> ExChalk.bg_green |> ExChalk.blue),
      now <- :erlang.system_time(:milli_seconds),
      latest_ib_gib <- 
        (if now - (timestamp_ms || 0) < @query_cache_expiry_ms do
          _ = Logger.debug("Using cached query. fizzdoodle latest_ib_gib: #{latest_ib_gib}" |> ExChalk.bg_green |> ExChalk.blue)
          latest_ib_gib
         else
           _ = Logger.debug("Cached query expired. Doing new query." |> ExChalk.bg_green |> ExChalk.blue)
           _ = IbGib.Data.Cache.delete(key)
           nil
         end)
    ) do
      {:ok, latest_ib_gib}
    else
      _not_found -> {:ok, nil}
    end
  end
  
  defp query_latest(identity_ib_gibs, query_src, ib_gib) do
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
        extract_latest_ib_gib(ib_gib, query_result_info),
        
      # Store in cache with timestamp
      key <- @query_cache_prefix_key <> ib_gib,
      now <- :erlang.system_time(:milli_seconds),
      
      IbGib.Data.Cache.put(key, %{latest: result_ib_gib, timestamp: now})
    ) do
      {:ok, result_ib_gib}
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

  defp get_reply_msg(latest_ib_gibs) do
    latest_ib_gibs =
      if map_size(latest_ib_gibs) > 0, do: latest_ib_gibs, else: nil

    reply_msg =
      %{
        "data" => %{
          "latest_ib_gibs" => latest_ib_gibs
        }
      }

    _ = Logger.debug("reply_msg zizzoo: #{inspect reply_msg}" |> ExChalk.bg_blue |> ExChalk.white |> ExChalk.italic)
    {:ok, reply_msg}
  end
end
