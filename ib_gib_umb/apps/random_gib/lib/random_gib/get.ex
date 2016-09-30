defmodule RandomGib.Get do
  @moduledoc """
  GenServer that contains simple functions for getting random things like
  letters, characters, etc.

  I created this when first learning Elixir. It probably should not be a
  GenServer and I'll probably need to change that, but I like my syntax.
  """

  require Logger

  @letters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @letters_and_characters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`~!@\#$%^&*()-_=+[]{}\\|;:'\"<>,.?/"

  @doc ~S"""
    Generates a new seed.

  ## Examples

    iex> RandomGib.Get.generate_seed()
    :ok

  """
  def generate_seed(algorithm \\ :exs1024) do
    :rand.seed_s(algorithm)
    :ok
  end

  @doc """
  Gets a single random item from a list.
  """
  # def one_of(src)
  def one_of(src) do
    one_of_impl(src)
  end

  @doc """
  Gets some subset of a given source list or bitstring string.
  """
  def some_of(src) do
    some_of_impl(src)
  end

  @doc ~S"""
   Gets some random letters of a given `count`.
   Returns a string.

  ## Examples

    result = RandomGib.some_letters(5)
  """
  @spec some_letters(pos_integer) :: String.t
  def some_letters(count) when count > 0 do
    1..count
      |> Enum.map(fn _ -> one_of_impl(@letters) end)
      |> Enum.reduce(fn (a,b) -> a <> b end)
  end

  @doc """
  Gets a string of characters with length `count`, drawing from the
  bitstring `valid_characters`, which defaults to a-z, A-Z and a bunch of
  special characters.

  ## Examples
    result = RandomGib.Get.some_characters(5)

    result = RandomGib.Get.some_characters(5, "abcdefgh*^&%")
  """
  def some_characters(count, valid_characters \\ @letters_and_characters)
    when is_integer(count) and is_bitstring(valid_characters) do
    1..count
      |> Enum.map(fn _ -> one_of_impl(valid_characters) end)
      |> Enum.reduce(fn (a,b) -> a <> b end)
  end

  defp one_of_impl([]) do
    nil
  end
  defp one_of_impl(src) when is_list(src) do
    Enum.random(src)
  end
  defp one_of_impl("") do
    ""
  end
  defp one_of_impl(src) when is_bitstring(src)  do
    length = String.length(src)
    if length === 0 do
      nil
    else
      String.at(src, :rand.uniform(length) - 1)
    end
  end


  defp some_of_impl([]) do
    []
  end
  defp some_of_impl("") do
    ""
  end
  defp some_of_impl(src) when is_list(src) do
    percent = :rand.uniform()
    result = Enum.filter(src, fn _item -> :rand.uniform() > percent end)
    if Enum.count(result) === 0 do
      _ = Logger.debug("Recursing some_of")
      some_of_impl(src)
    else
      result
    end
  end
  defp some_of_impl(src) when is_bitstring(src)  do
    length = String.length(src)
    percent = :rand.uniform()

    result =
      if length === 0 do
        nil
      else
        for <<c <- src>>, :rand.uniform() > percent, into: "", do: <<c>>
      end
    if result === "" do
      some_of_impl(src)
    else
      result
    end
  end

end
