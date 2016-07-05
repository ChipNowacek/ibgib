defmodule IbGib.Expression.Registry do
  use GenServer

  @registry_name IbGib.Expression.Registry
  @table_name IbGib.Expression.Registry
  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------

  @doc """
  Starts the registry.
  `registry_name` is the name of this registry process, not the expression
  processes that this registry will be tracking.
  """
  def start_link(name \\ @registry_name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  # ----------------------------------------------------------------------------
  # Client API
  # ----------------------------------------------------------------------------

  @doc """
  Registers the given expression ib_gib identifier `expr_ib_gib` with `expr_pid`
  process.

  Returns :ok
  """
  def register(expr_ib_gib, expr_pid, name \\ @registry_name) do
    GenServer.call(name, {:register, {expr_ib_gib, expr_pid}})
  end

  def get_process(expr_ib_gib, name \\ @registry_name) do
    GenServer.call(name, {:get_process, {expr_ib_gib}})
  end


  # ----------------------------------------------------------------------------
  # Server Callbacks
  # ----------------------------------------------------------------------------

  def init(name) do
    # `expressions` maps expr_ib_gib to expression pid
    expressions = :ets.new(@table_name, [:named_table, read_concurrency: true])
    # read_concurrency: true option optimizes the table for concurrent read operations.

    # Keep track of `refs` to remove them when process downed.
    # `refs` maps process monitor to expr_ib_gib, b/c `handle_info` will give the ref
    refs = %{}
    {:ok, {expressions, refs}}
  end

  def handle_call({:register, {expr_ib_gib, expr_pid}}, _from, { expressions, refs }) do
    case get_process(expressions, expr_ib_gib) do
      {:ok, pid} ->
        # Already exists.
        {:reply, :ok, {expressions, refs}}
      :error ->
        # Doesn't exist. Register with ets.
        ref = Process.monitor(expr_pid)
        refs = Map.put(refs, ref, expr_ib_gib)
        :ets.insert(expressions, {expr_ib_gib, expr_pid})
        {:reply, :ok, {expressions, refs}}
    end
  end

  def handle_call({:get_process, {expr_ib_gib}}, _from, { expressions, refs }) do

  end
  @doc """
  Looks up the expression pid for `expr_ib_gib` stored in ets table
  `@table_name`.

  Returns `{:ok, pid}` if the expression exists, else `{:error, "not found"}`.
  """
  defp get_process(expressions, expr_ib_gib, name \\ @registry_name) do
    # 2. Lookup is now done directly in ETS, without accessing the server
    # This is the whole point of using the ETS in this example. It shows that the ETS process is shared among all processes "locally", since this method is called on the client.
    case :ets.lookup(expressions, expr_ib_gib) do
      [{^expr_ib_gib, expr_pid}] -> {:ok, expr_pid}
      [] -> {:error, "not found"}
    end
  end


  @doc """
  Remove process reference if the process goes down.
  """
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {expressions, refs}) do
    {expression, refs} = Map.pop(refs, ref)
    :ets.delete(expressions, expression)
    {:noreply, {expressions, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
