defmodule IbGib.Auth.Authorizer do
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

    a_has_identity =
      Map.has_key?(a_rel8ns, "identity") and
      length(a_rel8ns["identity"]) > 0 and
      Enum.all?(a_rel8ns["identity"], &Helper.valid_identity?/1)
      # Enum.all?(a_rel8ns["identity"], &(Helper.valid_identity?(&1)))
    b_has_identity =
      Map.has_key?(b_rel8ns, "identity") and
      length(b_rel8ns["identity"]) > 0 and
      Enum.all?(b_rel8ns["identity"], &Helper.valid_identity?/1)
      # Enum.all?(b_rel8ns["identity"], &(Helper.valid_identity?(&1)))

    if a_has_identity and b_has_identity do
      b_identity = b_rel8ns["identity"]
    else
      _ = Logger.error "DOH! Unidentified #{which} apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
      expected = "a_has_identity: true, b_has_identity: true"
      actual = "a_has_identity: #{a_has_identity},
                b_has_identity: #{b_has_identity}"
      raise UnauthorizedError, message:
        emsg_invalid_authorization(expected, actual)
    end
  end
  def authorize_apply_b(which, a_rel8ns, b_rel8ns) when is_atom(which) do
    Logger.metadata([x: which])
    _ = Logger.debug "which: #{inspect which}"
    _ = Logger.warn "a_rel8ns: #{inspect a_rel8ns}"
    _ = Logger.warn "b_rel8ns: #{inspect b_rel8ns}"
    a_has_identity =
      Map.has_key?(a_rel8ns, "identity") and
      # Every identity rel8ns should have ib^gib
      length(a_rel8ns["identity"]) > 0 and
      Enum.all?(a_rel8ns["identity"], &Helper.valid_identity?/1)
    b_has_identity =
      Map.has_key?(b_rel8ns, "identity") and
      # Every identity rel8ns should have ib^gib
      length(b_rel8ns["identity"]) > 0
      Enum.all?(b_rel8ns["identity"], &Helper.valid_identity?/1)

    case {a_has_identity, b_has_identity} do
      {true, true} ->
        # both have identities, so the a must be a subset or equal to b
        # If b is only a session identity
        b_contains_all_of_a =
          Enum.reduce(a_rel8ns["identity"], true, fn(a_ib_gib, acc) ->
            acc and Enum.any?(b_rel8ns["identity"], &(&1 == a_ib_gib))
          end)

        if b_contains_all_of_a do
          # return the b identities, as they may be more restrictive
          b_identity = b_rel8ns["identity"]
        else
          # unauthorized: a requires auth, b does not have any/all
          expected = a_rel8ns["identity"]
          actual = b_rel8ns["identity"]
          _ = Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
          raise UnauthorizedError, message:
            emsg_invalid_authorization(expected, actual)
        end

      {false, true} ->
        # unauthorized: b is required to have authorization and doesn't
        # expected: [something], actual: nil
        expected = "a_has_identity: true, b_has_identity: true"
        actual = "a_has_identity: false, b_has_identity: true"
        _ = Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message:
          emsg_invalid_authorization(expected, actual)

      {true, false} ->
        # unauthorized: a requires auth, b has none
        # expected: a_identity, actual: nil
        expected = a_rel8ns["identity"]
        actual = nil
        _ = Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message:
          emsg_invalid_authorization(expected, actual)

      {false, false} ->
        # unauthorized: b is required to have authorization and doesn't
        # expected: [something], actual: nil
        expected = "a_has_identity: true, b_has_identity: true"
        actual = "a_has_identity: false, b_has_identity: false"
        _ = Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message:
          emsg_invalid_authorization(expected, actual)
    end
  end

end
