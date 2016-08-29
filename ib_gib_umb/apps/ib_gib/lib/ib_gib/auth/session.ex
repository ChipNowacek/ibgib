# defmodule IbGib.Auth.Session do
#   @moduledoc """
#   This module relates to handling sessions.
#
#   I am using the session ib as the hash of the session_id. So given
#   a session id of `12345`, the actual session *ib* will be some large hash
#   like `ABCDEFGHIJKLMNOSDFOIWEFHISDFJSDJFNDSF1234`. This way it is content-
#   addressable and can be checked for easily. I don't plan on storing the
#   session id itself.
#   """
#
#   use IbGib.Constants, :error_msgs
#   import IbGib.{Expression, QueryOptionsFactory, Macros, Helper}
#
#   require Logger
#
#   @doc """
#   Gets the session ib based on the given `session_id`.
#
#   ## Examples
#       iex> IbGib.Auth.Session.get_session_ib("some-id_here234987SD(^&@{%})")
#       {:ok, "6C111BD527531D047C90AE259852F4122E358ECFAAE9F78DAFF81F24B0CA1678"}
#
#   Returns {:ok, session_ib} if ok, else {:error, reason}
#   """
#   @spec get_session_ib(String.t) :: {:ok, String.t} | {:error, String.t}
#   def get_session_ib(session_id) when is_bitstring(session_id) do
#     session_ib = hash(session_id)
#     if session_ib != :error do
#       {:ok, session_ib}
#     else
#       {:error, emsg_hash_problem}
#     end
#   end
#   def get_session_ib(unknown_arg) do
#     {:error, emsg_invalid_arg(unknown_arg)}
#   end
#
#   @doc """
#   Bang version of `get_session_ib/1`.
#
#   ## Examples
#       iex> IbGib.Auth.Session.get_session_ib!("some-id_here234987SD(^&@{%})")
#       "6C111BD527531D047C90AE259852F4122E358ECFAAE9F78DAFF81F24B0CA1678"
#   """
#   def get_session_ib!(session_id) do
#     bang(get_session_ib(session_id))
#   end
#
#   @doc """
#   Creates a query that checks for the most recent ib_gib corresponding to the
#   given `session_id`.
#   The `query_off_of` is required because we need an ib_gib instance off of
#   which to call `query_off_of |> query(query_options)`.
#
#   Returns the latest session ib^gib in {:ok, latest} if found. If not found
#   returns {:ok, nil}. And if an error, {:error, reason}.
#   """
#   @spec get_latest_session_ib_gib(String.t, pid) :: {:ok, String.t} | {:ok, nil} | {:error, String.t}
#   def get_latest_session_ib_gib(session_id, query_off_of)
#     when is_bitstring(session_id) and is_pid(query_off_of) do
#     session_ib = get_session_ib!(session_id)
#
#     query_options =
#       do_query |> where_ib("is", session_ib) |> most_recent_only
#
#     query_result_info =
#       query_off_of |> query!(query_options) |> get_info!
#
#     result_list = query_result_info[:rel8ns]["result"]
#
#     result_count = Enum.count(result_list)
#     case result_count do
#       1 ->
#         # All queries return ib^gib itself as the first result.
#         # So if there is one result, then that is like an "empty" result.
#         {:ok, nil}
#
#       2 ->
#         {:ok, Enum.at(result_list, 1)}
#         # All queries return ib^gib itself as the first result.
#         # So if two results, then the second will be our session ib^gib
#       count ->
#         {:error, emsg_query_result_count(count)}
#     end
#   end
#   def get_latest_session_ib_gib(session_id, query_off_of) do
#     {:error, emsg_invalid_args([session_id, query_off_of])}
#   end
#
#   @doc """
#   Bang version of `get_latest_session_ib_gib/2`
#   """
#   @spec get_latest_session_ib_gib!(String.t, pid) :: String.t | nil
#   def get_latest_session_ib_gib!(session_id, query_off_of) do
#     bang(get_latest_session_ib_gib(session_id, query_off_of))
#   end
#
#   @doc """
#   Checks for an existing session ib_gib. If does not exist, creates one.
#
#   Returns {:ok, session_ib_gib} or {:error, reason}
#   """
#   @spec get_session(String.t) :: {:ok, String.t}
#   def get_session(session_id) when is_bitstring(session_id) do
#     with {:ok, root_session} <- IbGib.Expression.Supervisor.start_expression({"session", "gib"}),
#       {:ok, session_ib} <- get_session_ib(session_id),
#       {:ok, latest} <- get_latest_session_ib_gib(session_id, root_session),
#       {:ok, session_ib_gib} <- create_session_if_needed(latest, root_session, session_ib) do
#       {:ok, session_ib_gib}
#     else
#       {:error, reason} -> {:error, reason}
#     end
#   end
#   def get_session(unknown_arg) do
#     {:error, emsg_invalid_arg(unknown_arg)}
#   end
#
#   defp create_session_if_needed(existing, root_session, session_ib)
#     when is_nil(existing) do
#     with {:ok, {_, session}} <- root_session |> instance(session_ib),
#       {:ok, session_info} <- session |> get_info,
#       {:ok, session_ib_gib} <- get_ib_gib(session_info) do
#       {:ok, session_ib_gib}
#     else
#       {:error, reason} -> {:error, reason}
#     end
#   end
#   defp create_session_if_needed(existing, _, _) do
#     {:ok, existing}
#   end
#
#   @doc """
#   Bang version of `get_session/1`.
#   """
#   @spec get_session!(String.t) :: String.t
#   def get_session!(session_id) do
#     bang(get_session(session_id))
#   end
#
#   @doc """
#
#   """
#   def get_identity(context, credientials)
#   def get_identity(context = :session, session_id) do
#     :error
#   end
# end
