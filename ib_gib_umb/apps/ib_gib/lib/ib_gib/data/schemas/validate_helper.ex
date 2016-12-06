defmodule IbGib.Data.Schemas.ValidateHelper do
  @moduledoc """
  These are helper functions used in validating the
  `IbGib.Data.Schemas.IbGibModel`.
  """
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  import IbGib.Macros

  @doc """
  Is the src being passed in a non-empty map that contains key/values where the
  key is a string and the value is an array of valid ib_gib.

  ## Examples
      iex> test = %{"dna" => ["ib^gib", "fork^gib"]}
      ...> IbGib.Data.Schemas.ValidateHelper.map_of_ib_gib_arrays?(:some_field, test)
      true

      iex> test = %{:not_a_string => ["ib^gib", "fork^gib"]}
      ...> IbGib.Data.Schemas.ValidateHelper.map_of_ib_gib_arrays?(:some_field, test)
      false

      iex> test = %{"dna" => "not an array of ib^gib"}
      ...> IbGib.Data.Schemas.ValidateHelper.map_of_ib_gib_arrays?(:some_field, test)
      false

  Returns true if it's a map of valid ib^gib arrays.
  """
  def map_of_ib_gib_arrays?(_field, src)
    when is_map(src) and map_size(src) > 0 do
    src
    |> Enum.all?(
      fn({key, value}) ->
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

  E.g. %{"dna" => ["ib^gib"]}

  Returns true if it's a map of valid
  """
  def valid_data?(_field, src, max_size \\ @max_data_size)
  def valid_data?(_field, src, max_size) when is_map(src) and map_size(src) > 0 do
    get_map_size(src, 0, max_size) !== -1
  end
  def valid_data?(_field, src, _max_size)
    when is_map(src) and map_size(src) === 0 do
    _ = Logger.debug "empty map"
    true
  end
  def valid_data?(_field, src, _max_size) when is_nil(src) do
    _ = Logger.debug "nil map"
    true
  end
  def valid_data?(_field, _src, _max_size) do
    _ = Logger.debug "other"
    false
  end

  @doc """
  Get an approximate byte size of a given map `m`.

  Warning: Ugliness.

  Returns -1 if running_size exceeds max_size at any point.
  """
  def get_map_size(m, running_size \\ 0, max_size \\ @max_data_size)
    when is_map(m) and is_integer(max_size) and is_integer(running_size) do
    # We're going to iterate over each item in the map. If we ever hit the
    # max size, then we're going to abort immediately and return -1.
    m
    |> Enum.reduce_while(running_size,
      fn(item, acc) ->
        # _ = Logger.debug "item: #{inspect item}"
        {key, value} = item

        # _ = Logger.debug "key: #{inspect key}\nvalue: #{inspect value}"
        # _ = Logger.debug "is_list(value): #{is_list(value)}"
        if is_bitstring(key) do
          key_length = key |> String.length

          key_valid? =
            is_bitstring(key) and key_length > 0 and key_length <= @max_id_length

          if key_valid? do
            cond do
              is_nil(value) ->
                # add the key_length to the acc and continue
                {:cont, acc + key_length}

              is_bitstring(value) ->
                # Add the key_length and value_length to the acc
                # then check to see if we've gotten too big for our britches.
                value_length = value |> String.length
                new_running_size = acc + key_length + value_length
                if new_running_size <= max_size do
                  _ = Logger.debug "new_running_size: #{new_running_size}, max_size: #{max_size}"
                  {:cont, new_running_size}
                else
                  # not valid - too big
                  {:halt, -1}
                end

              is_map(value) ->
                # Call the get_map_size recursively, passing in our current
                # acc value as the starting point.
                new_running_size = get_map_size(value, acc + key_length, max_size)
                if new_running_size === -1 do
                  # Internal map has put us over the top
                  {:halt, -1}
                else
                  {:cont, new_running_size}
                end

              is_list(value) ->
                new_running_size =
                  Enum.reduce_while(value, acc + key_length, fn(list_item, list_acc) ->
                    # Must be a list of bitstrings or maps
                    cond do
                      is_nil(list_item) ->
                        {:cont, list_acc}
                      is_bitstring(list_item) ->
                        {:cont, list_acc + String.length(list_item)}
                      is_map(list_item) ->
                        # call recursively with our list_acc running_size
                        {:cont, get_map_size(list_item, list_acc, max_size)}
                      true ->
                        {:halt, -1}
                    end
                  end)
                  if new_running_size === -1 do
                    # Internal map has put us over the top
                    {:halt, -1}
                  else
                    {:cont, new_running_size}
                  end

              true ->
                # not valid - value is not a map, string, or nil
                _ = Logger.warn "invalid value. Is not a map, string, or nil. value: #{inspect value}"
                {:halt, -1}
            end
          else
            # key invalid
            _ = Logger.warn "invalid key: #{inspect key, [pretty: true]}"
            # not valid
            {:halt, -1}
          end
        else
          # key must be a bitstring, and value must be bitstring, map, or nil
          # not valid
          {:halt, -1}
        end
      end)

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
    ib_gib_length >= @min_ib_gib_length && ib_gib_length <= @max_ib_gib_length and
    # ib_gib has a single delimiter between two strings
    has_delim && array_length === 2 and
    # valid individual ib and gib lengths
    ib_length >= @min_id_length && ib_length <= @max_id_length and
    gib_length >= @min_id_length && gib_length <= @max_id_length
  end
  def valid_ib_gib?(_) do
    false
  end

  def invalid_id_length_msg, do: emsg_invalid_id_length()
  def invalid_unknown_msg, do: emsg_invalid_unknown_src_maybe()

  def do_validate_change(:rel8ns, src) do
    if map_of_ib_gib_arrays?(:rel8ns, src) do
      []
    else
      [rel8ns: emsg_invalid_relations()]
    end
  end
  def do_validate_change(:data, src) do
    if valid_data?(:data, src) do
      []
    else
      _ = Logger.error "whaaa. src: #{inspect src, [pretty: true]}"
      [data: emsg_invalid_data()]
    end
  end
  def do_validate_change(field, src) do
    invalid_args([field, src])
  end
end
