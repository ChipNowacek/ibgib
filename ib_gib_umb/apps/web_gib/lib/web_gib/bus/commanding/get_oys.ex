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

  import OK, only: ["~>>": 2]
  require Logger

  alias IbGib.Common
  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import IbGib.Macros, only: [handle_ok_error: 2]
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  @doc """
  Handles the command for getting oy(!)s. See module doc for more info `WebGib.Bus.Commanding.GetOys`.
  """
  def handle_cmd(_data,
                 _metadata,
                 msg,
                 assigns_identity_ib_gibs_(...) = _socket) do
    OK.with do
      _ = Logger.debug("oyyy" |> ExChalk.blue |> ExChalk.bg_yellow)
      # No validation ATOW (2017/03/08) for this command

      # Execute
      oy_ib_gibs <- exec_impl(identity_ib_gibs)

      # Reply
      reply_msg <- get_reply_msg(oy_ib_gibs)
      _ = Logger.debug("reply_msg oyyo: #{inspect reply_msg}" |> ExChalk.bg_blue |> ExChalk.white)
      
      OK.success reply_msg
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def handle_cmd(_data, _metadata, msg, socket) do
    handle_cmd_error(:error, "No clause match.", msg, socket)
  end

  defp exec_impl(identity_ib_gibs) do
    OK.with do
      {query_identity_ib_gibs, query_identity} <-
        prepare(identity_ib_gibs)

      oy_ib_gibs <- 
        get_oy_ib_gibs(identity_ib_gibs, query_identity_ib_gibs, query_identity)

      OK.success oy_ib_gibs
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
      query_opts <- build_query_opts(query_identity_ib_gibs)

      # Execute the query itself, which creates the query_result ib_gib
      query_result <- query_identity |> query(identity_ib_gibs, query_opts)

      # Return the query_result result (non-root) ib^gibs, if any
      # Returns {:ok, []} if none found
      query_result_info <- query_result |> get_info()
      _ = Logger.debug("query_result_info: #{inspect query_result_info}" |> ExChalk.bg_blue |> ExChalk.white)
      oy_ib_gibs <- 
        {:ok, query_result_info}
        ~>> extract_result_ib_gibs([prune_root: true])
        ~>> Common.filter_present_only(identity_ib_gibs)
        
      OK.success oy_ib_gibs
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end

  defp build_query_opts(query_identity_ib_gibs) do
    _ = Logger.debug("query_identity_ib_gibs: #{inspect query_identity_ib_gibs}" |> ExChalk.bg_green |> ExChalk.white)
    query_opts = 
      do_query()
      |> where_rel8ns("ancestor", "with", "ibgib", "oy#{@delim}gib")
      |> where_rel8ns("target_identity", "withany", "ibgib", query_identity_ib_gibs)
    {:ok, query_opts}
  end

  defp extract_result_ib_gibs(query_result_info, opts \\ [prune_root: true]) do
    raw_result_ib_gibs = query_result_info[:rel8ns]["result"]
    result_count = Enum.count(raw_result_ib_gibs)
    case result_count do
      0 ->
        # 0 results is unexpected. Should at least return the root (1 result)
        emsg = emsg_query_result_count(0)
        _ = Logger.error emsg
        {:error, emsg}

      1 ->
        # 1 result should be the root, but I don't explicitly ensure that here.
        if opts[:prune_root] do
          {:ok, []}
        else
          if Enum.at(raw_result_ib_gibs, 0) !== @root_ib_gib do
            Logger.warn "Query result has only one ib_gib that isn't the root. It is expected to always return the root in addition to the other query ib_gibs."
          end
          {:ok, raw_result_ib_gibs}
        end

      _ ->
        # At least one non-root result found
        result_ib_gibs = 
          if opts[:prune_root] do
            [_root | non_root_ib_gibs] = raw_result_ib_gibs
            non_root_ib_gibs
          else
            raw_result_ib_gibs
          end
        
        _ = Logger.debug("foonkie result_ib_gibs: #{inspect result_ib_gibs}" |> ExChalk.bg_blue |> ExChalk.white)
        {:ok, result_ib_gibs}
    end
  end

  defp get_reply_msg(oy_ib_gibs) do
    reply_msg =
      %{
        "data" => %{
          "oy_ib_gibs" => oy_ib_gibs
        }
      }

    _ = Logger.debug("reply_msg huh: #{inspect reply_msg}" |> ExChalk.bg_blue |> ExChalk.white |> ExChalk.italic)
    {:ok, reply_msg}
  end
end
