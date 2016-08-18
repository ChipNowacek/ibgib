defmodule RandomGib.Get do
  use GenServer
  require Logger

  @letters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @letters_and_characters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`~!@\#$%^&*()-_=+[]{}\\|;:'\"<>,.?/"

  @doc """
  Starts a worker server with a new seed.
  """
  def start_link(name) do
    # Logger.debug("GenServer starting...")
    # Agent.start_link(__MODULE__, fn -> %{} end, [name: name])
    # arg1: Where the callbacks are implemented.
    # arg2: Init argument (passed to `init`)
    # arg3: List of options, e.g. name of server
    result = GenServer.start_link(__MODULE__, :ok, name: name)
    # Logger.debug("GenServer started.")
    result
  end

  def init(:ok) do
    {:ok, %{}}
  end


  # ----------------------------------------------------------------------------
  # Client API
  # ----------------------------------------------------------------------------

  @doc ~S"""
    Generates a new seed.

  ## Examples

    iex> RandomGib.generate_seed()
    :ok

  """
  def generate_seed(algorithm \\ :exs1024) do
    GenServer.call(__MODULE__, {:generate_seed, algorithm})
  end

  @doc """
  Gets a single random item from a list.
  """
  # def one_of(src)
  def one_of(src) do
    GenServer.call(__MODULE__, {:one_of, src})
  end

  @doc """
  Gets some subset of a given source list or bitstring string.
  """
  def some_of(src) do
    GenServer.call(__MODULE__, {:some_of, src})
  end

  @doc ~S"""
   Gets some random letters of a given `count`.
   Returns a string.

  ## Examples

    result = RandomGib.some_letters(5)
  """
  @spec some_letters(pos_integer) :: String.t
  def some_letters(count) when count > 0 do
    GenServer.call(__MODULE__, {:some_letters, count})
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
    GenServer.call(__MODULE__, {:some_characters, count, valid_characters})
  end

  # ----------------------------------------------------------------------------
  # Server
  # ----------------------------------------------------------------------------


  def handle_call({:generate_seed, algorithm}, _from, state) do
    # Logger.debug("handle_call :generate_seed")
    :rand.seed_s(algorithm)
    {:reply, :ok, state}
  end
  def handle_call({:one_of, src}, _from, state) do
    # Logger.debug("handle_call :one_of")
    result = one_of_impl(src)
    {:reply, result, state}
  end
  def handle_call({:some_of, src}, _from, state) do
    # Logger.debug("handle_call :some_of")
    result = some_of_impl(src)
    {:reply, result, state}
  end
  def handle_call({:some_letters, count}, _from, state) do
    # Logger.debug("handle_call :some_letters")
    result = 1..count
      |> Enum.map(fn _ -> one_of_impl(@letters) end)
      |> Enum.reduce(fn (a,b) -> a <> b end)

    {:reply, result, state}
  end
  def handle_call({:some_characters, count, valid_characters}, _from, state) do
    # Logger.debug("handle_call :some_letters")
    result = 1..count
      |> Enum.map(fn _ -> one_of_impl(valid_characters) end)
      |> Enum.reduce(fn (a,b) -> a <> b end)

    {:reply, result, state}
  end

  defp one_of_impl([]) do
    # Logger.debug("one_of_impl []")
    nil
  end
  defp one_of_impl(src) when is_list(src) do
    # Logger.debug("one_of_impl list")
    Enum.random(src)
  end
  defp one_of_impl("") do
    # Logger.debug("one_of_impl \"\"")
    ""
  end
  defp one_of_impl(src) when is_bitstring(src)  do
    # Logger.debug("one_of_impl bitstring")
    length = String.length(src)
    cond do
      length == 0 -> nil
      length > 0 -> String.at(src, :rand.uniform(length)-1)
    end
  end


  defp some_of_impl([]) do
    # Logger.debug("some_of []")
    []
  end
  defp some_of_impl("") do
    # Logger.debug("some_of \"\"")
    ""
  end
  defp some_of_impl(src) when is_list(src) do
    # Logger.debug("some_of list")
    # Enum.at(list, :rand.uniform(Enum.count(list)))
    percent = :rand.uniform()
    result = Enum.filter(src, fn _item -> :rand.uniform() > percent end)
    if (Enum.count(result) === 0) do
      Logger.debug("Recursing some_of")
      some_of_impl(src)
    else
      result
    end
  end
  defp some_of_impl(src) when is_bitstring(src)  do
    # Logger.debug("some_of bitstring")
    length = String.length(src)
    percent = :rand.uniform()
    result = cond do
      length == 0 -> nil
      length > 0 -> for <<c <- src>>, :rand.uniform() > percent, into: "", do: <<c>>
    end
    if result === "" do
      # Logger.debug("Recursing some_of")
      some_of_impl(src)
    else
      result
    end
  end

end
