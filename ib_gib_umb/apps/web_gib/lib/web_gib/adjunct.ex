defmodule WebGib.Adjunct do
  @moduledoc """
  Functions related to using adjuncts with ibGib.

  An adjuncts is an ibGib that has a 1-way rel8n to another
  ibGib. For example, say identity A creates an ibGib a_ib
  and identity B creates a comment "on" it b_comment.
  Identity B owns b_comment and so has authz to add the
  rel8n on b_comment: b_comment => a_ib. _But_ B does not
  have authz to add a rel8n going the other direction:
  a_ib => b_comment, because B does not own a_ib.

  So in this case, where b_comment has a rel8n to a_ib but
  not the other way around, we say that b_comment is an
  "adjunct" to a_ib.
  """

  import OK, only: ["~>>": 2]
  require Logger
  require OK

  alias IbGib.Auth.Authz
  import IbGib.{Expression, Helper, Macros}
  use IbGib.Constants, :ib_gib

  @doc """
  If the current user doing the commenting (pic/etc.) is the owner of
  the thing being commented upon (target), then the would-be adjunct is
  actually directly rel8d to the target.
  But if it isn't authorized, then the adjunct will remain an adjunct
  and an external mechanism will be responsible for displaying others'
  adjuncts to the user.

  ATOW (2017/01/01) I have a query called from the js client that
  looks for all adjuncts of a given temporal junction point (which
  returns adjuncts for an entire timeline of targets).
  """
  def rel8_target_to_other_if_authorized(target, adjunct, identity_ib_gibs, rel8ns) do
    with(
      {:ok, target_info} <- target |> get_info(),
      {authz_result, _} <- Authz.authorize_apply_b(:rel8, target_info[:rel8ns], identity_ib_gibs),
      {:ok, new_target_or_nil} <-
        (
          if authz_result === :ok do
            _ = Logger.debug("authz is ok. rel8r is authorized to rel8 to the target." |> ExChalk.yellow |> ExChalk.bg_blue)
            target |> rel8(adjunct, identity_ib_gibs, rel8ns)
          else
            _ = Logger.debug("authz is NOT ok. rel8r is NOT authorized to rel8 to the target." |> ExChalk.yellow |> ExChalk.bg_red)
            # Not authorized, so this is a user commenting/pic on
            # someone else's ibGib
            {:ok, nil}
          end
        )
    ) do
      {:ok, new_target_or_nil}
    else
      error -> default_handle_error(error)
    end
  end

  @doc """
  This creates an adjunct rel8n on the given adjunct's temporal junction
  point to the target.

  For more info on what a temporal junction point is, see
  `IbGib.Helper.get_temporal_junction_ib_gib/1`.
  """
  def rel8_adjunct_to_target(target, 
                             adjunct,
                             identity_ib_gibs,
                             adjunct_rel8n,
                             adjunct_target_rel8n) do
    OK.with do
      # We're going to mut8 an adjunct_rel8n of the given
      #   `adjunct_rel8n`, e.g. "comment_on".
      # It's useful to do this before the adjunct rel8 itself.
      adjunct <-
        adjunct
        |> mut8(identity_ib_gibs, %{
            # adjunct_rel8n is what the rel8n from the adjunct to the
            # target is.
            # So for a comment, this says that our adjunct has a rel8n
            #   "comment_on" that points to the target.
            "adjunct_rel8n" => adjunct_rel8n,

            # This is the inverse rel8n from the target to the adjunct.
            # So this is saying "If we assimilate the adjunct to the
            #   target, this is the rel8n that it should be under (in
            #   addition to the 'ib^gib' rel8n)."
            # For a comment, e.g., this would be "comment"
            "adjunct_target_rel8n" => adjunct_target_rel8n
          })

      # Back to the Future to the rescue...again!
      # See `IbGib.Helper.get_temporal_junction_ib_gib/1` for more info.
      target_temp_junc_ib_gib <- get_temporal_junction_ib_gib(target)
      target_temporal_junction <-
        IbGib.Expression.Supervisor.start_expression(target_temp_junc_ib_gib)

      # Execute the actual adjunct rel8.
      adjunct <-
        adjunct
        |> rel8(target_temporal_junction,
                identity_ib_gibs,
                ["adjunct_to"])
      adjunct_ib_gib <- adjunct |> get_info() ~>> get_ib_gib()
      
      target_info <- target |> get_info()
      target_email_identities <- Authz.get_identities_of_type(target_info[:rel8ns]["identity"], "email")
      
      # Publish the corresponding Oy notification
      _ <- 
        if length(target_email_identities) > 0 do
          WebGib.Oy.create_and_publish_oy(:adjunct, %{
            "name" => adjunct_target_rel8n,
            "adjunct" => adjunct,
            "adjunct_identities" => identity_ib_gibs,
            "target" => target,
            "target_email_identities" => target_email_identities
          })
        else
          {:ok, :ok}
        end
        
      OK.success {adjunct, target_temp_junc_ib_gib}
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
end
