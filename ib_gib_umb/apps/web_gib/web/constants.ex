defmodule WebGib.Constants do
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
      def mut8_label do
        # ⎆
        <<226, 142, 134>>
      end

      def mut8_tooltip do
        "Mut8 it huzzah!"
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
