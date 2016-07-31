defmodule IbGib.Data.Schemas.ValidateHelper do
  alias Enum

  @invalid_id_length_msg "invalid id length"
  @invalid_unknown_msg "invalid. unknown src maybe, maybe not an array of string"
  @min 1
  @max 64

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
  Is the src being passed in a map that contains key/values where the key is a
  string and the value is an array of valid ib_gib.

  E.g. %{"history" => ["ib^gib"]}

  Returns true if it's a map of valid
  """
  def map_of_ib_gib_arrays?(_field, src) when is_map(src) do
    # leaving off here.
  end
  def map_of_ib_gib_arrays?(_field, _src) do
    false
  end


  def invalid_id_length_msg, do: @invalid_id_length_msg
  def invalid_unknown_msg, do: @invalid_unknown_msg
end
