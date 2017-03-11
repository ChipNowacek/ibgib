defmodule WebGib.Bus.Commanding.GetOys do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  Gets the oys for the current user.
  
  Oys are similar (but not equivalent) to events and notifications. They are 
  basically a subset of events that are to be brought to the user's attention.
  Ok, basically they're notifications, but that's a really long word.

  ---

  ## Patience

  Or do you show contempt 
  &nbsp;&nbsp;for the riches of his kindness, forbearance and patience,
  &nbsp;&nbsp;not realizing that God's kindness is intended
  &nbsp;&nbsp;to lead you to repentance.
  """

  require Logger
  require OK

  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib

  @doc """
  Handles the command for getting oy(!)s. See module doc for more info `WebGib.Bus.Commanding.GetOys`.
  """
  def handle_cmd(_data,
                 _metadata,
                 msg,
                 assigns_identity_ib_gibs_(...) = socket) do
    OK.with do
      _ = Logger.debug("oyyy" |> ExChalk.blue |> ExChalk.bg_yellow)
      # No validation ATOW (2017/03/08) for this command

      # Execute
      oy_ib_gibs <- exec_impl(identity_ib_gibs)

      # Reply
      reply_msg <- get_reply_msg(query_result_ib_gib, oy_ib_gibs)
      _ <- Logger.debug("reply_msg oyyo: #{inspect reply_msg}" |> ExChalk.bg_blue |> ExChalk.white)
      
      OK.success reply_msg
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def handle_cmd(_data, _metadata, msg, socket) do
    handle_cmd_error(:error, "No clause match.", msg, socket)
  end

  defp exec_impl(identity_ib_gibs) do
    with(
      # Get the adjunct and target in preparation to rel8
      {query_identity_ib_gibs, query_identity} <-
        prepare(identity_ib_gibs)

      oy_ib_gibs <- 
        get_oy_ib_gibs(identity_ib_gibs, query_identity_ib_gibs, query_identity)

      {:ok, adjunct_ib_gibs} <-
        get_adjunct_ib_gibs(identity_ib_gibs, identity, ib_gibs)
    ) do
      {:ok, adjunct_ib_gibs}
    else
      error -> default_handle_error(error)
    end
  end
  
  defp prepare(identity_ib_gibs) do
    OK.with do
      # non-root, non-node identity ib_gibs
      query_identity_ib_gibs <-
        Common.get_identities_for_query(identity_ib_gibs)
      query_identity_ib_gib = 
        query_identity_ib_gibs |> Enum.reverse() |> Enum.at(0)
      query_identity <-
        IbGib.Expression.Supervisor.start_expression(query_identity_ib_gib)
      OK.success {query_identity_ib_gibs, query_identity}
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  
  # lots of queries and identity vars here:
  #   query_identity - identity process that we're using to exec the query
  #   identity_ib_gibs - identities for the execution of the query and 
  #     which will be associated to the query and query_result ibGibs.
  #   query_identity_ib_gibs - identities used to search against, i.e. 
  #     where identity in [query_identity_ib_gibs] (pseudo code)
  defp get_oy_ib_gibs(identity_ib_gibs, 
                      query_identity_ib_gibs, 
                      query_identity) do
    OK.with do
      # Build the query options
      query_opts <- build_query_opts(identity_ib_gibs, query_identity_ib_gibs)

      # Execute the query itself, which creates the query_result ib_gib
      query_result <- query_identity |> query(identity_ib_gibs, query_opts),

      # Return the query_result result (non-root) ib^gibs, if any
      # Returns {:ok, nil} if none found
      {:ok, query_result_info} <- query_result |> get_info(),
      _ <- Logger.debug("query_result_info: #{inspect query_result_info}" |> ExChalk.bg_blue |> ExChalk.white),
      {:ok, adjunct_ib_gibs} <- extract_adjunct_ib_gibs(query_result_info)

      # Run the query
      query_result <- contact(query_identity, query)
      query_result_ib_gib <- query_result |> get_info() ~>> get_ib_gib()
      
      OK.success query_result_ib_gib
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end

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
               _ = Logger.debug("wookie adjunct_ib_gibs: #{inspect adjunct_ib_gibs}" |> ExChalk.bg_blue |> ExChalk.white)
               {:cont, Map.put(acc, ib_gib, adjunct_ib_gibs)}

             {:error, reason} ->
               {:halt, reason}
           end
         end)

    if is_map(adjunct_ib_gibs_or_error) do
      # is a map of ib_gib => adjunct ib_gib (or empty, which is fine)
      _ = Logger.debug("adjunct_ib_gibs_or_error: #{inspect adjunct_ib_gibs_or_error, pretty: true}" |> ExChalk.bg_blue |> ExChalk.white |> ExChalk.italic)
      {:ok, adjunct_ib_gibs_or_error}
    else
      # is an error (reason)
      {:error, adjunct_ib_gibs_or_error}
    end
  end

  defp get_adjuncts(identity_ib_gibs, query_src, ib_gib) do
    with(
      # Need to get the latest ib_gib in order to ensure that we get the 
      # proper temporal junction point.
      {:ok, latest_ib_gib} <-
        IbGib.Common.get_latest_ib_gib(identity_ib_gibs, ib_gib),

      # Get the temporal junction for the **latest** ib_gib
      {:ok, latest_ib_gib_process} <-
        IbGib.Expression.Supervisor.start_expression(latest_ib_gib),
      {:ok, latest_ib_gib_info} <- latest_ib_gib_process |> get_info(),
      _ <- Logger.debug("latest_ib_gib_info yoyo: #{inspect latest_ib_gib_info, pretty: true}" |> ExChalk.bg_green |> ExChalk.blue),
      {:ok, temporal_junction_ib_gib} when temporal_junction_ib_gib !== nil <-
        get_temporal_junction_ib_gib(latest_ib_gib_info),

      # Build the query options
      query_opts <- build_query_opts_adjunct(temporal_junction_ib_gib),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <- query_src |> query(identity_ib_gibs, query_opts),

      # Return the query_result result (non-root) ib^gibs, if any
      # Returns {:ok, nil} if none found
      {:ok, query_result_info} <- query_result |> get_info(),
      _ <- Logger.debug("query_result_info: #{inspect query_result_info}" |> ExChalk.bg_blue |> ExChalk.white),
      {:ok, adjunct_ib_gibs} <- extract_adjunct_ib_gibs(query_result_info)
    ) do
      {:ok, adjunct_ib_gibs}
    else
      error -> default_handle_error(error)
    end
  end

  defp build_query_opts(query_identity_ib_gibs) do
    do_query()
    |> where_rel8ns("ancestor", "with", "ibgib", "oy#{@delim}gib")
    |> where_rel8ns("identity", "withany", "ibgib", query_identity_ib_gibs)
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
        [_root | adjunct_ib_gibs] = result_data
        _ = Logger.debug("lookie2 adjunct_ib_gibs: #{inspect adjunct_ib_gibs}" |> ExChalk.bg_blue |> ExChalk.white)
        {:ok, adjunct_ib_gibs}
    end
  end

  defp get_reply_msg(adjunct_ib_gibs) do
    adjunct_ib_gibs =
      if map_size(adjunct_ib_gibs) > 0, do: adjunct_ib_gibs, else: nil

    reply_msg =
      %{
        "data" => %{
          "adjunct_ib_gibs" => adjunct_ib_gibs
        }
      }

    _ = Logger.debug("reply_msg huh: #{inspect reply_msg}" |> ExChalk.bg_blue |> ExChalk.white |> ExChalk.italic)
    {:ok, reply_msg}
  end
end
