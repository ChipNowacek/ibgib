defmodule IbGib.Auth.Identity do
  @moduledoc """
  This module relates to handling identity with respect to ib_gib.

  I am starting out with the following fundamental thing: identity^gib

  Each of these will be instanced, mut8d and rel8d.

  ## Overall Workflow

  So a user will come to the page. This creates a new session, which provides
  the first "layer" of identity, basically an anonymous identity. There is a
  call made to `get_identity/2` like the following:
    `get_identity(%{session_id: session123}, %{ip: 1.2.3.4})`
  _(I don't know if I'm actually going to log IPs, but probably.)_

  If the session is new, then the queries shown will be for anonymous users:
  ib_gib primitives, popular, category_x, etc.

  At any point the user will be able to add an identity layer. This is like
  logging in. (Probably will be a login screen). This will send a `POST` with
  either username/password (which of course is weak) and/or a sign-in "magic
  link" sent to a user's email. Here will be the associated identity call:

    `get_identity(%{username: "bob", password: "password"}, %{ip: 1.2.3.4})`.
    or
    `get_identity(%{token: abcde12345}, %{email: "example@email.addr", ip: 1.2.3.4})`

  Once the new identity has been created, it will be seen that there are
  multiple identities that are active. Each of these identities will be
  "attached" to new ib, and these identities drive which queries are presented
  to the user, or more generally speaking, which UX is presented to the user.
  """

  use IbGib.Constants, :error_msgs
  import IbGib.{Expression, QueryOptionsFactory, Macros, Helper}

  require Logger

  @doc """
  Checks for an existing identity ib_gib. If does not exist, creates one.

  Returns {:ok, identity_ib_gib} or {:error, reason}

  ## Parameters

  `priv_data` will not be directly stored but will be hashed and converted into
  the identity "ib", which makes the provided identity details content
  addressable. This also means that any changes would create an entirely new
  ib_gib.

  `pub_data` includes what will be the publicly visible associated with the
  identity. If the existing identity has different details, then the identity
  will be mut8d to incorporate this data.


  ## Implementation

  For an identity's ib, I am using the ib as the hash of the given identity
  details.
  E.g. "%{username => cool user, password => badPASSWORD}" hashes to
       "ABCDE12345ABCDE12345ABCDE12345ABCDE12345ABCDE12345"
       "%{identityId => aiSDFJEisjFJSEkwi1923487}" hashes to
       "12345ABCDE12345ABCDE12345ABCDE12345ABCDE12345ABCDE"
       "%{email => "example@email.address", identityId => aiSDFJEisjFJSEkwi1923487}" hashes to
       "YOyoYOyooo1234567890YOyoYOyooo1234567890YOyoYOyooo12345678901234"
       etc.

  Nothing in the `priv_data` is directly persisted. It is only used to
  generate the corresponding `ib`. Since this is "publicly visible", it is
  inevitable that it will be broken via rainbow tables, etc. But since we have
  a "full"ish history of all ib_gib, we can go back to any point in time and
  continue from any point going forward.

  Anything that will be "immediately" publicly visible will be passed in as
  `pub_data`. This includes emails (which are all publicly visible),
  usernames, etc.

  ## Security

  #### What if someone simply forks a new "identity"? If we only look for the
    most recent `ib` with the given hashed `ib`, then this could return the
    forged identity.

    Yes, the `ib` is entirely in control of the user. But the `gib` is only
    generated by the `ib_gib` engine. This is how we can "sign" our primitives
    with a `gib` of only "gib". No one, without direct access to a persistence
    substrate (i.e. db), can manipulate this. In the case of identity, we need
    to keep up not only with the initial identity, but subsequent mut8ns. So we
    cannot simply give the `gib` a value of "gib". So our signature will be
    overwriting the first three and last three characters of the commit hash
    with "gib". E.g. "ABCDEFsomehash12345" => "gibDEFsomehash12gib". Now we can
    add a query constraint of `WHERE gib LIKE 'gib%gib'` (or whatever the
    implementation is).

  ## Additional

  See `IbGib.Auth.Identity` for more information.
  """
  @spec get_identity(map, map) :: {:ok, String.t} | {:error, any}
  def get_identity(priv_data, pub_data)
    when is_map(priv_data) and is_map(pub_data) do
    with {:ok, root_identity} <- IbGib.Expression.Supervisor.start_expression({"identity", "gib"}),
      {:ok, identity_ib} <- get_identity_ib(priv_data),
      {:ok, latest} <- get_latest_identity_ib_gib(identity_ib, root_identity),
      {:ok, {identity_ib_gib, identity_info, identity}} <-
        create_identity_if_needed(latest, root_identity, identity_ib),
      {:ok, identity_ib_gib} <-
        update_data(identity_info, pub_data, identity, identity_ib_gib) do
      {:ok, identity_ib_gib}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  def get_identity(unknown_arg) do
    {:error, emsg_invalid_arg(unknown_arg)}
  end


  @doc """
  Gets the identity ib based on the given `identity_id`.

  ## Examples
      iex> identity_info = %{"some_key" => "some-id_here234987SD(^&@{%})"}
      iex> IbGib.Auth.Identity.get_identity_ib(identity_info)
      {:ok, "6C111BD527531D047C90AE259852F4122E358ECFAAE9F78DAFF81F24B0CA1678"}

  Returns {:ok, identity_ib} if ok, else {:error, reason}
  """
  @spec get_identity_ib(map) :: {:ok, String.t} | {:error, String.t}
  def get_identity_ib(identity_details)
    when is_map(identity_details) do
    identity_ib = hash(identity_details)
    if identity_ib != :error do
      {:ok, identity_ib}
    else
      {:error, emsg_hash_problem}
    end
  end
  def get_identity_ib(unknown_arg) do
    {:error, emsg_invalid_arg(unknown_arg)}
  end

  @doc """
  Bang version of `get_identity_ib/1`.

  ## Examples
      iex> IbGib.Auth.Session.get_identity_ib!("some-id_here234987SD(^&@{%})")
      "6C111BD527531D047C90AE259852F4122E358ECFAAE9F78DAFF81F24B0CA1678"
  """
  def get_identity_ib!(identity_id) do
    bang(get_identity_ib(identity_id))
  end

  @doc """
  Creates a query that checks for the most recent ib_gib corresponding to the
  given `identity_ib`.

  The `query_off_of` is required because we need an ib_gib instance off of
  which to call `query_off_of |> query(query_options)`.

  Returns the latest identity ib^gib in {:ok, latest} if found. If not found
  returns {:ok, nil}. And if an error, {:error, reason}.
  """
  @spec get_latest_identity_ib_gib(String.t, pid) :: {:ok, String.t} | {:ok, nil} | {:error, String.t}
  def get_latest_identity_ib_gib(identity_ib, query_off_of)
    when is_bitstring(identity_ib) and is_pid(query_off_of) do

    query_options =
      do_query |> where_ib("is", identity_ib) |> most_recent_only

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
        # So if two results, then the second will be our identity ib^gib
      count ->
        {:error, emsg_query_result_count(count)}
    end
  end
  def get_latest_identity_ib_gib(identity_id, query_off_of) do
    {:error, emsg_invalid_args([identity_id, query_off_of])}
  end

  defp create_identity_if_needed(existing_ib_gib, root_identity, identity_ib)
    when is_nil(existing_ib_gib) do
    with {:ok, {_, identity}} <- root_identity |> instance(identity_ib),
      {:ok, identity_info} <- identity |> get_info,
      {:ok, identity_ib_gib} <- get_ib_gib(identity_info) do
      {:ok, {identity_ib_gib, identity_info, identity}}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  defp create_identity_if_needed(existing_ib_gib, _, _) do
    with {:ok, identity} <-
        IbGib.Expression.Supervisor.start_expression(existing_ib_gib),
      {:ok, identity_info} <- identity |> get_info,
      {:ok, identity_ib_gib} <- get_ib_gib(identity_info) do
      {:ok, {existing_ib_gib, identity_info, identity}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Looks at the existing `identity_info` and compares it to the given
  `identity_data`. If it's the same, then it simply returns the
  """
  defp update_data(identity_info, identity_data, identity, identity_ib_gib)
    when is_map(identity_info) and is_map(identity_data) and
         is_pid(identity) and is_bitstring(identity_ib_gib) do
    :not_implemented
  end

end