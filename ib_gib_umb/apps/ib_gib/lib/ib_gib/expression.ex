defmodule IbGib.Expression do
  use GenServer
  require Logger

  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------
  def start_link({ib, gib}) do
    GenServer.start_link(__MODULE__, {ib, gib})
  end
  def start_link({:fork, fork_transform}) when is_map(fork_transform) do
    Logger.debug "{:fork, fork_transform}"

    # GenServer.start_link(__MODULE__, {:fork, fork_transform}, name: "#{fork_transform.ib}_#{fork_transform.gib}")
    GenServer.start_link(__MODULE__, {:fork, fork_transform})
  end

  def init({ib, gib}) do
    {:ok, %{ib: ib, gib: gib}}
  end
  def init({:fork, fork_transform}) do
    Logger.debug "{:fork, fork_transform}"

    {:ok, fork_transform}
  end


  # ----------------------------------------------------------------------------
  # Client API
  # ----------------------------------------------------------------------------



  # ----------------------------------------------------------------------------
  # Server
  # ----------------------------------------------------------------------------

  def express(ib, gib) do
  end
end
