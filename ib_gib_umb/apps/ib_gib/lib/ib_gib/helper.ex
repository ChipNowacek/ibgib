defmodule IbGib.Helper do
  @moduledoc """
  This module provides helper functions used throughout `ib_gib`, and other
  consuming apps, e.g. `web_gib`.
  """

  use IbGib.Constants, :ib_gib
  require Logger
  @hash_salt "ib_gib_salt_whaa"

  @doc """
  Extracts the `:ib` and `:gib` from `info` and combines them to form the
  `ib_gib`.

  See `get_ib_gib/2` for more info.

  ## Examples
      iex> info = %{ib: "ib", gib: "gib", rel8ns: %{}, data: %{}}
      ...> IbGib.Helper.get_ib_gib(info)
      {:ok, "ib^gib"}
  """
  def get_ib_gib(info) when is_map(info) do
    get_ib_gib(info[:ib], info[:gib])
  end

  @doc """
  Bang version of `get_ib_gib/1`.

  See `get_ib_gib/2` for more info.

  ## Examples
      iex> info = %{ib: "ib", gib: "gib", rel8ns: %{}, data: %{}}
      ...> IbGib.Helper.get_ib_gib!(info)
      "ib^gib"
  """
  def get_ib_gib!(info) when is_map(info) do
    get_ib_gib!(info[:ib], info[:gib])
  end

  @doc """
  Combines the two given strings `ib` and `gib` using the `delim/0` constant
  in `IbGib.Constants.ib_gib` to form the `ib_gib` identifier.

  The following examples have the delim hard-coded :X

  ## Examples
      iex> IbGib.Helper.get_ib_gib("ib", "gib")
      {:ok, "ib^gib"}

      iex> IbGib.Helper.get_ib_gib("some id", "some hash ABCDEFGHI123")
      {:ok, "some id^some hash ABCDEFGHI123"}

      # Disable logging for these error doctests.
      iex> Logger.disable(self)
      ...> {result, _} = IbGib.Helper.get_ib_gib(:not_a_bitstring, "bitstring here")
      ...> Logger.enable(self)
      ...> result
      :error

      iex> Logger.disable(self)
      ...> {result, _} = IbGib.Helper.get_ib_gib("bitstring here", :not_a_bitstring)
      ...> Logger.enable(self)
      ...> result
      :error
  """
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

  @doc """
  Bang version of `get_ib_gib/2`.

  ## Examples
      iex> IbGib.Helper.get_ib_gib!("ib", "gib")
      "ib^gib"

      iex> IbGib.Helper.get_ib_gib!("some id", "some hash ABCDEFGHI123")
      "some id^some hash ABCDEFGHI123"
  """
  @spec get_ib_gib!(String.t, String.t) :: String.t
  def get_ib_gib!(ib, gib) do
    case get_ib_gib(ib, gib) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Separates a given `ib_gib` into its component `ib` and `gib` bitstrings.


  ## Examples
      iex> IbGib.Helper.separate_ib_gib("ib^gib")
      {:ok, {"ib", "gib"}}

      iex> IbGib.Helper.separate_ib_gib("some id^some hash ABCDEFGHI123")
      {:ok, {"some id", "some hash ABCDEFGHI123"}}

      # Disable logging for these error doctests.
      iex> Logger.disable(self)
      ...> {result, _} = IbGib.Helper.separate_ib_gib(:not_a_bitstring)
      ...> Logger.enable(self)
      ...> result
      :error
  """
  @spec separate_ib_gib(String.t) :: {:ok, {String.t, String.t}} | {:error, String.t}
  def separate_ib_gib(ib_gib)
  def separate_ib_gib(ib_gib) when is_bitstring(ib_gib) do
    as_array = String.split(ib_gib, delim)
    {ib, gib} = {Enum.at(as_array, 0), Enum.at(as_array, 1)}
    {:ok, {ib, gib}}
  end
  def separate_ib_gib(ib_gib) do
    error_msg = "ib_gib must be a bitstring with a valid delim (#{delim}). ib_gib: #{inspect ib_gib}"
    Logger.error error_msg
    {:error, error_msg}
  end

  @doc """
  Bang version of `separate_ib_gib/1`.

  ## Examples
      iex> IbGib.Helper.separate_ib_gib!("ib^gib")
      {"ib", "gib"}

      iex> IbGib.Helper.separate_ib_gib!("some id^some hash ABCDEFGHI123")
      {"some id", "some hash ABCDEFGHI123"}
  """
  @spec separate_ib_gib!(String.t) :: {String.t, String.t}
  def separate_ib_gib!(ib_gib) when is_bitstring(ib_gib) do
    case separate_ib_gib(ib_gib) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Creates a new id string. This is not a properly formatted UUID. It is just
  a string of random-ish letters.

  It's not strictly necessary that the same algorithm is used across the entire
  ib_gib system for this. This is more of a convenience helper than an
  enforcer of consistency.
  """
  @spec new_id() :: String.t
  def new_id() do
    RandomGib.Get.some_letters(30)
  end

  @doc """
  Creates a hash based on the given `ib`, `relations`, and `data`.

  ## Examples
      iex> IbGib.Helper.hash("abc", %{"ancestor" => ["ib^gib"]}, %{"key" => "value"})
      "5B3EE06BCC9E68339B7AC6460D805FF6F110DA572F2590D2C1A395D7C1E2DA1D"

      iex> IbGib.Helper.hash("abc", %{"ancestor" => ["ib^gib"]}, %{})
      "9A566CD4F57FBEA31DC3F8DFA1771EDD83C1139AB15008E32DCBB6D93538CE8A"
  """
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
  # def hash(ib, ib_gib_dna, data \\ %{}) when
  #     is_bitstring(ib) and
  #     is_list(ib_gib_dna) and
  #     is_map(data) do
  #   ib_hash = hash(ib)
  #   dna_hash = hash(ib_gib_dna)
  #   data_hash = hash(data)
  #
  #   hash(ib_hash <> dna_hash <> data_hash)
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

    iex> IbGib.Helper.hash(%{"a" => "a here", "b" => "b here too"})
    "0AB8246B11E174B2A4A65F0D8AA50BB4CDF712C48BD8C532F57D1703F3404F33"

  """
  def hash(something)
  @spec hash(map) :: String.t
  def hash(map) when is_map(map) do
    {:ok, json} = Poison.encode(map)
    hash(json)
  end
  @doc ~S"""
   Encodes `s` into json and then creates a unique hash.

  ## Examples

    iex> IbGib.Helper.hash("oijwfensdfjoIEFas283e7NISWEFJOIwe98wefj")
    "E3F6683D94E3FDD2222055BE047FC80CADAD3BA775B5CC3A7AEC6427850D4F54"

  """
  @spec hash(String.t) :: String.t
  def hash(s) when is_bitstring(s) do
    :crypto.hash(:sha256, @hash_salt <> s) |> Base.encode16
  end
  def hash(_unknown_type) do
    :error
  end

  @doc """
  Determines if the given `ib` is valid.
  Only letters, digits, underscores, dashes, and spaces allowed.

  See IbGib.Constants.ib_gib.regex_valid_ib.

  ## Examples
      iex> IbGib.Helper.valid_ib?("ib")
      true

      iex> IbGib.Helper.valid_ib?("only letters and spaces")
      true

      iex> IbGib.Helper.valid_ib?("12345")
      true

      iex> IbGib.Helper.valid_ib?("letters numbers _underscores_ -dashes- spaces allowed")
      true

      iex> IbGib.Helper.valid_ib?("")
      false

      # This one is too long. 64 character max
      iex> IbGib.Helper.valid_ib?("12345678901234567890123456789012345678901234567890123456789012345")
      false
  """
  def valid_ib?(ib) when is_bitstring(ib) do
    ib_length = ib |> String.length

    ib_length >= min_id_length and
      ib_length <= max_id_length and
      Regex.match?(regex_valid_ib, ib)
  end
  def valid_ib?(_) do
    false
  end

  @doc """
  Determines if the given `gib` is valid. Only letters, digits, underscores
  allowed.

  See IbGib.Constants.ib_gib.regex_valid_gib.

  ## Examples
      iex> IbGib.Helper.valid_gib?("gib")
      true

      iex> IbGib.Helper.valid_gib?("lettersANDnumbersONLY12345inGIB")
      true

      iex> IbGib.Helper.valid_gib?("12345")
      true

      iex> IbGib.Helper.valid_gib?("underscores_allowed_in_gib")
      true

      iex> IbGib.Helper.valid_gib?("dashes-not-allowed-in-gib")
      false

      iex> IbGib.Helper.valid_gib?("")
      false

      # This one is too long. 64 character max
      iex> IbGib.Helper.valid_gib?("12345678901234567890123456789012345678901234567890123456789012345")
      false
  """
  def valid_gib?(gib) when is_bitstring(gib) do
    gib_length = gib |> String.length

    gib_length >= min_id_length and
      gib_length <= max_id_length and
      Regex.match?(regex_valid_gib, gib)
  end
  def valid_gib?(_) do
    false
  end


  @doc """
  Determines if the given `ib_gib` is valid.
  Only letters, digits, underscores allowed.

  See IbGib.Constants.ib_gib.regex_valid_ib_gib.

  ## Examples
      iex> IbGib.Helper.valid_ib_gib?("ib^gib")
      true

      iex> IbGib.Helper.valid_ib_gib?("letters digits _underscores_ -dashes- spaces^lettersANDnumbersONLY12345inGIB")
      true

      iex> IbGib.Helper.valid_ib_gib?("12345^12345")
      true

      iex> IbGib.Helper.valid_gib?("underscores_allowed_in_gib")
      true

      iex> IbGib.Helper.valid_ib_gib?("letters digits _underscores_ -dashes- spaces^invalid gib with spaces")
      false

      iex> IbGib.Helper.valid_ib_gib?("letters digits _underscores_ -dashes- spaces^invalid-gib-with-dashes")
      false

      iex> IbGib.Helper.valid_ib_gib?("letters digits _underscores_ -dashes- spaces^invalidGIBwithSpecial&!@")
      false

      # max valid length
      iex> IbGib.Helper.valid_ib_gib?("1234567890123456789012345678901234567890123456789012345678901234^1234567890123456789012345678901234567890123456789012345678901234")
      true

      # ib is too long. 64 character max
      iex> IbGib.Helper.valid_ib_gib?("12345678901234567890123456789012345678901234567890123456789012345^1234567890123456789012345678901234567890123456789012345678901234")
      false

      # gib is too long. 64 character max
      iex> IbGib.Helper.valid_ib_gib?("1234567890123456789012345678901234567890123456789012345678901234^12345678901234567890123456789012345678901234567890123456789012345")
      false
  """
  def valid_ib_gib?(ib_gib) when is_bitstring(ib_gib) do
    ib_gib_length = ib_gib |> String.length

    ib_gib_length >= min_ib_gib_length and
      ib_gib_length <= max_ib_gib_length and
      Regex.match?(regex_valid_ib_gib, ib_gib)
  end
  def valid_ib_gib?(_) do
    false
  end

end
