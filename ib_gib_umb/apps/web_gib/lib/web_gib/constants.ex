defmodule WebGib.Constants do
  @moduledoc """
  This module contains constants used in various aspects throughout the
  applications. Each function is a scope of constants and contains instructions
  for consuming the constants in a module.
  """

  def keys do
    quote do
      # I'm prepending ib to differentiate from any other possible name
      # conflict.
      # See `WebGib.Plugs.IbGibSession`
      @ib_session_id_key "ib_session_id"
      @ib_session_ib_gib_key "ib_session_ib_gib"

      # key to array of identities associated with current ib_gib session,
      # stored in session.
      # See `WebGib.Plugs.IbGibIdentity`
      @ib_identity_ib_gibs_key "identity_ib_gibs"

      @meta_query_ib_gib_key "meta_query_ib_gib"
      @meta_query_result_ib_gib_key "meta_query_result_ib_gib"

      @ident_email_email_addr_key "ident_email_email_addr"
      @ident_email_timestamp_key "ident_email_timestamp"
      @ident_email_token_key "ident_email_token"
      @ident_email_src_ib_gib_key "ident_email_src_ib_gib"
      @ident_email_pin_provided_key "ident_email_pin_provided"
    end
  end

  def validation do
    quote do
      @min_ident_pin_size 0
      @max_ident_pin_size 64

      @max_ident_elapsed_ms 300_000
    end
  end

  def config do
    quote do
      # @upload_files_path "/var/www/web_gib/files/"
      @upload_files_path "./files/"
      @pic_thumb_filename_prefix "thumb_"
      @pic_thumb_size "300x300"
      # @upload_files_path "/var/www/app/files/"
    end
  end

  def error_msgs do
    quote do
      @emsg_invalid_dest_ib "Only letters, numbers, spaces, dashes, underscores are allowed for the destination ib. Just hit the back button to return."

      @refresh_msg "Try logging out, refreshing your browser, and then logging back in."
      @emsg_invalid_session "There is a problem with the session.\n#{@refresh_msg}"
      @emsg_invalid_identity "There is a problem with authenticating your identity.\n#{@refresh_msg}"

      @emsg_invalid_ibgib_url "Invalid ib_gib given in URL"

      @emsg_invalid_comment "The comment is invalid."

      @emsg_invalid_link "The link is invalid."
      @emsg_invalid_query "The query is invalid."

      @emsg_invalid_email "The email is invalid."
      @emsg_ident_email_token_expired "The token has expired."
      @emsg_email_send_failed "There were problems sending the login email."
      @emsg_ident_email_failed "There was a problem with the login process."
      @emsg_ident_email_token_mismatch "The token does not match."

      @emsg_could_not_create_thumbnail "There was a problem creating the thumbnail."
    end
  end

  def fork do
    quote do
      def fork_label do
        # ⎇
        <<226,142,135>>

        # ⌥
        # <<226,140,165>>
      end

      def fork_tooltip do
        "Fork it yo!"
      end
    end
  end

  def mut8 do
    quote do
      def mut8_label, do: <<226, 142, 134>> # ⎆
      def mut8_tooltip, do: "Mut8 it huzzah!"
      def mut8_remove_data_label, do: <<226, 157, 140>> # ❌
      def mut8_remove_data_tooltip, do: "Remove it wha?"
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
