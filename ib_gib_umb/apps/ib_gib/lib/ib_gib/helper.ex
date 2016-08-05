defmodule IbGib.Helper do
  use IbGib.Constants, :ib_gib
  require Logger

  @spec get_ib_gib(String.t, String.t) :: {:ok, String.t} | {:error, String.t}
  def get_ib_gib(ib, gib)
    when is_bitstring(ib) and bit_size(ib) > 0 and
         is_bitstring(gib) and bit_size(gib) > 0 do
    {:ok, ib <> "#{delim}" <> gib}
  end
  def get_ib_gib(ib, gib) do
    error_msg = "ib and gib are not both bitstrings with length > 0. ib: #{inspect ib}. gib: #{inspect gib}"
    Logger.error error_msg
    {:error, error_msg}
  end

  @spec get_ib_gib!(String.t, String.t) :: String.t
  def get_ib_gib!(ib, gib) do
    case get_ib_gib(ib, gib) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  @spec new_id() :: String.t
  def new_id() do
    RandomGib.Get.some_letters(30)
  end


  @spec hash(String.t, map, map) :: String.t
  def hash(ib, relations, data \\ %{}) when
      is_bitstring(ib) and
      is_map(relations) and
      is_map(data) do
    ib_hash = hash(ib)
    relations_hash = hash(relations)
    data_hash = hash(data)

    hash(ib_hash <> relations_hash <> data_hash)
  end

  # @spec hash(String.t, list(String.t), map) :: String.t
  # def hash(ib, ib_gib_history, data \\ %{}) when
  #     is_bitstring(ib) and
  #     is_list(ib_gib_history) and
  #     is_map(data) do
  #   ib_hash = hash(ib)
  #   history_hash = hash(ib_gib_history)
  #   data_hash = hash(data)
  #
  #   hash(ib_hash <> history_hash <> data_hash)
  # end


  # @spec hash(list(String.t)) :: String.t
  # def hash(list) when is_list(list) do
  #   [head | tail] = list
  #   aggregate = List.foldl(tail, head, fn(x, acc) -> acc <> "," <> x end)
  #   hash(aggregate)
  # end
  @doc ~S"""
   Encodes `map` into json and then creates a unique hash.

  ## Examples

    iex> IbGib.TransformFactory.hash(%{"a" => "a here", "b" => "b here too"})
    "0AB8246B11E174B2A4A65F0D8AA50BB4CDF712C48BD8C532F57D1703F3404F33"

  """
  @spec hash(map) :: String.t
  def hash(map) when is_map(map) do
    {:ok, json} = Poison.encode(map)
    hash(json)
  end
  @doc ~S"""
   Encodes `s` into json and then creates a unique hash.

  ## Examples

    iex> IbGib.TransformFactory.hash("oijwfensdfjoIEFas283e7NISWEFJOIwe98wefj")
    "9BDE0A867929A62CA07A4BB5CC21F8E5BBBE388BA477B0E5FCB4B9B74294268F"

  """
  @spec hash(String.t) :: String.t
  def hash(s) when is_bitstring(s) do
    :crypto.hash(:sha256, s) |> Base.encode16
  end

  def valid_ib?(ib) when is_bitstring(ib) do
    ib_length = ib |> String.length

    ib_length >= min_id_length and
      ib_length <= max_id_length and
      Regex.match?(regex_valid_ib, ib)
  end
  def valid_ib?(ib) do
    false
  end

  def valid_gib?(gib) when is_bitstring(gib) do
    gib_length = gib |> String.length

    gib_length >= min_id_length and
      gib_length <= max_id_length and
      Regex.match?(regex_valid_gib, gib)
  end
  def valid_gib?(gib) do
    false
  end

  def valid_ib_gib?(ib_gib) when is_bitstring(ib_gib) do
    ib_gib_length = ib_gib |> String.length

    ib_gib_length >= min_ib_gib_length and
      ib_gib_length <= max_ib_gib_length and
      Regex.match?(regex_valid_ib_gib, ib_gib)
  end
  def valid_ib_gib?(ib_gib) do
    false
  end

end
