defmodule WebGib.Bus.Commanding.Refresh do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.
  """

  require Logger
  require OK
  import OK, only: ["~>>": 2]

  alias IbGib.Auth.Authz
  alias IbGib.Common
  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import IbGib.Macros, only: [invalid_args: 1]
  import IbGib.Expression.Supervisor, only: [start_expression: 1]
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

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
      {:ok, {refresh_kind, result_ib_gib}} <- exec_impl(identity_ib_gibs, src_ib_gib),

      # latest_is_different <- src_ib_gib !== latest_ib_gib,

      # # I can't just broadcast on the channel, because this will
      # # broadcast to all connected devices (very bad).
      # # Broadcast latest_ib_gib if different
      # _ <- (if latest_is_different,
      #       do: EventChannel.broadcast_ib_gib_event(:update, {src_ib_gib, latest_ib_gib}),
      #       else: :ok),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(refresh_kind, src_ib_gib, result_ib_gib)
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

  # _ = Logger.debug("testing OK.with huh. refreshed_ib_gib: #{refreshed_ib_gib}" |> ExChalk.bg_red |> ExChalk.green)

# defp exec_impl(identity_ib_gibs, src_ib_gib) do
# with(
#   {:ok, src} <- start_expression(src_ib_gib),
#   {:ok, info} <- src |> get_info(),
#   
#   # Depending on the src, we'll execute refresh differently.
#   {:ok, refresh_kind} <- get_refresh_kind(info[:rel8ns]["ancestor"]),
# 
#   {:ok, refreshed_ib_gib} <- 
#     refresh(refresh_kind, identity_ib_gibs, src_ib_gib, src, info)
# ) do
#   {:ok, {refresh_kind, refreshed_ib_gib}}
# end
# end

  defp exec_impl(identity_ib_gibs, src_ib_gib) do
    OK.with do
      src <- start_expression(src_ib_gib)
      info <- src |> get_info()
      
      refresh_kind <- get_refresh_kind(info[:rel8ns]["ancestor"])

      refreshed_ib_gib <- 
        refresh(refresh_kind, identity_ib_gibs, src_ib_gib, src, info)

      _ = Logger.debug("testing OK.with huh. refreshed_ib_gib: #{refreshed_ib_gib}" |> ExChalk.bg_red |> ExChalk.green)

      OK.success {refresh_kind, refreshed_ib_gib}
    else
      :not_implemented_query -> OK.failure "Not implemented for query"
      :not_implemented_query_result -> OK.failure "Not implemented for query result"
    end
  end

  
  defp get_refresh_kind(ancestors) 
    when ancestors != nil and is_list(ancestors) do
    refresh_kind = 
      cond do
        Enum.member?(ancestors, "query#{@delim}gib") ->
          :query
        Enum.member?(ancestors, "query_result#{@delim}gib") ->
          :query_result
        true ->
          :latest
      end
    {:ok, refresh_kind}
  end
  defp get_refresh_kind(ancestors) do
    invalid_args(ancestors)
  end
  
  defp refresh(refresh_kind, identity_ib_gibs, src_ib_gib, src, src_info)
  defp refresh(:query, identity_ib_gibs, query_ib_gib, query, query_info) do
    # Rerun the query
    OK.with do
      _ <- Authz.authorize_apply_b(:rel8, query_info[:rel8ns], identity_ib_gibs)
      # Contact the query with itself to rerun it.
      query_identity_ib_gibs <-
        Common.get_identities_for_query(identity_ib_gibs)
      query_identity_ib_gib = query_identity_ib_gibs |> Enum.at(0)
      query_identity <-
        IbGib.Expression.Supervisor.start_expression(query_identity_ib_gib)
      query_result <- contact(query_identity, query)
      query_result_ib_gib <- query_result |> get_info() ~>> get_ib_gib()
      
      OK.success query_result_ib_gib
    end
  end
  defp refresh(:query_result, identity_ib_gibs, query_result_ib_gib, query_result, query_result_info) do
    OK.with do
      query_ib_gib <- get_query_ib_gib(query_result_info[:rel8ns]["query"])
      query <- IbGib.Expression.Supervisor.start_expression(query_ib_gib)
      query_info <- query |> get_info()
      refresh(:query, identity_ib_gibs, query_ib_gib, query, query_info)
    end
  end
  defp refresh(:latest, identity_ib_gibs, src_ib_gib, _src, _src_info) do
    # Get the latest version of the src_ib_gib
    IbGib.Common.get_latest_ib_gib(identity_ib_gibs, src_ib_gib)
  end
  
  defp get_query_ib_gib(query_rel8ns)
    when is_list(query_rel8ns) and length(query_rel8ns) === 1 do
    {:ok, Enum.at(query_rel8ns, 0)}
  end
  defp get_query_ib_gib(query_rel8ns) do
    {:error, "Invalid query rel8ns. query_result should have a \"query\" rel8n with a single ib^gib."}
  end

  defp get_reply_msg(:query = refresh_kind, query_ib_gib, query_result_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "query_ib_gib" => query_ib_gib,
          "query_result_ib_gib" => query_result_ib_gib
        },
        "metadata" => %{
          "refresh_kind" => refresh_kind
        }
      }
    {:ok, reply_msg}
  end
  defp get_reply_msg(:query_result = refresh_kind, src_ib_gib, latest_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "src_ib_gib" => src_ib_gib,
          "latest_ib_gib" => latest_ib_gib,
          "latest_is_different" => src_ib_gib !== latest_ib_gib
        },
        "metadata" => %{
          "refresh_kind" => refresh_kind
        }
      }
    {:ok, reply_msg}
  end
  defp get_reply_msg(:latest = refresh_kind, src_ib_gib, latest_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "src_ib_gib" => src_ib_gib,
          "latest_ib_gib" => latest_ib_gib,
          "latest_is_different" => src_ib_gib !== latest_ib_gib
        },
        "metadata" => %{
          "refresh_kind" => refresh_kind
        }
      }
    {:ok, reply_msg}
  end
end
