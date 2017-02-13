defmodule WebGib.Bus.Commanding.Tag do
  @moduledoc """
  Command-related code for the bus being implemented on Phoenix channels.

  Tagging is the process of rel8ing ibGib to a tag ibGib to mark it as having
  some quality. This is arguably similar to just rel8ing an ibGib directly to
  another ibGib, but tags are specifically designed to be a property that will
  be queryable and affect how an item is rendered.
  
  See the 
  [Tags issue ibGib](https://www.ibgib.com/ibgib/comment%5E92552362020A5421556F53D9032D6D1873C7659F07FF0B0DE5E28DC0057B03ED), 
  and also the corresponding 
  [GitHub Tagging issue](https://github.com/ibgib/ibgib/issues/169).
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

  defpat tag_data_(
    tag_text_() =
    tag_icons_text_() =
    src_ib_gib_()
  )

  def handle_cmd(tag_data_(...) = data,
                 _metadata,
                 msg,
                 assigns_identity_ib_gibs_(...) = socket) do
    _ = Logger.debug("yakkertag. src_ib_gib: #{src_ib_gib}" |> ExChalk.blue |> ExChalk.bg_white)
    with(
      # Validate
      {:tag_text, true} <-
        validate_input(:tag_text, tag_text, "Invalid tag text."),
      {:tag_icons_text, true} <-
        validate_input(:tag_icons_text, tag_icons_text, "Invalid tag icons text."),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib, src_ib_gib, "Invalid source ibGib", :ib_gib),
      {:src_ib_gib, true} <-
        validate_input(:src_ib_gib,
                       {:simple, src_ib_gib != @root_ib_gib},
                       "Cannot tag the root"),

      # Execute
      {:ok, {tag_ib_gib, new_src_ib_gib_or_nil, src_temp_junc_ib_gib_or_nil}} <-
        exec_impl(identity_ib_gibs, src_ib_gib, tag_text, tag_icons_text),

      # Broadcast updates, depending on if we have directly rel8d to
      # the src or if we rel8d an adjunct indirectly to it.
      {:ok, :ok} <-
        broadcast(src_ib_gib,
                  tag_ib_gib,
                  new_src_ib_gib_or_nil,
                  src_temp_junc_ib_gib_or_nil),

      # Reply
      {:ok, reply_msg} <- get_reply_msg(tag_ib_gib, new_src_ib_gib_or_nil)
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

  defp exec_impl(identity_ib_gibs, src_ib_gib, tag_text, tag_icons_text) do
    with(
      # Get **latest** src and reference to base tag_gib to use.
      # See notes in module doc (`WebGib.Bus.Commanding.Comment`) for
      # more info on why getting the latest src.
      {:ok, {latest_src, tag_gib}} <- prepare(identity_ib_gibs, src_ib_gib),

      # Create the bare tag itself
      {:ok, tag} <-
        create_tag(identity_ib_gibs, latest_src, tag_gib, tag_text, tag_icons_text),

      # If authorized, rel8 the tag directly to the src
      {:ok, new_src_or_nil} <-
          Adjunct.rel8_target_to_other_if_authorized(
            latest_src,
            tag,
            identity_ib_gibs,
            ["tag"]
          ),

      # If above is not authorized (new_src_or_nil is nil), then create
      # a 1-way adjunct rel8n on the tag to the src.
      {:ok, {tag, src_temp_junc_ib_gib_or_nil}} <-
        rel8_adjunct_if_necessary(new_src_or_nil, identity_ib_gibs, latest_src, tag),

      # Get the corresponding ib^gibs to return
      {:ok, {tag_ib_gib, new_src_ib_gib_or_nil}} <-
        get_ib_gibs(tag, new_src_or_nil)
    ) do
      {:ok, {tag_ib_gib, new_src_ib_gib_or_nil, src_temp_junc_ib_gib_or_nil}}
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

      {:ok, tag_gib} <-
        IbGib.Expression.Supervisor.start_expression("tag#{@delim}gib")
    ) do
      {:ok, {latest_src, tag_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  # Creates the tag, only rel8ng it to src via tag_on rel8n.
  # The tag ib is in the form of "tag tag_text", e.g. "tag bookmark", 
  # "tag flagged copyright", "tag highlight", "tag todo-yo", etc.
  defp create_tag(identity_ib_gibs, latest_src, tag_gib, tag_text, tag_icons_text) do
    with(
      {:ok, tag} <-
        tag_gib |> instance(identity_ib_gibs, "tag #{tag_text}"),
      state <- %{
                  "text" => tag_text,
                  "icons" => tag_icons_text,
                  "render" => "tag",
                  "shape" => "rect",
                  "when" => get_timestamp_str()
                },
      {:ok, tag} <- tag |> mut8(identity_ib_gibs, state),
      {:ok, tag} <-
        tag |> rel8(latest_src, identity_ib_gibs, ["tag_"])
    ) do
      {:ok, tag}
    else
      error -> default_handle_error(error)
    end
  end
  

  defp rel8_adjunct_if_necessary(nil, identity_ib_gibs, latest_src, tag) do
    _ = Logger.debug("rel8_adjunct necessary. new_src is nil." |> ExChalk.bg_cyan |> ExChalk.black)
    # adjunct IS needed, because new_src is nil. The reasoning here is
    #   that we don't have a new_src (it's nil), so the user was NOT
    #   authorized to rel8 **directly** to the target, so we need an
    #   _adjunct_ rel8n.
    Adjunct.rel8_adjunct_to_target(
      latest_src,        # target
      tag,               # adjunct
      identity_ib_gibs,  # identity_ib_gibs
      "tag_",            # adjunct_rel8n
      "tag"              # adjunct_target_rel8n
    )
  end
  defp rel8_adjunct_if_necessary(_new_src, _identity_ib_gibs, _src, adjunct) do
    _ = Logger.debug("rel8_adjunct NOT necessary. new_src is NOT nil." |> ExChalk.bg_cyan |> ExChalk.black)
    # adjunct not needed, because new_src was not nil. The reasoning
    #   here is that we have a new_src only if we were authorized to
    #   rel8 adjunct to src **directly**, so we do NOT need an _adjunct_
    #   rel8n.
    {:ok, {adjunct, nil}}
  end


  defp get_ib_gibs(tag, new_src) do
    with(
      {:ok, tag_info} <- get_info(tag),
      {:ok, tag_ib_gib} <- get_ib_gib(tag_info),

      {:ok, new_src_info} <-
        (if new_src, do: get_info(new_src), else: {:ok, nil}),
      {:ok, new_src_ib_gib} <-
        (if new_src, do: get_ib_gib(new_src_info), else: {:ok, nil})
    ) do
      {:ok, {tag_ib_gib, new_src_ib_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  defp broadcast(src_ib_gib,
                 tag_ib_gib,
                 new_src_ib_gib_or_nil,
                 src_temp_junc_ib_gib_or_nil)
  defp broadcast(src_ib_gib,
                 _tag_ib_gib,
                 new_src_ib_gib,
                 nil) do
    # We directly rel8d the tag to the src, so publish an update
    # msg for the src only.
    EventChannel.broadcast_ib_gib_event(:update,
                                        {src_ib_gib, new_src_ib_gib})
    {:ok, :ok}
  end
  defp broadcast(src_ib_gib,
                 tag_ib_gib,
                 nil = _new_src_ib_gib_or_nil,
                 src_temp_junc_ib_gib) do
    _ = Logger.debug("broadcasting :new_adjunct.\nsrc_temp_junc_ib_gib: #{src_temp_junc_ib_gib}\ntag_ib_gib: #{tag_ib_gib}\nsrc_ib_gib: #{src_ib_gib}")
    EventChannel.broadcast_ib_gib_event(:new_adjunct,
                                        {src_temp_junc_ib_gib,
                                         tag_ib_gib,
                                         src_ib_gib})
    {:ok, :ok}
  end

  defp get_reply_msg(tag_ib_gib, new_src_ib_gib) do
    reply_msg =
      %{
        "data" => %{
          "tag_ib_gib" => tag_ib_gib,
          "new_src_ib_gib" => new_src_ib_gib
        }
      }
    {:ok, reply_msg}
  end
end
