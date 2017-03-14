defmodule IbGib.Auth.Authz do
  @moduledoc """
  Contains functionality that authorizes interaction between two ibgib.
  I will refer to these as `a` and `b`, and conceivably this refers to _any_
  two ibgib. However, for right now, `a` will be a "regular" ibgib and `b` will
  refer to...

    * A `transform`
      * `fork`, `mut8`, or `rel8`
      * Generates a "regular" ibgib as output

    * A `plan`
      * A group of 1 or more `transform`s.
      * Generates intermediate transforms when applied
      * Generates a final "regular" ibgib as output

    * A `query`
      * Contains immutable data describing a query
      * Generates a `query_result` ibgib with `rel8n` `"result"` that contains
        the results of the query's execution.

  A "regular" ibgib is anything else that isn't one of these three.

  When `b` is applied to `a`, there are certain authorization rules that must
  be met. This module governs that interaction.
  """

  # ----------------------------------------------------------------------------
  # alias, import, require, use
  # ----------------------------------------------------------------------------

  require Logger

  alias IbGib.{Helper, UnauthorizedError}

  import IbGib.Macros

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs


  # ----------------------------------------------------------------------------
  # Functions
  # ----------------------------------------------------------------------------

  # Check to make sure that our identities are valid (authorization)
  # The passed in identities must contain **all** of the existing identities.
  # Otherwise, the caller does not have the proper authorization, and should
  # fork their own version before trying to mut8/rel8.
  # Note also that this will **ADD** any other identities that are passed in,
  # thus raising the level of authorization required for future mut8ns/rel8ns.
  # Returns b_identities if authorized.
  # b must always have at least one identity
  @spec authorize_apply_b(atom, map, map) :: {:ok, list(String.t)} | {:error, String.t}
  def authorize_apply_b(which, a_rel8ns, b_rel8ns)
  def authorize_apply_b(which, a_rel8ns, b_rel8ns)
    when (which == :fork or which == :query) and
         is_map(a_rel8ns) and is_map(b_rel8ns) do
    # When authorizing a fork or query, we only care that both a and b _have_
    # valid identities, because anyone can fork/read anything else.
    # Authorization here is really just checking for error in code or more
    # nefarious monkey business and ensuring that whoever could be doing said
    # monkey business at least has some identity.
    Logger.metadata([x: which])
    _ = Logger.debug "which: #{which}"
    _ = Logger.debug "a_rel8ns: #{inspect a_rel8ns}"
    _ = Logger.debug "b_rel8ns: #{inspect b_rel8ns}"

    if has_identity(a_rel8ns) and has_identity(b_rel8ns) do
      {:ok, b_rel8ns["identity"]}
    else
      expected = "a_has_identity: true, b_has_identity: true"
      actual = "a_has_identity: #{has_identity(a_rel8ns)},
                b_has_identity: #{has_identity(b_rel8ns)}"
      {:error, emsg_invalid_authorization(expected, actual)}
    end
  end
  def authorize_apply_b(which, a_rel8ns, b_rel8ns)
    when is_atom(which) and is_map(a_rel8ns) and is_map(b_rel8ns) do
    Logger.metadata([x: which])
    _ = Logger.debug "which: #{inspect which}"
    _ = Logger.debug "a_rel8ns: #{inspect a_rel8ns}"
    _ = Logger.debug "b_rel8ns: #{inspect b_rel8ns}"

    with(
      {:ok, :ok} <- ensure_a_and_b_have_identity(a_rel8ns, b_rel8ns),
      {:ok, highest_tier} <- get_highest_auth_tier(a_rel8ns),
      {:ok, :ok} <- check_tier_authorized(highest_tier, a_rel8ns, b_rel8ns)
    ) do
      # Return b identities for convenience to caller
      {:ok, b_rel8ns["identity"]}
    else
      error -> Helper.default_handle_error(error)
    end
  end
  def authorize_apply_b(which, a_rel8ns, b_identities)
    when (which == :fork or which == :query) and
         is_map(a_rel8ns) and is_list(b_identities) do
    a_has_identity = has_identity(a_rel8ns)
    b_identities_length = length(b_identities) > 0
    valid_b_identities = Enum.all?(b_identities, &Helper.valid_identity?/1)

    if a_has_identity and b_identities_length and valid_b_identities do
      {:ok, b_identities}
    else
      expected = "a_has_identity: true, b_identities are valid"
      actual = "a_has_identity: #{a_has_identity},
                b_identities_length: #{b_identities_length},
                valid_b_identities: #{valid_b_identities}"

      {:error, emsg_invalid_authorization(expected, actual)}
    end
  end
  def authorize_apply_b(which, a_rel8ns, b_identities)
    when is_atom(which) and is_map(a_rel8ns) and is_list(b_identities) do
    Logger.metadata([x: which])
    _ = Logger.debug "which: #{inspect which}"
    _ = Logger.debug "a_rel8ns: #{inspect a_rel8ns}"
    _ = Logger.debug "b_identities: #{inspect b_identities}"

    with(
      true <- has_identity(a_rel8ns),
      {:ok, highest_tier} <- get_highest_auth_tier(a_rel8ns),
      {:ok, :ok} <- check_tier_authorized(highest_tier, a_rel8ns, b_identities)
    ) do
      # Return b identities for convenience to caller
      {:ok, b_identities}
    else
      error -> Helper.default_handle_error(error)
    end
  end

  # If this is invalid, then we are going to fail fast and crash, which is
  # what we want, since this is in the new process that was created (somehow)
  # by an unauthorized caller.
  # This raises a special `UnauthorizedError` error.
  @spec authorize_apply_b!(atom, map, map) :: list(String.t)
  def authorize_apply_b!(which, a_rel8ns, b_rel8ns) do
    case authorize_apply_b(which, a_rel8ns, b_rel8ns) do
      {:ok, b_identities} -> b_identities
      {:error, reason} ->
        _ = Logger.error "DOH! Unauthorized transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}\nreason: #{reason}"
        raise UnauthorizedError, message: reason
    end
  end

  # ----------------------------------------------------------------------------
  # Private Impl Methods
  # ----------------------------------------------------------------------------

  defp ensure_a_and_b_have_identity(a_rel8ns, b_rel8ns) do
    case {has_identity(a_rel8ns), has_identity(b_rel8ns)} do
      {true, true} ->
        # authorized
        {:ok, :ok}

      {false, true} ->
        # unauthorized: b is required to have authorization and doesn't
        expected = "a_has_identity: true, b_has_identity: true"
        actual = "a_has_identity: false, b_has_identity: true"
        {:error, emsg_invalid_authorization(expected, actual)}

      {true, false} ->
        # unauthorized: a requires auth, b has none
        expected = a_rel8ns["identity"]
        actual = nil
        {:error, emsg_invalid_authorization(expected, actual)}

      {false, false} ->
        # unauthorized: b is required to have authorization and doesn't
        expected = "a_has_identity: true, b_has_identity: true"
        actual = "a_has_identity: false, b_has_identity: false"
        {:error, emsg_invalid_authorization(expected, actual)}
    end
  end

  # This looks through the identities in `rel8ns` and sees what the highest
  # level of authorization we have. Email is the highest (ATOW 2016/10/08),
  # then session, then ibgib (i.e. "none").
  defp get_highest_auth_tier(rel8ns) do
    identity_types =
      rel8ns["identity"]
      # |> Enum.reduce([], &(&2 ++ [get_identity_type(&1)]))
      |> Enum.reduce([], fn(ib_gib, acc) ->
           _ = Logger.debug("ib_gib: #{ib_gib}" |> ExChalk.bg_blue)
           acc ++ [get_identity_type(ib_gib)]
         end)
      |> Enum.uniq()

    cond do
      Enum.member?(identity_types, "email")   -> {:ok, :email}
      Enum.member?(identity_types, "session") -> {:ok, :session}
      Enum.member?(identity_types, "ibgib")   -> {:ok, :ibgib}

      # I don't know how this would get here, but would be a no-no.
      true ->
        emsg = emsg_invalid_authorization(_expected = "email, session, or ibgib", "unknown")
        Logger.error emsg
        {:error, emsg}
    end
  end

  defp check_tier_authorized(auth_tier, a_rel8ns, b_rel8ns)
  defp check_tier_authorized(:ibgib, _a_rel8ns, _b_rel8ns) do
    # At this point, we have already determined that both have identity.
    # So it is authorized.
    {:ok, :ok}
  end
  defp check_tier_authorized(:session, a_rel8ns, b_rel8ns)
    when is_map(b_rel8ns) do
    b_identities = b_rel8ns["identity"]
    check_tier_authorized(:session, a_rel8ns, b_identities)
  end
  defp check_tier_authorized(:session, a_rel8ns, b_identities)
    when is_list(b_identities) do
    # `a` only has a session identity, so `b` must have at least that same
    # session identity ib^gib.
    # It's ok if `b` also has additional email identities.

    a_identities = a_rel8ns["identity"]
    a_session_identity =
      a_identities
      |> Enum.filter(&(get_identity_type(&1) == "session"))
      |> Enum.at(0)

    b_contains_a_session_identity =
      Enum.member?(b_identities, a_session_identity)

    if b_contains_a_session_identity do
      {:ok, :ok}
    else
      # unauthorized: a requires auth, b does not have any/all
      expected = a_identities
      actual = b_identities
      {:error, emsg_invalid_authorization(expected, actual)}
    end
  end
  defp check_tier_authorized(:email, a_rel8ns, b_rel8ns) when is_map(b_rel8ns) do
    b_identities = b_rel8ns["identity"]
    check_tier_authorized(:email, a_rel8ns, b_identities)
  end
  defp check_tier_authorized(:email, a_rel8ns, b_identities)
    when is_list(b_identities) do
    # `a` has at least one email identity, so `b` email identity/identities
    # must contain at least all of `a` email identities.
    a_email_identities =
      a_rel8ns["identity"]
      |> Enum.filter(&(get_identity_type(&1) == "email"))

    b_contains_all_of_a_email_identities =
      a_email_identities
      |> Enum.reduce(true, fn(a_ib_gib, acc) ->
           acc and Enum.member?(b_identities, a_ib_gib)
         end)

    if b_contains_all_of_a_email_identities do
      # authorized
      {:ok, :ok}
    else
      # unauthorized: a requires auth, b does not have any/all
      expected = a_email_identities
      actual = b_identities
      # We don't need to log an error, since this could be called from 
      # determining if we are doing an adjunct or not. The bang (!) version 
      # raises and logs error if unauthorized 
      _ = Logger.debug "Unauthorized. Checking for adjunct, allow, etc.?\na_rel8ns:#{inspect a_rel8ns}\nb_identities:#{inspect b_identities}"
      {:error, emsg_invalid_authorization(expected, actual)}
    end
  end

  # ----------------------------------------------------------------------------
  # Helper
  # ----------------------------------------------------------------------------

  defp has_identity(rel8ns) do
    Map.has_key?(rel8ns, "identity") and
      length(rel8ns["identity"]) > 0 and
      Enum.all?(rel8ns["identity"], &Helper.valid_identity?/1)
  end

  @doc """
  Gets the identity type of a given `identity_ib_gib`.
  
  ## Examples
  
    iex> IbGib.Auth.Authz.get_identity_type("ib^gib")
    "ibgib"
    
    iex> IbGib.Auth.Authz.get_identity_type("session_abc^123gib")
    "session"

    iex> IbGib.Auth.Authz.get_identity_type("email_abc^123gib")
    "email"
  """
  def get_identity_type(identity_ib_gib)
  def get_identity_type(@root_ib_gib) do
    "ibgib"
  end
  def get_identity_type(identity_ib_gib) do
    {ib, _gib} = Helper.separate_ib_gib!(identity_ib_gib)
    [identity_type, _] = String.split(ib, @identity_type_delim)
    identity_type
  end
  
  @doc """
  Gets a filtered list of identity_ib_gibs which are the given `identity_type`.
  
  ## Examples
  
    iex> IbGib.Auth.Authz.get_identities_of_type(["ib^gib", "session_abc^123"], "ibgib")
    {:ok, ["ib^gib"]}

    iex> IbGib.Auth.Authz.get_identities_of_type(["ib^gib", "session_abc^123"], "session")
    {:ok, ["session_abc^123"]}

    iex> IbGib.Auth.Authz.get_identities_of_type(["ib^gib", "session_abc^123", "email_abc^123", "email_def^456"], "email")
    {:ok, ["email_abc^123", "email_def^456"]}
  """
  def get_identities_of_type(identity_ib_gibs, identity_type) 
  def get_identities_of_type(identity_ib_gibs, identity_type) 
    when is_list(identity_ib_gibs) and identity_ib_gibs !== [] and
         is_bitstring(identity_type) do
    identities =
      identity_ib_gibs
      |> Enum.filter(&(get_identity_type(&1) == identity_type))
    {:ok, identities}
  end
  def get_identities_of_type(identity_ib_gibs, identity_type) do
    invalid_args([identity_ib_gibs, identity_type])
  end
  
  @doc """
  Bang version of `get_identities_of_type/2`.

  iex> IbGib.Auth.Authz.get_identities_of_type!(["ib^gib", "session_abc^123"], "ibgib")
  ["ib^gib"]

  iex> IbGib.Auth.Authz.get_identities_of_type!(["ib^gib", "session_abc^123"], "session")
  ["session_abc^123"]

  iex> IbGib.Auth.Authz.get_identities_of_type!(["ib^gib", "session_abc^123", "email_abc^123", "email_def^456"], "email")
  ["email_abc^123", "email_def^456"]
  """
  def get_identities_of_type!(identity_ib_gibs, identity_type) do
    bang(get_identities_of_type(identity_ib_gibs, identity_type))
  end
end
