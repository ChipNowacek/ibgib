defmodule WebGib.Bus.Commanding.Comment do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  (Naming things is hard oy)
  """

  require Logger

  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.Expression
  import IbGib.Helper
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
      {:ok, {comment_ib_gib, new_src_ib_gib}} <-
        exec_impl(identity_ib_gibs, src_ib_gib, comment_text),

      # Broadcast updated src_ib_gib
      _ <-
        EventChannel.broadcast_ib_gib_update(src_ib_gib, new_src_ib_gib),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(comment_ib_gib, new_src_ib_gib)
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
      {:ok, {src, comment_gib}} <- prepare(src_ib_gib),
      {:ok, comment} <-
        create_comment(identity_ib_gibs, src, comment_gib, comment_text),
      # Auto-Relate the comment on the source
      # Here may be where we have to get clever for user interaction, i.e.
      # if the commenter is not the owner of the src.
      {:ok, new_src} <- src |> rel8(comment, identity_ib_gibs, ["comment"]),
      {:ok, {comment_ib_gib, new_src_ib_gib}} <- get_ib_gibs(comment, new_src)
    ) do
      {:ok, {comment_ib_gib, new_src_ib_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  defp prepare(src_ib_gib) do
    with(
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, comment_gib} <-
        IbGib.Expression.Supervisor.start_expression("comment#{@delim}gib")
    ) do
      {:ok, {src, comment_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  defp create_comment(identity_ib_gibs, src, comment_gib, comment_text) do
    with(
      {:ok, comment} <-
        comment_gib |> fork(identity_ib_gibs, "comment"),
      state <- %{
                  "text" => comment_text,
                  "render" => "text",
                  "shape" => "rect"
                },
      {:ok, comment} <- comment |> mut8(identity_ib_gibs, state),
      {:ok, comment} <- comment |> rel8(src, identity_ib_gibs, ["comment_on"])
    ) do
      {:ok, comment}
    else
      error -> default_handle_error(error)
    end
  end

  defp get_ib_gibs(comment, new_src) do
    with(
      {:ok, comment_info} <- get_info(comment),
      {:ok, comment_ib_gib} <- get_ib_gib(comment_info),
      {:ok, new_src_info} <- get_info(new_src),
      {:ok, new_src_ib_gib} <- get_ib_gib(new_src_info)
    ) do
      {:ok, {comment_ib_gib, new_src_ib_gib}}
    else
      error -> default_handle_error(error)
    end
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
