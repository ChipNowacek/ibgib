defmodule WebGib.Bus.Commanding.Refresh do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.
  """

  require Logger

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import WebGib.Bus.Commanding.Helper
  use IbGib.Constants, :ib_gib

  def handle_cmd(%{"src_ib_gib" => src_ib_gib} = data,
                 _metadata,
                 msg,
                 %{assigns:
                   %{ib_identity_ib_gibs: identity_ib_gibs}
                 } = socket) do
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
      {:ok, latest_ib_gib} <- exec_impl(identity_ib_gibs, src_ib_gib),

      latest_is_different <- src_ib_gib !== latest_ib_gib,

      # Broadcast updated src_ib_gib if different
      _ <- (if latest_is_different, do: EventChannel.broadcast_ib_gib_update(src_ib_gib, latest_ib_gib), else: :ok),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(latest_is_different)
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
    with(
      # We will query off of the current identity
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(Enum.at(identity_ib_gibs, 0)),

      # Our search for the latest version must be using the credentials of
      # **that** ibgib's identities, i.e. in that timeline.
      {:ok, src_process} <-
        IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, src_info} <- src_process |> get_info(),
      {:ok, src_identity_ib_gibs} <- get_ib_gib_identity_ib_gibs(src_info),

      # Build the query options
      query_opts <- build_query_opts_latest(src_identity_ib_gibs, src_ib_gib),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <- src |> query(identity_ib_gibs, query_opts),

        # Return the query_result result ib^gib
      {:ok, query_result_info} <- query_result |> get_info(),
      {:ok, result_ib_gib} <-
        extract_result_ib_gib(src_ib_gib, query_result_info)
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

  defp extract_result_ib_gib(src_ib_gib, query_result_info) do
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

  defp get_reply_msg(latest_is_different) do
    reply_msg =
      %{
        "data" => %{
          "latest_is_different" => latest_is_different
        }
      }
    {:ok, reply_msg}
  end
end
