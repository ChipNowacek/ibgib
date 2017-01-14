defmodule WebGib.Bus.Commanding.Mut8Comment do
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

  import Expat # https://github.com/vic/expat
  require Logger

  alias IbGib.Auth.Authz
  alias WebGib.Bus.Channels.Event, as: EventChannel
  alias WebGib.Adjunct
  import IbGib.{Expression, Helper}
  import WebGib.Bus.Commanding.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib

  defpat comment_data_(
    comment_text_() =
    src_ib_gib_()
  )

  def handle_cmd(comment_data_(...) = data,
                 _metadata,
                 msg,
                 assigns_identity_ib_gibs_(...) = socket) do
    _ = Logger.debug("yakker. src_ib_gib: #{src_ib_gib}" |> ExChalk.blue |> ExChalk.bg_white)
    # Process.sleep(2000);
    with(
      # Validate
      {:comment_text, true} <-
        validate_input(:comment_text, comment_text, "Invalid comment text."),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib, src_ib_gib, "Invalid source ibGib", :ib_gib),
        {:ok, {src_ib, _src_gib}} <- separate_ib_gib(src_ib_gib),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib,
                       {:simple,  src_ib === "comment"},
                       "Source must be a comment^gib."),

      # Execute
      {:ok, new_src_ib_gib} <-
        exec_impl(identity_ib_gibs, src_ib_gib, comment_text),

      # Broadcast update
      {:ok, :ok} <- broadcast(src_ib_gib, new_src_ib_gib),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(new_src_ib_gib)
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
      {:ok, latest_src} <- prepare(identity_ib_gibs, src_ib_gib),

      # Mut8 the comment
      {:ok, new_src} <-
        mut8_comment(identity_ib_gibs, latest_src, comment_text),

      # Get the corresponding ib^gibs to return
      {:ok, new_src_ib_gib} <- get_ib_gibs(new_src)
    ) do
      {:ok, new_src_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  defp prepare(identity_ib_gibs, src_ib_gib) do
    with(
      {:ok, latest_src_ib_gib} <-
        IbGib.Common.get_latest_ib_gib(identity_ib_gibs, src_ib_gib),
      {:ok, latest_src} <-
        IbGib.Expression.Supervisor.start_expression(latest_src_ib_gib)
    ) do
      {:ok, latest_src}
    else
      error -> default_handle_error(error)
    end
  end

  # Creates the comment, only rel8ng it to src via comment_on rel8n.
  defp mut8_comment(identity_ib_gibs, latest_src, comment_text) do
    with(
      state <- %{
                  "text" => comment_text
                  # "render" => "text",
                  # "shape" => "rect"
                },
      {:ok, new_src} <- latest_src |> mut8(identity_ib_gibs, state)
    ) do
      {:ok, new_src}
    else
      error -> default_handle_error(error)
    end
  end

  # Still pluralized because reusing from comment.ex command.
  defp get_ib_gibs(new_src) do
    with(
      {:ok, new_src_info} <- get_info(new_src),
      {:ok, new_src_ib_gib} <- get_ib_gib(new_src_info)
    ) do
      {:ok, new_src_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  defp broadcast(src_ib_gib, new_src_ib_gib) do
    EventChannel.broadcast_ib_gib_event(:update,
                                        {src_ib_gib, new_src_ib_gib})
    {:ok, :ok}
  end

  defp get_reply_msg(new_src_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "new_src_ib_gib" => new_src_ib_gib
        }
      }
    {:ok, reply_msg}
  end
end
