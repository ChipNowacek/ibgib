defmodule WebGib.Constants do
  @moduledoc """
  This module contains constants used in various aspects throughout the
  applications. Each function is a scope of constants and contains instructions
  for consuming the constants in a module.
  """

  def keys do
    quote do
      # I'm prepending ib_gib_ to differentiate from any other possible name
      # conflict.
      # See `WebGib.Plugs.IbGibSession`
      @session_id_key :ib_gib_session_id
      @session_ib_gib_key :session_ib_gib

      # key to array of identities associated with current session.
      # See `WebGib.Plugs.IbGibIdentity`
      @identity_ib_gibs_key :identity_ib_gibs
    end
  end

  def error_msgs do
    quote do
      @emsg_invalid_dest_ib "Only letters, numbers, spaces, dashes, underscores are allowed for the destination ib. Just hit the back button to return."

      @refresh_msg "Try logging out, refreshing your browser, and then logging back in."
      @emsg_invalid_session "There is a problem with the session. #{@refresh_msg}"
      @emsg_invalid_authentication "There is a problem with authentication. #{@refresh_msg}"
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
