defmodule IbGib.Data.Schemas.ValidateHelper do
  require Logger

  @invalid_id_length_msg "invalid id length"
  @invalid_unknown_msg "invalid. unknown src maybe, maybe not an array of string"
  @min 1
  @max 64
  @min_ib_gib (@min*2)+1 # 3
  @max_ib_gib (@max*2)+1 # 129
  @delim "^"

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
  #     len < @min or len > @max
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

        Logger.debug "key: #{inspect key}\nvalue: #{inspect value}"
        Logger.debug "is_list(value): #{is_list(value)}"

        # so_far =
          is_bitstring(key) and
          String.length(key) > 0 and
          is_list(value) and
          Enum.count(value) > 0 and
          value |> Enum.all?(&(valid_ib_gib?(&1)))

        # if so_far do
        #   value |> Enum.all?(&(valid_ib_gib?(&1)))
        # else
        #   Logger.debug "nope"
        #   false
        # end
      end)
  end
  def map_of_ib_gib_arrays?(_field, _src) do
    false
  end

  def valid_ib_gib?(ib_gib) when is_bitstring(ib_gib) do
    # This whole function is not optimized and NEEDS to be, because we're
    # going to be doing a LOT of ib_gib validating.
    # Right now however, I'm writing this to be clear.

    # 1. Setup our return logical `and` operation.

    ib_gib_length = ib_gib |> String.length
    has_delim = ib_gib |> String.contains?(@delim)
    array = ib_gib |> String.split(@delim)
    array_length = array |> length
    ib = array |> Enum.at(0, "")
    ib_length = ib |> String.length
    gib = array |> Enum.at(1, "")
    gib_length = gib |> String.length

    # 2. Return a single shortcut logical `and` operation.

    # valid ib_gib length
    ib_gib_length >= @min_ib_gib && ib_gib_length <= @max_ib_gib and
    # ib_gib has a single delimiter between two strings
    has_delim && array_length === 2 and
    # valid individual ib and gib lengths
    ib_length >= @min && ib_length <= @max and
    gib_length >= @min && gib_length <= @max
  end
  def valid_ib_gib?(ib_gib) do
    false
  end

  def invalid_id_length_msg, do: @invalid_id_length_msg
  def invalid_unknown_msg, do: @invalid_unknown_msg
end
