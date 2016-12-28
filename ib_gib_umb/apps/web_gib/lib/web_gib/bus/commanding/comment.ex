defmodule WebGib.Bus.Commanding.Comment do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)

  ## Why Comment on Latest Src - Reducing Branching Timelines

  When we do a comment on a src, we get the latest version of the src first
  and comment on _that_ src. This is to help reduce the possibility of
  accidental branching timelines.

  See
  https://github.com/ibgib/ibgib/commit/4111df50e0c0c4530ae59163bb5c8edcca39cb37

  When we move to a more distributed architecture, this will need to be
  re-visited, because the most recent version would possibly differ, unless
  we use a sharding approach, perhaps based on the temporal junction point of
  an ibGib? Probably this would be best, or perhaps a sharding approach on the
  given user identities. Either way, we need to have a single data store that
  tracks a given timeline, otherwise branching timelines for a single ibGib
  will abound.
  """

  require Logger

  alias WebGib.Bus.Channels.Event, as: EventChannel
  alias IbGib.Auth.Authz
  import IbGib.{Expression, Helper}
  import WebGib.Bus.Commanding.Helper
  use IbGib.Constants, :ib_gib

  def handle_cmd(%{"comment_text" => comment_text,
                    "src_ib_gib" => src_ib_gib} = data,
                 _metadata,
                 msg,
                 %{assigns:
                   %{ib_identity_ib_gibs: identity_ib_gibs}
                 } = socket) do
    _ = Logger.debug("yakker. src_ib_gib: #{src_ib_gib}" |> ExChalk.blue |> ExChalk.bg_white)
    with(
      # Validate
      {:comment_text, true} <-
        validate_input(:comment_text, comment_text, "Invalid comment text."),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib, src_ib_gib, "Invalid source ibGib", :ib_gib),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib,
                       {:simple, src_ib_gib != @root_ib_gib},
                       "Cannot comment on the root"),

      # Execute
      {:ok, {comment_ib_gib, new_src_ib_gib_or_nil, src_temp_junc_ib_gib_or_nil}} <-
        exec_impl(identity_ib_gibs, src_ib_gib, comment_text),

      # Broadcast updates, depending on if we have directly rel8d to
      # the src or if we rel8d an adjunct indirectly to it.
      {:ok, :ok} <-
        broadcast(src_ib_gib,
                  comment_ib_gib,
                  new_src_ib_gib_or_nil,
                  src_temp_junc_ib_gib_or_nil),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(comment_ib_gib, new_src_ib_gib_or_nil)
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

  defp exec_impl(identity_ib_gibs, src_ib_gib, comment_text) do
    with(
      # Get **latest** src and reference to base comment_gib to use.
      # See notes in module doc (`WebGib.Bus.Commanding.Comment`) for
      # more info on why getting the latest src.
      {:ok, {latest_src, comment_gib}} <- prepare(identity_ib_gibs, src_ib_gib),

      # Create the bare comment itself
      {:ok, comment} <-
        create_comment(identity_ib_gibs, latest_src, comment_gib, comment_text),

      # If authorized, rel8 the comment directly to the src
      {:ok, new_src_or_nil} <-
        rel8_to_src_if_authorized(latest_src, comment, identity_ib_gibs),

      # If above is not authorized (new_src_or_nil is nil), then create
      # a 1-way adjunct rel8n on the comment to the src.
      {:ok, {comment, src_temp_junc_ib_gib_or_nil}} <-
        rel8_adjunct_if_necessary(new_src_or_nil, identity_ib_gibs, latest_src, comment),

      # Get the corresponding ib^gibs to return
      {:ok, {comment_ib_gib, new_src_ib_gib_or_nil}} <-
        get_ib_gibs(comment, new_src_or_nil)
    ) do
      {:ok, {comment_ib_gib, new_src_ib_gib_or_nil, src_temp_junc_ib_gib_or_nil}}
    else
      error -> default_handle_error(error)
    end
  end

  defp prepare(identity_ib_gibs, src_ib_gib) do
    with(
      {:ok, latest_src_ib_gib} <-
        IbGib.Common.get_latest_ib_gib(identity_ib_gibs, src_ib_gib),
      {:ok, latest_src} <-
        IbGib.Expression.Supervisor.start_expression(latest_src_ib_gib),

      {:ok, comment_gib} <-
        IbGib.Expression.Supervisor.start_expression("comment#{@delim}gib")
    ) do
      {:ok, {latest_src, comment_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  # Creates the comment, only rel8ng it to src via comment_on rel8n.
  defp create_comment(identity_ib_gibs, latest_src, comment_gib, comment_text) do
    with(
      {:ok, comment} <-
        comment_gib |> fork(identity_ib_gibs, "comment"),
      state <- %{
                  "text" => comment_text,
                  "render" => "text",
                  "shape" => "rect"
                },
      {:ok, comment} <- comment |> mut8(identity_ib_gibs, state),
      {:ok, comment} <-
        comment |> rel8(latest_src, identity_ib_gibs, ["comment_on"])
    ) do
      {:ok, comment}
    else
      error -> default_handle_error(error)
    end
  end

  # Auto-Relate the comment on the source
  # Here may be where we have to get clever for user interaction, i.e.
  # if the commenter is not the owner of the src.
  # So the plan is to do this relate if authorized, i.e. if the current user
  # doing the commenting is the owner of the thing being commented upon.
  # If it isn't authorized, then an external mechanism will be responsible
  # for displaying others' comments to the user.
  defp rel8_to_src_if_authorized(src, comment, identity_ib_gibs) do
    # {:ok, new_src} <- src |> rel8(comment, identity_ib_gibs, ["comment"]),
    with(
      {:ok, src_info} <- src |> get_info(),
      {authz_result, _} <- Authz.authorize_apply_b(:rel8, src_info[:rel8ns], identity_ib_gibs),
      {:ok, new_src_or_nil} <-
        (
          if authz_result === :ok do
            _ = Logger.debug("authz is ok. commenter is authorized to rel8 to the src." |> ExChalk.yellow |> ExChalk.bg_blue)
            src |> rel8(comment, identity_ib_gibs, ["comment"])
          else
            _ = Logger.debug("authz is NOT ok. commenter is NOT authorized to rel8 to the src." |> ExChalk.yellow |> ExChalk.bg_red)
            # Not authorized, so this is a user commenting on someone else's
            # ibGib
            {:ok, nil}
          end
        )
    ) do
      {:ok, new_src_or_nil}
    else
      error -> default_handle_error(error)
    end
  end

  # When doing pic, I should move this function into an
  # `IbGib.Expression.Adjunct` module (or whatever) and generalize it.
  defp rel8_adjunct_if_necessary(nil, identity_ib_gibs, src, comment) do
    _ = Logger.debug("rel8_adjunct necessary. new_src is nil." |> ExChalk.bg_cyan |> ExChalk.black)
    # adjunct IS needed, because new_src is nil. The reasoning here is
    # that we don't have a new_src (it's nil), so the user was NOT authorized
    # to rel8 **directly** to the src, so we DO need an _adjunct_ rel8n.
    with(
      # We're going to mut8 an adjunct_rel8n of "comment_on".
      # It's useful to do this before the adjunct rel8 itself.
      {:ok, comment} <-
        comment |> mut8(identity_ib_gibs, %{
          # adjunct_rel8n is what the rel8n from the adjunct to the target is
          # So this says that our adjunct comment has a rel8n "comment_on"
          # that points to the target.
          "adjunct_rel8n" => "comment_on",

          # This is the inverse rel8n from the target to the adjunct.
          # So this is saying "If we assimilate the adjunct to the target,
          # this is the rel8n that it should be under (in addition to the
          # 'ib^gib' rel8n)."
          "adjunct_target_rel8n" => "comment"
        }),

      # Back to the Future to the rescue...again!
      # See `IbGib.Helper.get_temporal_junction_ib_gib/1` for more info.
      {:ok, src_temp_junc_ib_gib} <- get_temporal_junction_ib_gib(src),
      {:ok, src_temporal_junction} <-
        IbGib.Expression.Supervisor.start_expression(src_temp_junc_ib_gib),

      # Execute the actual adjunct rel8.
      {:ok, comment} <-
        comment |> rel8(src_temporal_junction, identity_ib_gibs, ["adjunct_to"])
    ) do
      {:ok, {comment, src_temp_junc_ib_gib}}
    else
      error -> default_handle_error(error)
    end
  end
  defp rel8_adjunct_if_necessary(_new_src, _identity_ib_gibs, _src, comment) do
    _ = Logger.debug("rel8_adjunct NOT necessary. new_src is NOT nil." |> ExChalk.bg_cyan |> ExChalk.black)
    # adjunct not needed, because new_src was not nil. The reasoning here is
    # that we have a new_src only if we WERE authorized to rel8 comment to src
    # **directly**, so we do NOT need an _adjunct_ rel8n.
    {:ok, {comment, nil}}
  end

  defp get_ib_gibs(comment, new_src) do
    with(
      {:ok, comment_info} <- get_info(comment),
      {:ok, comment_ib_gib} <- get_ib_gib(comment_info),

      {:ok, new_src_info} <-
        (if new_src, do: get_info(new_src), else: {:ok, nil}),
      {:ok, new_src_ib_gib} <-
        (if new_src, do: get_ib_gib(new_src_info), else: {:ok, nil})
    ) do
      {:ok, {comment_ib_gib, new_src_ib_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  defp broadcast(src_ib_gib,
                 comment_ib_gib,
                 new_src_ib_gib_or_nil,
                 src_temp_junc_ib_gib_or_nil)
  defp broadcast(src_ib_gib,
                 _comment_ib_gib,
                 new_src_ib_gib,
                 nil) do
    # We directly rel8d the comment to the src, so publish an update
    # msg for the src.
    EventChannel.broadcast_ib_gib_event(:update,
                                        {src_ib_gib, new_src_ib_gib})
    {:ok, :ok}
  end
  defp broadcast(src_ib_gib,
                 comment_ib_gib,
                 nil = _new_src_ib_gib_or_nil,
                 src_temp_junc_ib_gib) do
   _ = Logger.debug("broadcasting :new_adjunct.\nsrc_temp_junc_ib_gib: #{src_temp_junc_ib_gib}\ncomment_ib_gib: #{comment_ib_gib}\nsrc_ib_gib: #{src_ib_gib}")
    EventChannel.broadcast_ib_gib_event(:new_adjunct,
                                        {src_temp_junc_ib_gib,
                                         comment_ib_gib,
                                         src_ib_gib})
    {:ok, :ok}
  end

  defp get_reply_msg(comment_ib_gib, new_src_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "comment_ib_gib" => comment_ib_gib,
          "new_src_ib_gib" => new_src_ib_gib
        }
      }
    {:ok, reply_msg}
  end
end
