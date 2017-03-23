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
  alias WebGib.Oy
  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import IbGib.Macros, only: [handle_ok_error: 2, ok_pipe_logger: 3]
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  @doc """
  Handles the command for getting oy(!)s. See module doc for more info `WebGib.Bus.Commanding.GetOys`.
  """
  def handle_cmd(data = %{"oy_kind" => oy_kind, "oy_filter" => oy_filter},
                 _metadata,
                 msg,
                 assigns_identity_ib_gibs_(...) = _socket) do
    OK.with do
      _ = Logger.debug("oyyy" |> ExChalk.blue |> ExChalk.bg_yellow)
      # Validate
      true <- validate_input({:ok, :oy_kind}, 
                             oy_kind, 
                             "Invalid oy_kind")
      true <- validate_input({:ok, :oy_filter}, 
                             oy_filter, 
                             "Invalid oy_filter")

     _ = Logger.debug("oyyy2" |> ExChalk.blue |> ExChalk.bg_yellow)

      # Execute
      oy_ib_gibs <- exec_impl(identity_ib_gibs, data)

      # Reply
      reply_msg <- get_reply_msg(oy_ib_gibs)
      _ = Logger.debug("reply_msg oyyo: #{inspect reply_msg}" |> ExChalk.bg_blue |> ExChalk.white)
      
      OK.success reply_msg
    else
      reason -> 
        Logger.error("what up reason oy: #{inspect reason}")
        OK.failure handle_ok_error(reason, log: true)
    end
  end
  def handle_cmd(_data, _metadata, msg, socket) do
    handle_cmd_error(:error, "No clause match.", msg, socket)
  end

  defp exec_impl(identity_ib_gibs, 
                 data = %{"oy_kind" => "adjunct", 
                          "oy_filter" => "new"}) do
    Logger.debug("data: #{inspect data}" |> ExChalk.bg_yellow |> ExChalk.blue)
    OK.with do
      {query_identity_ib_gibs, query_identity} <-
        prepare(identity_ib_gibs)

      oy_ib_gibs <- 
        get_oy_ib_gibs(identity_ib_gibs, 
                       query_identity_ib_gibs, 
                       query_identity,
                       [oy_kind: "adjunct", oy_filter: "new"])

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
                      query_identity,
                      opts = [oy_kind: "adjunct", 
                              oy_filter: "new"]) do
    OK.with do
      # Build the query options
      query_opts <- build_query_opts(query_identity_ib_gibs, opts[:oy_kind])

      oy_ib_gibs <- 
        {:ok, query_identity} 
        ~>> query(identity_ib_gibs, query_opts)
        ~>> get_info()
        ~>> ok_pipe_logger(:debug, "get_oy_ib_gibs query_result_info")
        ~>> extract_result_ib_gibs([prune_root: true])
        ~>> ok_pipe_logger(:debug, "get_oy_ib_gibs result_ib_gibs")
        # ~>> Common.filter_present_only(identity_ib_gibs)
        ~>> ok_pipe_logger(:debug, "get_oy_ib_gibs present only")
        ~>> filter_oy_ib_gibs(opts[:oy_filter])
        ~>> ok_pipe_logger(:debug, "get_oy_ib_gibs filter_oy_ib_gibs")

      OK.success oy_ib_gibs
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  
  defp filter_oy_ib_gibs(oy_ib_gibs, oy_filter)
  defp filter_oy_ib_gibs(oy_ib_gibs, nil) do
    {:ok, oy_ib_gibs}
  end
  defp filter_oy_ib_gibs([], _oy_filter) do
    {:ok, []}
  end
  defp filter_oy_ib_gibs([@root_ib_gib], _oy_filter) do
    {:ok, [@root_ib_gib]}
  end
  defp filter_oy_ib_gibs(oy_ib_gibs, oy_filter = "new") do
    initial = {:ok, []}
    filtered_oy_ib_gibs = 
      Enum.reduce_while(oy_ib_gibs, [], fn(oy_ib_gib, acc) -> 
        case Oy.is_new?(oy_ib_gib) do
          {:ok, true}  -> {:cont, acc ++ [oy_ib_gib]}
          {:ok, false} -> {:cont, acc}
          {:error, _}  -> {:halt, :error}
        end
      end)
    if filtered_oy_ib_gibs == :error do
      {:error, "There was a problem filtering the oy_ib_gibs."}
    else
      {:ok, filtered_oy_ib_gibs}
    end
  end

  defp build_query_opts(query_identity_ib_gibs, _oy_kind = "adjunct") do
    _ = Logger.debug("query_identity_ib_gibs: #{inspect query_identity_ib_gibs}" |> ExChalk.bg_green |> ExChalk.white)
    query_opts = 
      do_query()
      |> where_rel8ns("ancestor", "with", "ibgib", "oy#{@delim}gib")
      |> where_rel8ns("target_identity", "withany", "ibgib", query_identity_ib_gibs)
    {:ok, query_opts}
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
