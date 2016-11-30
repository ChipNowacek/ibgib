defmodule WebGib.Validate do
  @moduledoc """
  Validation logic for sanitizing front-facing data.

  IOW, this isn't inside the `ib_gib` app, because it is a wrapper specifically
  geared towards scary input and the `web_gib` app.
  """

  require Logger

  import IbGib.Helper
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :validation
  use WebGib.Constants, :validation

  # ----------------------------------------------------------------------------
  # Helper (refactor this into a module!)
  # ----------------------------------------------------------------------------

  def validate(type, instance)
  def validate(:dest_ib, dest_ib) do
    valid_ib?(dest_ib) or
      # empty or nil dest_ib will be set automatically.
      dest_ib === "" or dest_ib === nil
  end
  def validate(:comment_text, comment_text) when is_bitstring(comment_text) do
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
  def validate(:query_params, query_params) do
    _ = Logger.debug "validating query_params: #{inspect query_params}"
    valid? =
      validate(:search_ib, query_params) and
      validate(:ib_query_type, query_params) and
      validate(:search_data, query_params)

    if valid? do
      _ = Logger.debug("valid?: #{valid?}" |> ExChalk.bg_green)
    else
      _ = Logger.debug("valid?: #{valid?}" |> ExChalk.bg_red)
    end
    valid?
  end
  def validate(:search_ib, %{"search_ib" => search_ib})
    when is_bitstring(search_ib) do
    _ = Logger.debug "validating search_ib: #{search_ib}"
    String.length(search_ib) < @max_id_length
  end
  def validate(:search_ib, %{"search_ib" => search_ib}) do
    _ = Logger.warn "Invalid search_ib: #{inspect search_ib}"
    false
  end
  def validate(:search_ib, _query_params) do
    # none given is fine
    true
  end
  def validate(:ib_query_type, %{"ib_query_type" => ib_query_type})
    when is_bitstring(ib_query_type) do
    _ = Logger.debug "validating ib_query_type: #{ib_query_type}"
    ib_query_type in ["is", "has"]
  end
  def validate(:ib_query_type, query_params) do
    _ = Logger.warn "Invalid ib_query_type: #{inspect query_params}"
    false
  end
  def validate(:search_data, %{"search_data" => search_data})
    when is_bitstring(search_data) do
    _ = Logger.debug "validating search_data: #{search_data}"
    String.length(search_data) <= @max_query_data_text_size
  end
  def validate(:search_data, %{"search_data" => search_data}) do
    _ = Logger.warn "Invalid search_data: #{inspect search_data}"
    false
  end
  def validate(:search_data, _query_params) do
    # none given is fine
    true
  end


end
