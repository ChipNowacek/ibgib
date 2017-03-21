defmodule IbGib.Helper do
  @moduledoc """
  This module provides helper functions used throughout `ib_gib`, and other
  consuming apps, e.g. `web_gib`.
  """

  require Logger
  require OK

  import IbGib.Macros
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

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
  Determines if the given `rel8n_name` is valid.
  ATOW (2017/02/19), I'm making this the same as valid_ib?

  ## Examples
      iex> IbGib.Helper.valid_rel8n_name?("ib")
      true

      iex> IbGib.Helper.valid_rel8n_name?("only letters and spaces")
      true

      iex> IbGib.Helper.valid_rel8n_name?("12345")
      true

      iex> IbGib.Helper.valid_rel8n_name?("letters numbers _underscores_ -dashes- spaces allowed")
      true

      iex> IbGib.Helper.valid_rel8n_name?("ib^gib")
      true

      iex> IbGib.Helper.valid_rel8n_name?("tag^gib")
      true

      iex> IbGib.Helper.valid_rel8n_name?("")
      false

      # This one is too long. 76 character max
      iex> IbGib.Helper.valid_rel8n_name?("12345678901234567890123456789012345678901234567890123456789012345678901234567")
      false
  """
  def valid_rel8n_name?(rel8n_name) when is_bitstring(rel8n_name) do
    valid_ib?(rel8n_name) or valid_ib_gib?(rel8n_name)
    # length = rel8n_name |> String.length
    # 
    # length >= @min_id_length and
    #   length <= @max_id_length and
    #   Regex.match?(@regex_valid_rel8n_name, rel8n_name)
  end
  def valid_rel8n_name?(_) do
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

  This returns the first (non-root) ib^gib in the given `ib_gib`'s past, 
  ** unless the ib_gib is a blank pic, comment, or link, in which case this 
  skips the _very_ first past ibGib and returns the next **. This is because
  with these, the very first one is a "blank" with an empty data, and old
  ibGib will all share the exact same temporal junction point, which isn't 
  useful. The utility of the temporal junction point is to define the start of
  a "single" ibGib's timeline, like it's birthday.

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

  I'm creating this specifically for "adjunct" ibGib rel8ns, which are 1-way
  rel8ns that are rel8d _to_ an ibGib but are not directly rel8d _on_ an ibGib.
  So I'm going to "tag" the ibGib at the precise ib^gib pointer in time where
  the comment occurs, **as well as tagging the temporal junction point**. This
  way, when I go to look up "Hey, give me the implied ibGibs related to some
  given ibGib", I know to look at the temporal junction point instead of
  searching for any possible ib^gib in its "past". (Yes, I have actually been
  coding this entire "past" querying and it is ludicrously ugly.)
  
  ## Examples
    
    # By default, the temporal junction point is the _first_ ib^gib (a^123) in
    # the ibGib's past rel8n.
    iex> past = ["ib^gib", "a^123", "a^456"]
    ...> ancestors = ["ib^gib","A^gib"]
    ...> info = %{ib: "a", gib: "XYZ", data: %{}, rel8ns: %{"past" => past, "ancestor" => ancestors}}
    ...> Logger.disable(self())
    ...> result = IbGib.Helper.get_temporal_junction_ib_gib(info)
    ...> Logger.enable(self())
    ...> result
    {:ok, "a^123"}
  
    # Some, e.g. links, skip the first past (link^123) and return the second
    # (link^456) because the first one is a "blank".
    iex> past = ["ib^gib", "link^123", "link^456"]
    ...> ancestors = ["ib^gib","text^gib","link^gib"]
    ...> info = %{ib: "ibyo", gib: "gibyo", data: %{}, rel8ns: %{"past" => past, "ancestor" => ancestors}}
    ...> Logger.disable(self())
    ...> result = IbGib.Helper.get_temporal_junction_ib_gib(info)
    ...> Logger.enable(self())
    ...> result
    {:ok, "link^456"}

    iex> past = ["ib^gib", "pic^5349835F0D03EEC0DFC13FC8777683331E613F4977EA55E663463C97FBC3936B", "pic^D6C742A8135841E23310C980EBAB3D341FB274D45A96BDD993DC70009EA37999"]
    ...> ancestors = ["ib^gib", "binary^gib", "pic^gib"]
    ...> info = %{ib: "ibyo", gib: "gibyo", data: %{}, rel8ns: %{"past" => past, "ancestor" => ancestors}}
    ...> Logger.disable(self())
    ...> result = IbGib.Helper.get_temporal_junction_ib_gib(info)
    ...> Logger.enable(self())
    ...> result
    {:ok, "pic^D6C742A8135841E23310C980EBAB3D341FB274D45A96BDD993DC70009EA37999"}
    
    # If an ibGib has no past (only the root), then the **current** ibGib _is_
    # the temporal junction point.
    iex> past = ["ib^gib"]
    ...> ancestors = ["ib^gib","A^gib"]
    ...> info = %{ib: "a", gib: "XYZ", data: %{}, rel8ns: %{"past" => past, "ancestor" => ancestors}}
    ...> Logger.disable(self())
    ...> result = IbGib.Helper.get_temporal_junction_ib_gib(info)
    ...> Logger.enable(self())
    ...> result
    {:ok, "a^XYZ"}
  """
  def get_temporal_junction_ib_gib(ib_gib)
  def get_temporal_junction_ib_gib(ib_gib) when is_bitstring(ib_gib) do
    case IbGib.Expression.Supervisor.start_expression(ib_gib) do
      {:ok, ib_gib_pid} -> get_temporal_junction_ib_gib(ib_gib_pid)
      error -> default_handle_error(error)
    end
  end
  def get_temporal_junction_ib_gib(ib_gib_pid) when is_pid(ib_gib_pid) do
    case IbGib.Expression.get_info(ib_gib_pid) do
      {:ok, info} -> get_temporal_junction_ib_gib(info)
      error -> default_handle_error(error)
    end
  end
  def get_temporal_junction_ib_gib(ib_gib_info) when is_map(ib_gib_info) do
    with(
      {:ok, past} <- 
        get_rel8ns(ib_gib_info, "past", [error_on_not_found: true]),
      # Remove the root, since the root is never the temporal junction point
      [@root_ib_gib | past_sans_root] = past,
      
      {:ok, ancestors} <- 
        get_rel8ns(ib_gib_info, "ancestor", [error_on_not_found: true]),
      {:ok, ib_gib} <- get_ib_gib(ib_gib_info),
      
      {:ok, temp_junc_ib_gib} <- 
        (if skip_first_past?(ancestors) do
           {:ok, Enum.at(past_sans_root, 1) || 
                 Enum.at(past_sans_root, 0) || 
                 ib_gib}
         else
           {:ok, Enum.at(past_sans_root, 0) || ib_gib}
         end)
    ) do
      {:ok, temp_junc_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end
  def get_temporal_junction_ib_gib(ib_gib) do
    invalid_args(ib_gib)
  end
  
  @doc """
    If the ibGib is a comment, pic, or link, we must skip the first "blank"
    past ib_gib because this will have no data. 
    See https://github.com/ibgib/ibgib/issues/143 for details
  
    ## Examples

    iex> ancestors = ["ib^gib","text^gib","link^gib"]
    ...> IbGib.Helper.skip_first_past?(ancestors)
    true
    iex> ancestors = ["ib^gib","text^gib","pic^gib"]
    ...> IbGib.Helper.skip_first_past?(ancestors)
    true
    iex> ancestors = ["ib^gib","text^gib","comment^gib"]
    ...> IbGib.Helper.skip_first_past?(ancestors)
    true
    iex> ancestors = ["ib^gib","a^gib","b^gib"]
    ...> IbGib.Helper.skip_first_past?(ancestors)
    false
    iex> ancestors = ["ib^gib","binary^gib","pic^gib"]
    ...> IbGib.Helper.skip_first_past?(ancestors)
    true
  """
  def skip_first_past?(ancestors) when is_list(ancestors) do
    ancestors
    |> Enum.any?(fn(ancestor_ib_gib) -> 
         ancestor_ib_gib === "binary^gib" or 
         ancestor_ib_gib === "text^gib"
       end)
  end
  def skip_first_past?(ancestors) do
    false
  end
  
  @doc """
  Gets the `rel8n_name` rel8ns for a given `info`.
  
    # ok, Rel8ns found
    iex> info = %{rel8ns: %{"past" => ["ib^gib", "1^gib"]}}
    ...> Logger.disable(self())
    ...> result = IbGib.Helper.get_rel8ns(info, "past", [error_on_not_found: true])
    ...> Logger.enable(self())
    ...> result
    {:ok, ["ib^gib", "1^gib"]}

    # ok, Empty opts
    iex> info = %{rel8ns: %{"past" => ["ib^gib", "1^gib"]}}
    ...> Logger.disable(self())
    ...> result = IbGib.Helper.get_rel8ns(info, "past", [])
    ...> Logger.enable(self())
    ...> result
    {:ok, ["ib^gib", "1^gib"]}

    # error - Invalid opts
    iex> info = %{rel8ns: %{"past" => ["ib^gib", "1^gib"]}}
    ...> Logger.disable(self())
    ...> {:error, _} = IbGib.Helper.get_rel8ns(info, "past", nil)
    ...> Logger.enable(self())
    ...> :ok
    :ok
    
    # error, not found, error_on_not_found: true
    iex> info = %{rel8ns: %{"past" => ["ib^gib", "1^gib"]}}
    ...> Logger.disable(self())
    ...> {:error, _} = IbGib.Helper.get_rel8ns(info, "x", [error_on_not_found: true])
    ...> Logger.enable(self())
    ...> :ok
    :ok

    # ok, not found, error_on_not_found: false
    iex> info = %{rel8ns: %{"past" => ["ib^gib", "1^gib"]}}
    ...> Logger.disable(self())
    ...> {:ok, []} = IbGib.Helper.get_rel8ns(info, "x", [error_on_not_found: false])
    ...> Logger.enable(self())
    ...> :ok
    :ok
  """
  def get_rel8ns(info, rel8n_name, opts \\ [error_on_not_found: true]) 
  def get_rel8ns(info, rel8n_name, opts) 
    when is_map(info) and is_bitstring(rel8n_name) and is_list(opts) do
    OK.with do
      _ = Logger.debug("info:\n#{inspect info}" |> ExChalk.magenta)
      rel8ns <- 
        if info[:rel8ns] do
          {:ok, info[:rel8ns]}
        else
          {:error, "Invalid info. No info[:rel8ns] map found"}
        end
      _ = Logger.debug("rel8ns:\n#{inspect rel8ns}" |> ExChalk.magenta)

      result_rel8ns <-
        cond do
          rel8ns[rel8n_name] != nil ->
            {:ok, rel8ns[rel8n_name]}
            
          !opts[:error_on_not_found] ->
            {:ok, []}
            
          opts[:error_on_not_found] ->
            {:error, "Rel8n #{rel8n_name} not found."}
        end 
      _ = Logger.debug("result_rel8ns:\n#{inspect result_rel8ns}" |> ExChalk.magenta)
        
      OK.success result_rel8ns
    end
  end
  def get_rel8ns(info, rel8n_name, opts) do
    invalid_args([info, rel8n_name, opts])
  end

  @doc """
  Gets the rel8n_names of all rel8nships between ibGibs `a` and `b`.
  
  This returns a map in the form of %{"rel8n_name" => ["ib^gib1", "ib^gib2"...]}
  
  ## how strategies
  
  `how` refers to how we're looking for rel8nships. 
  
  The driving use case is to find the rel8nships between two ibGibs in order to
  unrel8 one of them before rel8ing to "trash". 
  
  ### `:a_now_b_anytime` 
  
  This strategy will look at the current timeframe of `a` only. It will check
  each direct rel8n to see if it includes either `b`'s _current_ ib^gib, or 
  any of the ib^gib listed in its "past" rel8n. 
  
  When you fork an ibGib, it starts the past anew, so it will not overlap with
  other forked timelines. So if you rel8 an ibGib, then fork it, then rel8 the
  fork, this will only find the rel8nships between each individual timeline. 
  (Because a fork creates a "different" ibGib.)
  
    iex> a_info = %{ib: "a", gib: "gib", data: %{}, rel8ns: %{"past" => ["a0^gib"], "ancestor" => ["ib^gib"], "ib^gib"=> ["b^gib"]}}
    ...> b_info = %{ib: "b", gib: "gib", data: %{}, rel8ns: %{"past" => ["b0^gib"], "ancestor" => ["ib^gib"]}}
    ...> Logger.disable(self())
    ...> result = IbGib.Helper.get_direct_rel8nships(:a_now_b_anytime, a_info, b_info)
    ...> Logger.enable(self())
    ...> result
    {:ok, %{"ib^gib" => ["b^gib"]}}
  """
  def get_direct_rel8nships(how, a_info, b_info) 
  def get_direct_rel8nships(:a_now_b_anytime, a_info, b_info)
    when is_map(a_info) and is_map(b_info) do
    # There is a rel8nship if the _current_ rel8ns of a match _either_ the 
    # current b_ib_gib _or_ any ib_gib in b's past.
    with(
      {:ok, b_ib_gib} <- get_ib_gib(b_info),
      b_ib_gibs <- [b_ib_gib] ++ b_info[:rel8ns]["past"] -- ["ib^gib"],
      rel8n_names <-
        a_info[:rel8ns]
        |> Enum.reduce(%{}, fn({rel8n_name, rel8n_ib_gibs}, acc) -> 
             rel8d_b_ib_gibs = get_rel8d_ib_gibs(rel8n_ib_gibs, b_ib_gibs)
             _ = Logger.debug("rel8d_b_ib_gibs: #{inspect rel8d_b_ib_gibs}" |> ExChalk.bg_green |> ExChalk.blue)
             if rel8d_b_ib_gibs === [] do
               acc
             else
               Map.put(acc, rel8n_name, rel8d_b_ib_gibs)
             end
           end)
    ) do 
      {:ok, rel8n_names}
    else
      error -> default_handle_error(error)
    end
  end
  def get_direct_rel8nships(a, b) do
    invalid_args([a, b])
  end

  # helper method for above `get_direct_rel8nships` function
  defp get_rel8d_ib_gibs(rel8n_ib_gibs, b_ib_gibs) do
    b_ib_gibs 
    |> Enum.reduce([], fn(b_ib_gib, acc) ->  
         if Enum.member?(rel8n_ib_gibs, b_ib_gib) do
           acc ++ [b_ib_gib]
         else
           acc
         end
       end)
  end

  def get_timestamp_str() do
    DateTime.utc_now |> DateTime.to_string
  end
  
  @doc """
  Inverts a map of key/value list to a new map where each item in the value
  lists is the key and its value is a list of the corresponding original keys.

  That's a mouthful. I'm probably not saying it right. Here is an example:
  
    iex> a = ["a"]
    ...> b = ["b"]
    ...> c = ["a", "b", "c"]
    ...> map = %{a: a, b: b, c: c}
    ...> IbGib.Helper.invert_flat_map(map)
    %{"a" => [:a, :c], "b" => [:b, :c], "c" => [:c]}
  """
  def invert_flat_map(key_valuelist_map) do
    uniq_values = 
      key_valuelist_map
      |> Map.values
      |> List.flatten
      |> Enum.uniq
    
    # Map the unique values to a keyword list and convert that back to a map.
    uniq_values
    |> Enum.map(&({&1, key_valuelist_map 
                       |> Enum.filter(fn({_k,v}) -> Enum.member?(v, &1) end) 
                       |> Enum.into(%{}) 
                       |> Map.keys})) 
    |> Enum.into(%{})
  end

  def extract_result_ib_gibs(query_result_info, opts \\ [prune_root: true]) do
    raw_result_ib_gibs = query_result_info[:rel8ns]["result"]
    result_count = Enum.count(raw_result_ib_gibs)
    case result_count do
      0 ->
        # 0 results is unexpected. Should at least return the root (1 result)
        emsg = emsg_query_result_count(0)
        _ = Logger.error emsg
        {:error, emsg}

      1 ->
        # 1 result should be the root, but I don't explicitly ensure that here.
        if opts[:prune_root] do
          {:ok, []}
        else
          if Enum.at(raw_result_ib_gibs, 0) !== @root_ib_gib do
            Logger.warn "Query result has only one ib_gib that isn't the root. It is expected to always return the root in addition to the other query ib_gibs."
          end
          {:ok, raw_result_ib_gibs}
        end

      _ ->
        # At least one non-root result found
        result_ib_gibs = 
          if opts[:prune_root] do
            raw_result_ib_gibs -- [@root_ib_gib]
          else
            raw_result_ib_gibs
          end
        
        _ = Logger.debug("foonkie result_ib_gibs: #{inspect result_ib_gibs}" |> ExChalk.bg_blue |> ExChalk.white)
        {:ok, result_ib_gibs}
    end
  end

end
