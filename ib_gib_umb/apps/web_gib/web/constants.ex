defmodule WebGib.Constants do
  def error_msgs do
    quote do
      def emsg_invalid_dest_ib do
        "Only letters, numbers, spaces, dashes, underscores are allowed for the destination ib. Just hit the back button to return."
      end
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
