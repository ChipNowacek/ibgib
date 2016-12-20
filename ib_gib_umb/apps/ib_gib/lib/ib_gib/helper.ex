defmodule IbGib.Helper do
  @moduledoc """
  This module provides helper functions used throughout `ib_gib`, and other
  consuming apps, e.g. `web_gib`.
  """

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs
  import IbGib.Macros
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
      iex> Logger.disable(self())
      ...> {result, _} = IbGib.Helper.get_ib_gib(:not_a_bitstring, "bitstring here")
      ...> Logger.enable(self())
      ...> result
      :error

      iex> Logger.disable(self())
      ...> {result, _} = IbGib.Helper.get_ib_gib("bitstring here", :not_a_bitstring)
      ...> Logger.enable(self())
      ...> result
      :error
  """
  @spec get_ib_gib(String.t, String.t) :: {:ok, String.t} | {:error, String.t}
  def get_ib_gib(ib, gib)
    when is_bitstring(ib) and bit_size(ib) > 0 and
         is_bitstring(gib) and bit_size(gib) > 0 do
    {:ok, ib <> "#{@delim}" <> gib}
  end
  def get_ib_gib(ib, gib) do
    error_msg = "ib and gib are not both bitstrings with length > 0. ib: #{inspect ib}. gib: #{inspect gib}"
    _ = Logger.error error_msg
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
      iex> Logger.disable(self())
      ...> {result, _} = IbGib.Helper.separate_ib_gib(:not_a_bitstring)
      ...> Logger.enable(self())
      ...> result
      :error
  """
  @spec separate_ib_gib(String.t) :: {:ok, {String.t, String.t}} | {:error, String.t}
  def separate_ib_gib(ib_gib)
  def separate_ib_gib(ib_gib) when is_bitstring(ib_gib) do
    as_array = String.split(ib_gib, @delim)
    {ib, gib} = {Enum.at(as_array, 0), Enum.at(as_array, 1)}
    {:ok, {ib, gib}}
  end
  def separate_ib_gib(ib_gib) do
    error_msg = "ib_gib must be a bitstring with a valid delim (#{@delim}). ib_gib: #{inspect ib_gib}"
    _ = Logger.error error_msg
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

    iex> s = <<255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 1, 0>>
    ...> IbGib.Helper.hash(s)
    "135672D7505A3BCEC8055D368E99C6EBF80174031C73763D53952743D73835BB"
  """
  @spec hash(String.t | binary) :: String.t
  def hash(s) when is_bitstring(s) or is_binary(s) do
  :sha256
    |> :crypto.hash(@hash_salt <> s)
    |> Base.encode16
  end
  def hash(_unknown_type) do
    :error
  end

  @doc """
  Determines if the given `ib` is valid.
  Only letters, digits, underscores, dashes, and spaces allowed.

  See IbGib.Constants.ib_gib.@regex_valid_ib.

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

      # This one is too long. 76 character max
      iex> IbGib.Helper.valid_ib?("12345678901234567890123456789012345678901234567890123456789012345678901234567")
      false
  """
  def valid_ib?(ib) when is_bitstring(ib) do
    ib_length = ib |> String.length

    ib_length >= @min_id_length and
      ib_length <= @max_id_length and
      Regex.match?(@regex_valid_ib, ib)
  end
  def valid_ib?(_) do
    false
  end

  @doc """
  Determines if the given `gib` is valid. Only letters, digits, underscores
  allowed.

  See IbGib.Constants.ib_gib.@regex_valid_gib.

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

      # This one is too long. 76 character max
      iex> IbGib.Helper.valid_gib?("12345678901234567890123456789012345678901234567890123456789012345678901234567")
      false
  """
  def valid_gib?(gib) when is_bitstring(gib) do
    gib_length = gib |> String.length

    gib_length >= @min_id_length and
      gib_length <= @max_id_length and
      Regex.match?(@regex_valid_gib, gib)
  end
  def valid_gib?(_) do
    false
  end


  @doc """
  Determines if the given `ib_gib` is valid.
  Only letters, digits, underscores allowed.

  See IbGib.Constants.ib_gib.@regex_valid_ib_gib.

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
      iex> IbGib.Helper.valid_ib_gib?("1234567890123456789012345678901234567890123456789012345678901234567890123456^1234567890123456789012345678901234567890123456789012345678901234567890123456")
      true

      # ib is too long. 76 character max
      iex> IbGib.Helper.valid_ib_gib?("12345678901234567890123456789012345678901234567890123456789012345678901234567^1234567890123456789012345678901234567890123456789012345678901234567890123456")
      false

      # gib is too long. 64 character max
      iex> IbGib.Helper.valid_ib_gib?("1234567890123456789012345678901234567890123456789012345678901234567890123456^12345678901234567890123456789012345678901234567890123456789012345678901234567")
      false
  """
  def valid_ib_gib?(ib_gib) when is_bitstring(ib_gib) do
    ib_gib_length = ib_gib |> String.length

    ib_gib_length >= @min_ib_gib_length and
      ib_gib_length <= @max_ib_gib_length and
      Regex.match?(@regex_valid_ib_gib, ib_gib)
  end
  def valid_ib_gib?(_) do
    false
  end

  @doc """
  Creates an "official" stamp on the given `gib`.

  ## Examples
    iex> IbGib.Helper.stamp_gib("someGIB")
    {:ok, "ibGib_someGIB_ibGib"}

    iex> {result, _emsg} = IbGib.Helper.stamp_gib("")
    ...> result
    :error
  """
  def stamp_gib(gib) when is_bitstring(gib) and gib != "" do
    {:ok, "#{@gib_stamp}_#{gib}_#{@gib_stamp}"}
  end
  def stamp_gib(unknown_arg) do
    {:error, emsg_invalid_args(unknown_arg)}
  end

  @doc """
  Bang version of `stamp_gib/1`.

  ## Examples
    iex> IbGib.Helper.stamp_gib!("someGIB")
    "ibGib_someGIB_ibGib"
  """
  def stamp_gib!(gib) when is_bitstring(gib) and gib != "" do
    bang(stamp_gib(gib))
  end

  @doc """
  Checks if a given `gib` is "officially" stamped by ibGib.

  ## Examples
    iex> IbGib.Helper.gib_stamped?("ibGib_someGIB_ibGib")
    true

    iex> IbGib.Helper.gib_stamped?("someGIB")
    false

    iex> Logger.disable(self())
    ...> result = IbGib.Helper.gib_stamped?("")
    ...> Logger.enable(self())
    ...> result
    false

    iex> Logger.disable(self())
    ...> result = IbGib.Helper.gib_stamped?(%{"not" => "a bitstring"})
    ...> Logger.enable(self())
    ...> result
    false
  """
  def gib_stamped?(gib) when is_bitstring(gib) and gib != "" do
    String.length(gib) > 12 and
    String.starts_with?(gib, @gib_stamp) and
    String.ends_with?(gib, @gib_stamp)
  end
  def gib_stamped?(gib) do
    _ = Logger.warn emsg_invalid_args(gib)
    false
  end

  def valid_identity?(@root_ib_gib) do
    true
  end
  def valid_identity?(ib_gib) do
    if valid_ib_gib?(ib_gib) do
      {_ib, gib} = separate_ib_gib!(ib_gib)
      gib_stamped?(gib)
    else
      false
    end
  end

  def validate_identity_ib_gibs(identity_ib_gibs)
    when is_list(identity_ib_gibs) do
    valid_identity_ib_gibs =
      length(identity_ib_gibs) > 0 and
      identity_ib_gibs |> Enum.all?(&(valid_ib_gib?(&1)))
    if valid_identity_ib_gibs do
      {:ok, :ok}
    else
      emsg = emsg_invalid_args(identity_ib_gibs)
      _ = Logger.error emsg
      {:error, emsg}
    end
  end
  def validate_identity_ib_gibs(identity_ib_gibs) do
    {:error, emsg_invalid_args(identity_ib_gibs)}
  end

  def default_handle_error(error) do
    case error do
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      err -> {:error, inspect err}
    end
  end


  @doc """
  IbGib uses identity claims as opposed to a single "user_id" field. So we will
  do an aggregate "user_id" hash which is generated based on the current
  identities.

  ## Examples

    One string
      iex> identity_ib_gibs = ["a"]
      ...> {result, _hash} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs)
      ...> result
      :ok

    Two strings
      iex> identity_ib_gibs = ["a", "b"]
      ...> {result, _hash} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs)
      ...> result
      :ok

    One email identity string
      iex> identity_ib_gibs = ["email_a"]
      ...> {result, _hash} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs)
      ...> result
      :ok

    One email identity string with other non-email string
      iex> identity_ib_gibs = ["email_a", "b"]
      ...> {result, _hash} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs)
      ...> result
      :ok

    Same email with other non-email ids should generate same hash
      iex> identity_ib_gibs1 = ["email_a", "session_123"]
      ...> identity_ib_gibs2 = ["email_a", "session_456"]
      ...> {:ok, hash1} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs1)
      ...> {:ok, hash2} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs2)
      ...> hash1 === hash2
      true

    To ensure we have consistent hashing (sha256 internals shouldn't change!)
      iex> identity_ib_gibs = ["email_a", "email_b", "session_123"]
      ...> {result, hash} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs)
      ...> {result, hash}
      {:ok, "1174A7BAB4B6A811E8B345DAC5FD50201FD7904362C873D94125F2BAEB75E309"}

    Can't be nil
      iex> identity_ib_gibs = nil
      ...> Logger.disable(self())
      ...> {result, _reason} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs)
      ...> Logger.enable(self())
      ...> result
      :error

    Can't be empty list
      iex> identity_ib_gibs = []
      ...> Logger.disable(self())
      ...> {result, _reason} = IbGib.Helper.get_aggregate_id_hash(identity_ib_gibs)
      ...> Logger.enable(self())
      ...> result
      :error
  """
  def get_aggregate_id_hash(identity_ib_gibs)
  def get_aggregate_id_hash(identity_ib_gibs)
    when is_list(identity_ib_gibs) and
         length(identity_ib_gibs) > 0 do

    email_identity_ib_gibs =
      Enum.filter(identity_ib_gibs, &(String.starts_with?(&1, "email")))

    src_identities =
      if Enum.count(email_identity_ib_gibs) > 0 do
        email_identity_ib_gibs
      else
        identity_ib_gibs
      end

    agg_hash =
      src_identities
      |> Enum.sort()
      |> Enum.reduce("", fn(identity_ib_gib, acc) -> acc <> identity_ib_gib end)
      |> hash()

    {:ok, agg_hash}
  end
  def get_aggregate_id_hash(unknown_arg) do
    emsg = "#{emsg_invalid_identity_ib_gibs()} #{emsg_invalid_args([unknown_arg])}"
    _ = Logger.error(emsg)
    {:error, emsg}
  end

  @doc """
  From [Back to the Future II on IMDB](http://www.imdb.com/title/tt0096874/quotes?item=qt0426637)
  > Marty McFly: That's right, Doc. November 12, 1955.
  > Doc: Unbelievable, that old Biff could have chosen that particular date. It could mean that that point in time inherently contains some sort of cosmic significance. Almost as if it were the temporal junction point for the entire space-time continuum. On the other hand, it could just be an amazing coincidence.

  This returns the first (non-root) ib^gib in the given `ib_gib`'s past.
  This seems to be a useful thing, defining the start of a timeline, i.e. the
  ib_gib's "birthday".

  Think of child records/tables in a relational database. These records are
  joined to the parent record via the parent's id/seq value. Well this id/seq
  value is like the "initial" id/seq value in that record's existence. But with
  relational databases, there is not a "complete" history kept throughout the
  lifetime of the thing unless there is an audit trail. If there _is_ an audit
  trail, then those audit id/seq values are somewhat like the ib^gib pointers.

  So the initial id/seq still ends up being the starting point - the
  "temporal junction point" where you have to travel back to in order to
  reference the entire timeline.

  ## Use Case

  I'm creating this specifically for "implied" ibGib rel8ns, which are 1-way
  rel8ns that are rel8d _to_ an ibGib but are not directly rel8d _on_ an ibGib.
  So I'm going to "tag" the ibGib at the precise ib^gib pointer in time where
  the comment occurs, **as well as tagging the temporal junction point**. This
  way, when I go to look up "Hey, give me the implied ibGibs related to some
  given ibGib", I know to look at the temporal junction point instead of
  searching for any possible ib^gib in its "past". (Yes, I have actually been
  coding this entire "past" querying and it is ludicrously ugly.)
  """
  def get_temporal_junction(ib_gib)
  def get_temporal_junction(ib_gib_pid) when is_pid(ib_gib_pid) do
    case IbGib.Expression.get_info(ib_gib_pid) do
      {:ok, info} -> get_temporal_junction(info)
      error -> default_handle_error(error)
    end
  end
  def get_temporal_junction(ib_gib_info) when is_map(ib_gib_info) do
    past = ib_gib_info[:rel8ns]["past"]
    if Enum.count(past) > 1 do
      # position 0 is root, position 1 is the temporal junction
      {:ok, Enum.at(past, 1)}
    else
      # There is no past, so the given `ib_gib_info` itself _is_ the temporal
      # junction. So get the info's ib^gib
      get_ib_gib(ib_gib_info)
    end
  end
  def get_temporal_junction(ib_gib) do
    invalid_args(ib_gib)
  end
end
