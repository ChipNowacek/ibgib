defmodule IbGib.Constants do
  @moduledoc """
  This module contains constants used in various aspects throughout the
  applications. Each function is a scope of constants and contains instructions
  for consuming the constants in a module.
  """

  @doc """
  Use this with `use IbGib.Constants, :ib_gib`
  """
  def ib_gib do
    # defmacro delim do
    #   quote do: "^"
    # end
    quote do
      # if change, must also change in regex below
      @delim "^"
      @root_ib_gib "ib#{@delim}gib"

      defp delim, do: "^"
      defp min_id_length, do: 1
      defp max_id_length, do: 76
      defp min_ib_gib_length, do: 3 # min + delim + min
      defp max_ib_gib_length, do: 153 # max + delim + max
      defp max_data_size, do: 10_240_000 # 10 MB max internal data
      # one or more word chars, underscore, dash
      defp regex_valid_ib, do: ~r/^[\w\d_-\s]+$/
      defp regex_valid_gib, do: ~r/^[\w\d]+$/
      # delim hardcoded in!!!!
      defp regex_valid_ib_gib, do: ~r/^[\w\d_-\s]+\^[\w\d]+$/

      defp default_dna, do: ["ib#{delim}gib"]
      defp default_past, do: ["ib#{delim}gib"]

      # This "stamp" added to gib means that we have generated the ib_gib,
      # and not a user.
      @gib_stamp "ibGib"

      # This key prefix is a helper that indicates some meta action for the
      # corresponding key/value entry in a map.
      #
      # ATOW: 2016/08/10
      # Use case for this is that I want to be able to delete/edit an existing
      # key via a mut8. So if an ib_gib's data has `"a" => "a value"` and I want
      # to delete that key/value pair.
      defp map_key_meta_prefix, do: "meta__"
      defp rename_operator, do: ">rename>"
    end
  end

  def transforms do
    quote do
      @default_transform_options %{:gib_stamp => false}
    end
  end

  @doc """
  Use this with `use IbGib.Constants, :error_msgs`
  """
  def error_msgs do
    quote do
      defp emsg_invalid_relations do
        "Something about the rel8ns is invalid. :-/"
      end

      defp emsg_invalid_data do
        "Something about the data is invalid. :-O"
      end

      defp emsg_invalid_id_length do
        "invalid id length"
      end

      defp emsg_invalid_unknown_src_maybe do
        "invalid. unknown src maybe, maybe not an array of string"
      end

      defp emsg_invalid_data_value(value) do
        "invalid data value: #{inspect value}"
      end

      defp emsg_unknown_field do
        "Unknown field. Expected either :data or :rel8ns."
      end

      defp emsg_hash_problem do
        "There was a problem hashing the given value."
      end

      defp emsg_invalid_arg(arg) do
        "Invalid argument: #{inspect arg}"
      end

      defp emsg_invalid_args(args) do
        "Invalid argument: #{inspect args}"
      end

      defp emsg_query_result_count(count) do
        "Unexpected query result count: #{count}"
      end
    end
  end

  # def query do
  #   quote do
  #     def ib_search_methods, do: @ib_search_methods
  #   end
  # end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
