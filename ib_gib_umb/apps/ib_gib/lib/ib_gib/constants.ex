defmodule IbGib.Constants do

  @doc """
  Use this with `use IbGib.Constants, :ib_gib`
  """
  def ib_gib do
    quote do
      # if change, must also change in regex below
      def delim, do: "^"

      def min_id_length, do: 1
      def max_id_length, do: 64
      def min_ib_gib_length, do: 3 # min + delim + min
      def max_ib_gib_length, do: 129 # max + delim + max
      def max_data_size, do: 10_240_000 # 10 MB max internal data
      # one or more word chars, underscore, dash
      def regex_valid_ib, do: ~r/^[\w\d_-\s]+$/
      def regex_valid_gib, do: ~r/^[\w\d]+$/
      # delim hardcoded in!!!!
      def regex_valid_ib_gib, do: ~r/^[\w\d_-\s]+\^[\w\d]+$/

      def default_history, do: ["ib#{delim}gib"]

    end
  end

  @doc """
  Use this with `use IbGib.Constants, :error_msgs`
  """
  def error_msgs do
    quote do
      def emsg_invalid_relations do
        "Something about the rel8ns is invalid. :-/"
      end

      def emsg_invalid_data do
        "Something about the data is invalid. :-O"
      end

      def emsg_invalid_id_length do
        "invalid id length"
      end

      def emsg_invalid_unknown_src_maybe do
        "invalid. unknown src maybe, maybe not an array of string"
      end

      def emsg_invalid_data_value(value) do
        "invalid data value: #{inspect value}"
      end

      def emsg_unknown_field do
        "Unknown field. Expected either :data or :rel8ns."
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
