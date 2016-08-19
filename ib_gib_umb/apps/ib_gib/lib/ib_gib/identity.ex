defmodule IbGib.Identity do
  @moduledoc """
  This module relates to handling identity with respect to ib_gib.

  I am starting out with the following fundamental things:
    session^gib
    user^gib
    email^gib

  Each of these will be instanced, mut8d and rel8d.

  For the session, I am using the ib as the hash of the session_id. So given
  a session id of `12345`, the actual session ib will be some large hash
  like `ABCDEFGHIJKLMNOSDFOIWEFHISDFJSDJFNDSF1234`. This way it is content-
  addressable and can be checked for easily. I don't plan on storing the
  session id itself.
  """

  use IbGib.Constants, :error_msgs
  import IbGib.Macros
  alias IbGib.{Expression, Helper}
  import IbGib.{Expression, QueryOptionsFactory}
  require Logger

  @doc """
  Gets the session ib based on the given `session_id`.

  ## Examples
      iex> IbGib.Identity.get_session_ib("some-id_here234987SD(^&@{%})")
      {:ok, "6C111BD527531D047C90AE259852F4122E358ECFAAE9F78DAFF81F24B0CA1678"}

  Returns {:ok, session_ib} if ok, else {:error, reason}
  """
  @spec get_session_ib(String.t) :: {:ok, String.t} | {:error, String.t}
  def get_session_ib(session_id) when is_bitstring(session_id) do
    session_ib = Helper.hash(session_id)
    if session_ib != :error do
      {:ok, session_ib}
    else
      {:error, emsg_hash_problem}
    end
  end
  def get_session_ib(unknown_arg) do
    {:error, emsg_invalid_arg(unknown_arg)}
  end

  @doc """
  Bang version of `get_session_ib/1`.

  ## Examples
      iex> IbGib.Identity.get_session_ib!("some-id_here234987SD(^&@{%})")
      "6C111BD527531D047C90AE259852F4122E358ECFAAE9F78DAFF81F24B0CA1678"
  """
  def get_session_ib!(session_id) do
    bang(get_session_ib(session_id))
  end

  @doc """
  Creates a query that checks for the most recent ib_gib corresponding to the
  given `session_id`.
  The `query_off_of` is required because we need an ib_gib instance off of
  which to call `query_off_of |> query(query_options)`.

  Returns the latest session ib^gib in {:ok, latest} if found. If not found
  returns {:ok, nil}. And if an error, {:error, reason}.
  """
  @spec get_latest_session_ib_gib(String.t, pid) :: {:ok, String.t} | {:ok, nil} | {:error, String.t}
  def get_latest_session_ib_gib(session_id, query_off_of)
    when is_bitstring(session_id) and is_pid(query_off_of) do
    session_ib = get_session_ib!(session_id)

    query_options =
      do_query |> where_ib("is", session_ib) |> most_recent_only

    query_result_info =
      query_off_of |> query!(query_options) |> get_info!

    result_list = query_result_info[:rel8ns]["result"]

    result_count = Enum.count(result_list)
    case result_count do
      1 ->
        # All queries return ib^gib itself as the first result.
        # So if there is one result, then that is like an "empty" result.
        {:ok, nil}

      2 ->
        {:ok, Enum.at(result_list, 1)}
        # All queries return ib^gib itself as the first result.
        # So if two results, then the second will be our session ib^gib
      count ->
        {:error, emsg_query_result_count(count)}
    end
  end
  def get_latest_session_ib_gib(session_id, query_off_of) do
    {:error, emsg_invalid_args([session_id, query_off_of])}
  end

  @doc """
  Bang version of `get_latest_session_ib_gib/2`
  """
  @spec get_latest_session_ib_gib!(String.t, pid) :: String.t | nil
  def get_latest_session_ib_gib!(session_id, query_off_of) do
    bang(get_latest_session_ib_gib(session_id, query_off_of))
  end

end
