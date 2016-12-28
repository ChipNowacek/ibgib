defmodule IbGib.Expression.Registry do
  @moduledoc """
  This registry keeps track of `IbGib.Expression` processes corresponding to
  each process's `ib^gib` unique identifier. So, it maps the `ib^gib` to
  an `ib_gib` pid.
  """

  use GenServer
  require Logger

  @registry_name IbGib.Expression.Registry
  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------

  @doc """
  Starts the registry.
  `registry_name` is the name of this registry process, not the expression
  processes that this registry will be tracking.
  """
  def start_link(name \\ @registry_name) do
    # _ = Logger.debug ("name: #{name}")
    GenServer.start_link(__MODULE__, name, [name: name])
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

  @doc """
  Gets the pid process associated with the given `expr_ib_gib` if it has been
  registered.

  Returns {:ok, expr_pid} or {:error, reason}
  """
  def get_process(expr_ib_gib, name \\ @registry_name) do
    GenServer.call(name, {:get_process, {expr_ib_gib}})
  end


  # ----------------------------------------------------------------------------
  # Server Callbacks
  # ----------------------------------------------------------------------------

  def init(_srv_name) do
    # _ = Logger.debug "srv_name: #{srv_name}"

    # `expressions` maps expr_ib_gib to expression pid
    expressions = %{}
    # Removing expressions with ets because I want to be able to have it
    # mapped by strings, and ets.new requires an atom.
    # All of the advice says string->atom is bad.

    # Keep track of `refs` to remove them when process downed.
    # `refs` maps process monitor to expr_ib_gib, b/c `handle_info` will give the ref
    refs = %{}
    {:ok, {expressions, refs}}
  end

  def handle_call({:register, {expr_ib_gib, expr_pid}}, _from, {expressions, refs}) do
    # _ = Logger.debug "inspect expressions: #{inspect expressions}"
    # _ = Logger.debug "inspect refs: #{inspect refs}"
    {:ok, {expressions, refs}} = register_impl(expressions, expr_ib_gib, expr_pid, refs)
    {:reply, :ok, {expressions, refs}}
  end
  def handle_call({:get_process, {expr_ib_gib}}, _from, {expressions, refs}) do
    # _ = Logger.debug "inspect expressions: #{inspect expressions}"
    # _ = Logger.debug "inspect refs: #{inspect refs}"

    {:reply, get_process_impl(expressions, expr_ib_gib), {expressions, refs}}
  end

  @doc """
  Remove expression process from expressions and refs if the process goes
  down.
  """
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {expressions, refs}) do
    {expr_ib_gib, refs} = Map.pop(refs, ref)
    # _ = Logger.debug "Removed ref: #{inspect ref}"
    {expr_pid, expressions} = Map.pop(expressions, expr_ib_gib)
    # _ = Logger.debug "Removing expr_pid: #{inspect expr_pid}"
    # :ets.delete(expressions, expression)
    {:noreply, {expressions, refs}}
  end
  def handle_info(msg, state) do
    _ = Logger.debug "msg: #{msg}"
    {:noreply, state}
  end

  defp get_process_impl(expressions, expr_ib_gib) do
    # _ = Logger.debug "expr_ib_gib: #{expr_ib_gib}"
    case Map.fetch(expressions, expr_ib_gib) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, :not_found}
    end
  end

  defp register_impl(expressions, expr_ib_gib, expr_pid, refs) do
    case get_process_impl(expressions, expr_ib_gib) do
      {:ok, _pid} ->
        # Already exists.
        _ = Logger.debug "expr_ib_gib (#{expr_ib_gib}) already exists"
        {:ok, {expressions, refs}}
      {:error, _reason} ->
        # Doesn't exist, so register it
        _ = Logger.debug "expr_ib_gib (#{expr_ib_gib}) does not exist. registering..."
        ref = Process.monitor(expr_pid)
        refs = Map.put(refs, ref, expr_ib_gib)
        expressions = Map.put(expressions, expr_ib_gib, expr_pid)
        {:ok, {expressions, refs}}
    end
  end
end
