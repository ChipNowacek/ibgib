defmodule IbGib.Helper do
  @spec get_ib_gib(String.t, String.t) :: {:ok, String.t} | {:error, String.t}
  def get_ib_gib(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    {:ok, ib <> "|" <> gib}
  end
  def get_ib_gib(ib, gib) do
    {:error, "ib and gib are not both bitstrings."}
  end

  @spec get_ib_gib(String.t, String.t) :: String.t
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

end
