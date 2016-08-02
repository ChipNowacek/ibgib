defmodule IbGib.Data.Cache do
  use GenServer
  require Logger

  @srv_name IbGib.Data.Cache
  @cache_table_name IbGib.Data.Cache

  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------

  @doc """
  Starts the cache.
  """
  @spec start_link(atom()) :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}
  def start_link(name \\ @srv_name) when is_atom(name) do
    # Logger.debug ("name: #{name}")
    GenServer.start_link(__MODULE__, name, [name: name])
  end

  # ----------------------------------------------------------------------------
  # Client API
  # ----------------------------------------------------------------------------

  @doc """
  Inserts/replaces the given `key` with the given `value`.

  Returns {:ok, :ok} or {:error, reason}
  """
  def put(key, value, name \\ @srv_name) when is_bitstring(key) do
    Logger.debug "putting..."
    GenServer.call(name, {:put, {key, value}})
  end

  @doc """
  Gets the `value` associated with the given `key` if it has been stored.

  Returns {:ok, value} or {:error, reason}
  """
  def get(key, name \\ @srv_name) do
    GenServer.call(name, {:get, {key, name}})
  end


  # ----------------------------------------------------------------------------
  # Server Callbacks
  # ----------------------------------------------------------------------------

  def init(srv_name) when is_atom(srv_name) do
    # Logger.debug "srv_name: #{srv_name}"

    items = :ets.new(srv_name, [:named_table, read_concurrency: true])

    {:ok, {items}}
  end

  def handle_call({:put, {key, value}}, _from, {items}) do
    Logger.debug "inspect items: #{inspect items}"

    {:reply, put_impl(items, key, value), {items}}
  end
  def handle_call({:get, {key, name}}, _from, {items}) do
    Logger.debug "inspect items: #{inspect items}"

    {:reply, get_impl(items, key), {items}}
  end

  defp get_impl(items, key) do
    Logger.debug "key: #{key}"
    case :ets.lookup(items, key) do
      [{^key, value}] -> {:ok, value}
      [] -> {:error, :not_found}
    end
  end

  defp put_impl(items, key, value) do
    Logger.debug "key: #{key}\nvalue: #{inspect value}"
    insert_result = :ets.insert_new(items, {key, value})
    if (insert_result) do
      {:ok, :ok}
    else
      Logger.warn "Attempted to insert duplicate key in cache. key: #{key}"
      {:error, :already}
    end
  end
end
