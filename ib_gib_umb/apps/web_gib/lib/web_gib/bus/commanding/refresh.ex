defmodule WebGib.Bus.Commanding.Refresh do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.
  """

  require Logger
  require OK

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import IbGib.Expression.Supervisor, only: [start_expression: 1]
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib

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

  defp exec_impl(identity_ib_gibs, src_ib_gib) do
    OK.with do
      src <- start_expression(src_ib_gib)
      info <- src |> get_info
      ancestors = info[:rel8ns]["ancestor"]
      refresh_kind =
        cond do
          Enum.member?(ancestors, "query#{@delim}gib") -> :query
          Enum.member?(ancestors, "query_result#{@delim}gib") -> :query_result
            
          true -> :latest
        end
        
      result_ib_gib <- 
        get_refresh_result_ib_gib(refresh_kind, identity_ib_gibs, src_ib_gib)
      
      _ = Logger.debug("testing OK.with huh" |> ExChalk.bg_red |> ExChalk.green)
      {:ok, {refresh_kind, result_ib_gib}}
    end
  end
  
  defp get_refresh_result_ib_gib(:query, {identity_ib_gibs, 
                                          src_ib_gib,
                                          src,
                                          info}) do
    # Rerun the query
    # rerun_query(src_ib_gib)
    {:error, :not_implemented_query}
  end
  defp get_refresh_result_ib_gib(:query_result, {identity_ib_gibs, 
                                                 src_ib_gib, 
                                                 src, 
                                                 info}) do
    # Rerun the query associated to the result
    {:error, :not_implemented_query_result}
  end
  defp get_refresh_result_ib_gib(:latest, identity_ib_gibs, src_ib_gib) do
    # Get the latest version of the src_ib_gib
    IbGib.Common.get_latest_ib_gib(identity_ib_gibs, src_ib_gib)
  end
  
  defp rerun_query()
  end 

  defp get_reply_msg(src_ib_gib, latest_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "src_ib_gib" => src_ib_gib,
          "latest_ib_gib" => latest_ib_gib,
          "latest_is_different" => src_ib_gib !== latest_ib_gib
        }
      }
    {:ok, reply_msg}
  end
end
