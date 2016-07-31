defmodule IbGib.Constants do

  def ib_gib do
    quote do
      def delim, do: "^"
      def min_id_length, do: 1
      def max_id_length, do: 64
      def min_ib_gib_length, do: 3 # min + delim + min
      def max_ib_gib_length, do: 129 # max + delim + max
    end
  end

  @doc """
  Use this by `use IbGib.Constants, :error_msgs`
  """
  def error_msgs do
    quote do
      def emsg_invalid_relations do
        "Something about the rel8ns is invalid. :/"
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
