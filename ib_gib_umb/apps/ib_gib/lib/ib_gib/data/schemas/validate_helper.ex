defmodule IbGib.Data.Schemas.ValidateHelper do
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  # @doc """
  # I'm not sure about the implementation here. I know I made these to make
  # sure that the thing being passed in was an array of strings, and that
  # the strings were valid id strings.
  # """
  # def id_array(field, src)
  # def id_array(field, src) when is_list(src) and length(src) === 0 do
  #   # empty array is valid
  #   []
  # end
  # def id_array(field, src) when is_list(src) do
  #   # Already assumed that it is list of strings per schema declaration
  #   has_invalid_length = Enum.any?(src, fn id ->
  #     len = String.length(id)
  #     len < min_id_length or len > max_id_length
  #   end)
  #
  #   cond do
  #     has_invalid_length -> [{field, invalid_id_length_msg}]
  #     true -> []
  #   end
  # end
  # def id_array(field, src) do
  #   [{field, invalid_unknown_msg}]
  # end

  @doc """
  Is the src being passed in a non-empty map that contains key/values where the
  key is a string and the value is an array of valid ib_gib.

  E.g. %{"history" => ["ib^gib"]}

  Returns true if it's a map of valid
  """
  def map_of_ib_gib_arrays?(_field, src)
    when is_map(src) and map_size(src) > 0 do
    src
    |> Enum.all?(
      fn(item) ->
        Logger.debug "item: #{inspect item}"
        {key, value} = item

        # Logger.debug "key: #{inspect key}\nvalue: #{inspect value}"
        # Logger.debug "is_list(value): #{is_list(value)}"

        is_bitstring(key) and
        String.length(key) > 0 and
        is_list(value) and
        Enum.count(value) > 0 and
        value |> Enum.all?(&(valid_ib_gib?(&1)))
      end)
  end
  def map_of_ib_gib_arrays?(_field, _src) do
    false
  end

  @doc """
  Is the src being passed in a non-empty map that contains key/values where the
  key is a string and the value is an array of valid ib_gib.

  E.g. %{"history" => ["ib^gib"]}

  Returns true if it's a map of valid
  """
  def valid_data?(_field, src, max_size \\ max_data_size)
  def valid_data?(_field, src, max_size)
    when is_map(src) and map_size(src) > 0 do

      # Going to reduce the enumerable to avoid going through multiple times.
      # -1 returned means not valid. Anything positive will be the size.

    valid = 0 <
      src
      |> Enum.reduce_while(0,
        fn(item, acc) ->
          Logger.debug "item: #{inspect item}"
          {key, value} = item

          # Logger.debug "key: #{inspect key}\nvalue: #{inspect value}"
          # Logger.debug "is_list(value): #{is_list(value)}"
          if (is_bitstring(key) and (is_bitstring(value) or is_nil(value))) do
            key_length = key |> String.length

            key_valid? =
              is_bitstring(key) and key_length > 0 and key_length <= max_id_length

            if (key_valid?) do
              value_valid? =
                if is_nil(value) do
                  {:cont, acc + key_length}
                else
                  value_length = value |> String.length
                  running_size = acc + key_length + value_length
                  if (running_size <= max_size) do
                    Logger.debug "running_size: #{running_size}, max_size: #{max_size}"
                    {:cont, running_size}
                  else
                    # not valid - too big
                    {:halt, -1}
                  end
                end
            else
              # not valid
              {:halt, -1}
            end
          else
            # key and value must be bitstrings, or value can be nil
            # not valid
            {:halt, -1}
          end
        end)
  end
  def valid_data?(_field, src, max_size)
    when is_map(src) and map_size(src) === 0 do
    Logger.debug "empty map"
    true
  end
  def valid_data?(_field, src, max_size) when src === nil do
    Logger.debug "nil map"
    true
  end
  def valid_data?(_field, _src, max_size) do
    Logger.debug "other"
    false
  end

  def valid_ib_gib?(ib_gib) when is_bitstring(ib_gib) do
    # This whole function is not optimized and NEEDS to be, because we're
    # going to be doing a LOT of ib_gib validating.
    # Right now however, I'm writing this to be clear.

    # 1. Setup our return logical `and` operation.

    ib_gib_length = ib_gib |> String.length
    has_delim = ib_gib |> String.contains?(delim)
    array = ib_gib |> String.split(delim)
    array_length = array |> length
    ib = array |> Enum.at(0, "")
    ib_length = ib |> String.length
    gib = array |> Enum.at(1, "")
    gib_length = gib |> String.length

    # 2. Return a single shortcut logical `and` operation.

    # valid ib_gib length
    ib_gib_length >= min_ib_gib_length && ib_gib_length <= max_ib_gib_length and
    # ib_gib has a single delimiter between two strings
    has_delim && array_length === 2 and
    # valid individual ib and gib lengths
    ib_length >= min_id_length && ib_length <= max_id_length and
    gib_length >= min_id_length && gib_length <= max_id_length
  end
  def valid_ib_gib?(ib_gib) do
    false
  end

  def invalid_id_length_msg, do: emsg_invalid_id_length
  def invalid_unknown_msg, do: emsg_invalid_unknown_src_maybe

  def do_validate_change(field, src) do
    case field do
      :rel8ns ->
        if map_of_ib_gib_arrays?(field, src) do
          []
        else
          [rel8ns: emsg_invalid_relations]
        end
      :data ->
        if valid_data?(field, src) do
          []
        else
          [data: emsg_invalid_data]
        end
      _ -> Logger.error emsg_unknown_field
    end
  end
end
