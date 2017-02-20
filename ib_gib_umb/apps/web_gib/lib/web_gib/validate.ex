defmodule WebGib.Validate do
  @moduledoc """
  Validation logic for sanitizing front-facing data.

  IOW, this isn't inside the `ib_gib` app, because it is a wrapper specifically
  geared towards scary input and the `web_gib` app.
  """

  require Logger

  import IbGib.Helper
  import WebGib.Patterns
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :validation
  use WebGib.Constants, :validation

  def validate(type, instance)
  def validate(:ib, ib) do
    valid_ib?(ib)
  end
  def validate(:dest_ib, dest_ib) do
    valid_ib?(dest_ib) or
      # empty or nil dest_ib will be set automatically.
      dest_ib === "" or dest_ib === nil
  end
  def validate(:comment_text, comment_text) when is_bitstring(comment_text) and comment_text !== "" do
    # Right now, I don't really care what text is in there. Will need to do
    # fancier validation later obviously. But I'm not too concerned with text
    # length at the moment, just so long as it is less than the allowed data
    # size.
    _ = Logger.debug "comment_text: #{comment_text}"
    _ = Logger.debug "string length comment_text: #{String.length(comment_text)}"
    _ = Logger.debug "@max_comment_text_size: #{@max_comment_text_size}"

    String.length(comment_text) < @max_comment_text_size
  end
  def validate(:comment_text, comment_text) do
    _ = Logger.warn "Invalid comment_text: #{inspect comment_text}"
    false
  end
  def validate(:pic_data, {content_type, filename, path}) do
    _ = Logger.debug "validating pic_data..."
    !!content_type and !!filename and !!path and File.exists?(path)
  end
  def validate(:link_text, link_text) when is_bitstring(link_text) do
    _ = Logger.debug "link_text: #{link_text}"

    # Just check the bare minimum right now.
    link_text_length = String.length(link_text)
    link_text_length >= @min_link_text_size and
      link_text_length <= @max_link_text_size
  end
  def validate(:link_text, link_text) do
    _ = Logger.warn "Invalid link_text: #{inspect link_text}"
    false
  end
  def validate(:email_addr, email_addr) when is_bitstring(email_addr) do
    _ = Logger.debug "email_addr: #{email_addr}"

    # Just check the bare minimum right now.
    email_addr_length = String.length(email_addr)
    _valid =
      email_addr_length >= @min_email_addr_size and
      email_addr_length <= @max_email_addr_size and
      Regex.match?(@regex_valid_email_addr, email_addr)
  end
  def validate(:email_addr, email_addr) do
    _ = Logger.warn "Invalid email_addr: #{inspect email_addr}"
    false
  end
  def validate(:ib_gib, ib_gib) when is_bitstring(ib_gib) do
    _ = Logger.debug "valid_ib_gib?: #{valid_ib_gib?(ib_gib)}"
    valid? = valid_ib_gib?(ib_gib)

    if valid? do
      _ = Logger.debug("valid?: #{valid?}" |> ExChalk.bg_green)
    else
      _ = Logger.debug("valid?: #{valid?}\nib_gib: #{ib_gib}" |> ExChalk.bg_red)
    end
    valid?
  end
  def validate(:ib_gib, ib_gib) do
    _ = Logger.warn "Invalid ib_gib: #{inspect ib_gib}"
    _ = Logger.debug("valid?: #{false}" |> ExChalk.bg_red)
    false
  end
  def validate(:ib_gibs, ib_gibs) when is_list(ib_gibs) and length(ib_gibs) > 0 do
    Enum.all?(ib_gibs, &(validate(:ib_gib, &1)))
  end
  def validate(:ib_gibs, ib_gibs) do
    _ = Logger.warn "Invalid ib_gibs. Must be a non-empty list of ib_gibs."
    false
  end
  def validate(:query_params, query_params_(...) = query_params) do
    _ = Logger.debug "validating query_params: #{inspect query_params}"
    valid? =
      validate(:query_somehow, query_params) and
      validate(:query_search_text, query_params)

    if valid? do
      _ = Logger.debug("valid?: #{valid?}" |> ExChalk.bg_green)
    else
      _ = Logger.debug("valid?: #{valid?}" |> ExChalk.bg_red)
    end
    valid?
  end
  def validate(:query_somehow, query_params_(...) = query_params) do
    valid? = ib_is? or ib_has? or data_has? or tag_is? or tag_has?
    
  end
  def validate(:query_search_text, query_params_(...) = query_params) do
    if data_has? do
      # data_has? is the least restrictive. So just search per data_has?
      # constraints, b/c don't want to invalidate for invalid ib if they 
      # just have both data and ib checked by default.
      String.length(search_text) <= @max_query_data_text_size
    else
      String.length(search_text) <= @max_id_length
    end
  end
  def validate(:query_search_text, query_params_(...) = query_params) do
    false
  end
  def validate(:rel8n_name, rel8n_name) do
    valid_rel8n_name?(rel8n_name)
  end
  def validate(:adjunct_rel8n, nil) do
    # can't be nil
    false
  end
  def validate(:adjunct_rel8n, adjunct_rel8n) do
    # adjunct_rel8n cannot be "past", "history", etc.
    # i.e. we can't "attach" any ibGib to these rel8ns.
    !Enum.member?(@invalid_adjunct_rel8ns, adjunct_rel8n)
  end
  def validate(:tag_text, tag_text) when is_bitstring(tag_text) and tag_text !== "" do
    _ = Logger.debug "tag_text: #{tag_text}"
    _ = Logger.debug "string length tag_text: #{String.length(tag_text)}"
    _ = Logger.debug "@max_tag_text_size: #{@max_tag_text_size}"

    valid_ib?(tag_text) and 
      String.length(tag_text) <= @max_tag_text_size
  end
  def validate(:tag_text, tag_text) do
    _ = Logger.warn "Invalid tag_text: #{inspect tag_text}"
    false
  end
  def validate(:tag_icons_text, tag_icons_text) 
    when is_bitstring(tag_icons_text) and tag_icons_text !== "" do
    _ = Logger.debug "tag_icons_text: #{tag_icons_text}"
    _ = Logger.debug "string length tag_icons_text: #{String.length(tag_icons_text)}"
    _ = Logger.debug "@max_tag_icons_text_size: #{@max_tag_icons_text_size}"

    String.length(tag_icons_text) < @max_tag_icons_text_size
  end
  def validate(:tag_icons_text, tag_icons_text) do
    _ = Logger.warn "Invalid tag_icons_text: #{inspect tag_icons_text}"
    false
  end
end
