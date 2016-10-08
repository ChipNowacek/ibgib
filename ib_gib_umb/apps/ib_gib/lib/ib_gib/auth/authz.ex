defmodule IbGib.Auth.Authz do
  @moduledoc """
  Contains behavior that authorizes interaction between two ibgib.
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
  # fork their own version before trying to mut8.
  # Note also that this will **ADD** any other identities that are passed in,
  # thus raising the level of authorization required for future mut8ns.
  # If this is invalid, then we are going to fail fast and crash, which is
  # what we want, since this is in the new process that was created (somehow)
  # by an unauthorized caller.
  # Returns b_identities if authorized.
  # Raises exception if unauthorized (fail fast is proper).
  # b must always have at least one identity
  @spec authorize_apply_b(atom, map, map) :: list(String.t)
  def authorize_apply_b(which, a_rel8ns, b_rel8ns)
  def authorize_apply_b(which, a_rel8ns, b_rel8ns)
    when which == :fork or which == :query do
    # When authorizing a fork or query, we only care that both a and b _have_
    # valid identities, because anyone can fork/read anything else.
    # Authorization here is really just checking for error in code or more
    # nefarious monkey business and ensuring that whoever could be doing said
    # monkey business at least has some identity.
    Logger.metadata([x: which])
    _ = Logger.debug "which: #{which}"
    _ = Logger.warn "a_rel8ns: #{inspect a_rel8ns}"
    _ = Logger.warn "b_rel8ns: #{inspect b_rel8ns}"

    # if a_has_identity and b_has_identity do
    if has_identity(a_rel8ns) and has_identity(b_rel8ns) do
      b_identity = b_rel8ns["identity"]
    else
      _ = Logger.error "DOH! Unidentified #{which} apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
      expected = "a_has_identity: true, b_has_identity: true"
      actual = "a_has_identity: #{has_identity(a_rel8ns)},
                b_has_identity: #{has_identity(b_rel8ns)}"
      raise UnauthorizedError, message:
        emsg_invalid_authorization(expected, actual)
    end
  end
  def authorize_apply_b(which, a_rel8ns, b_rel8ns) when is_atom(which) do
    Logger.metadata([x: which])
    _ = Logger.debug "which: #{inspect which}"
    _ = Logger.warn "a_rel8ns: #{inspect a_rel8ns}"
    _ = Logger.warn "b_rel8ns: #{inspect b_rel8ns}"

    with(
      {:ok, :ok} <- ensure_a_and_b_have_identity(a_rel8ns, b_rel8ns),
      {:ok, highest_tier} <- get_highest_auth_tier(a_rel8ns),
      {:ok, :ok} <- ensure_tier_authorized(highest_tier, a_rel8ns, b_rel8ns)
    ) do
      # Return b identities for convenience to caller
      b_rel8ns["identity"]
    else
      {:error, reason} ->
        _ = Logger.error "DOH! Unauthorized transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}\nreason: #{reason}"
        raise UnauthorizedError, message: reason
    end
  end

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
      # |> Enum.reduce([], fn(identity_ib_gib, acc)) ->
      #      if identity_ib_gib == @root_ib_gib do
      #        acc ++ ["ibgib"]
      #      else
      #        acc ++ [get_identity_type(identity_ib_gib)]
      #      end
      #    end)
      |> Enum.uniq

    cond do
      Enum.member?(identity_types, "email")   -> {:ok, :email}
      Enum.member?(identity_types, "session") -> {:ok, :session}
      Enum.member?(identity_types, "ibgib")   -> {:ok, :ibgib}

      # I don't know how this would get here, but would be a no-no.
      true ->
        emsg = emsg_invalid_authorization(expected = "email, session, or ibgib", "unknown")
        Logger.error emsg
        {:error, emsg}
    end
  end

  # Raises `UnauthorizedError` if unauthorized.
  defp ensure_tier_authorized(auth_tier, a_rel8ns, b_rel8ns)
  defp ensure_tier_authorized(:ibgib, a_rel8ns, b_rel8ns) do
    # At this point, we have already determined that both have identity.
    # So it is authorized.
    {:ok, :ok}
  end
  defp ensure_tier_authorized(:session, a_rel8ns, b_rel8ns) do
    # `a` only has a session identity, so `b` must have at least that same
    # session identity ib^gib.
    # It's ok if `b` also has additional email identities.

    a_identities = a_rel8ns["identity"]
    a_session_identity =
      a_identities
      |> Enum.filter(&(get_identity_type(&1) == "session"))
      |> Enum.at(0)

    b_contains_a_session_identity =
      Enum.member?(b_rel8ns["identity"], a_session_identity)

    if b_contains_a_session_identity do
      {:ok, :ok}
    else
      # unauthorized: a requires auth, b does not have any/all
      expected = a_rel8ns["identity"]
      actual = b_rel8ns["identity"]
      {:error, emsg_invalid_authorization(expected, actual)}
    end
  end
  defp ensure_tier_authorized(:email, a_rel8ns, b_rel8ns) do
    # `a` has at least one email identity, so `b` email identity/identities
    # must contain at least all of `a` email identities.
    a_email_identities =
      a_rel8ns["identity"]
      |> Enum.filter(&(get_identity_type(&1) == "email"))

    b_identities = b_rel8ns["identity"]

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
      expected = a_rel8ns["identity"]
      actual = b_rel8ns["identity"]
      _ = Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
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

  defp get_identity_type(@root_ib_gib) do
    "ibgib"
  end
  defp get_identity_type(identity_ib_gib) do
    {ib, _gib} = Helper.separate_ib_gib!(identity_ib_gib)
    [identity_type, _] = String.split(ib, @identity_type_delim)
    identity_type
  end
end
