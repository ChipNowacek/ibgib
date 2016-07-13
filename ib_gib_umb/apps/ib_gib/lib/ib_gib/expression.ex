defmodule IbGib.Expression do
  use GenServer
  require Logger

  alias IbGib.{TransformFactory, Helper}

  @delim "^"

  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------
  @doc """
  Starts an expression via given `args` as follows:

    {:ib_gib, {ib, gib}} - Use this to start an expression for an existing
      `ib_gib` that has already been persisted. the `ib` and `gib` uniquely
      identify something in time.

    {:combine, {a, b}} - Use this to create a new ib_gib, usually when applying
      a transform ib_gib `b` to some other ib_gib `a`.
  """
  def start_link(args)
  def start_link({:ib_gib, {ib, gib}}) do
    # expr_id = Helper.new_id |> String.downcase
    Logger.debug "{ib, gib}: {#{inspect ib}, #{inspect gib}}"
    result = GenServer.start_link(__MODULE__, {:ib_gib, {ib, gib}})
    Logger.debug "start_link result: #{inspect result}"
    result
  end
  def start_link({:combine, {a, b}}) when is_map(a) and is_map(b) do
    # expr_id = Helper.new_id |> String.downcase
    Logger.debug "{a, b}: {#{inspect a}, #{inspect b}}"
    result = GenServer.start_link(__MODULE__, {:combine, {a, b}})
    Logger.debug "start_link result: #{inspect result}"
    result
  end

  # ----------------------------------------------------------------------------
  # Inits
  # ----------------------------------------------------------------------------
  def init({:ib_gib, {ib, gib}}) when is_bitstring(ib) and is_bitstring(gib) do
    info =
      if ib === "ib" and gib === "gib" do
        Logger.debug "initializing ib_gib root expression."
        %{
          :ib => ib,
          :gib => gib,
          :ib_gib_history => ["ib#{@delim}gib"],
          :data => %{}
        }
      else
        Logger.debug "initializing ib_gib expression by loading data. ib: #{ib}, gib: #{gib}"
        IbGib.Data.load!(ib, gib)
      end
    register_result = IbGib.Expression.Registry.register(Helper.get_ib_gib!(ib, gib), self)
    if (register_result === :ok) do
      {:ok, %{:info => info}}
    else
      Logger.error "Register expression error: #{inspect register_result}"
      {:error, register_result}
    end
  end
  def init({:combine, {a, b}}) when is_map(a) and is_map(b) do
    if (b[:ib] === "fork" and b[:gib] !== "gib") do
      # We are applying a fork transform.
      Logger.debug "applying fork b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
      Logger.debug "a[:ib_gib_history]: #{inspect a[:ib_gib_history]}"
      fork_data = b[:data]

      # We're going to borrow `a` as our own info for the new thing. We're just
      # going to change its `ib`, `gib`, and `ib_gib_history`.

      # We take the ib directly from the fork's `dest_ib`.
      Logger.debug "Setting a[:ib]... fork_data: #{inspect fork_data}"
      ib = fork_data[:dest_ib]
      a = Map.put(a, :ib, ib)
      Logger.debug "a: #{inspect a}"

      # We add the fork itself to the `ib_gib_history`.
      Logger.debug "Setting a[:ib_gib_history] to include fork that we're applying..."
      b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])
      a_history = a[:ib_gib_history]
      ib_gib_history = a_history ++ [b_ib_gib]
      Logger.debug "ib_gib_history: #{inspect ib_gib_history}"
      a = Map.put(a, :ib_gib_history, ib_gib_history)
      Logger.debug "History set. new a[:ib_gib_history]: #{inspect a[:ib_gib_history]}"

      data = Map.get(a, :data, %{})
      Logger.debug "data: #{inspect data}"
      a = Map.put(a, :data, data)

      # Now we calculate the new hash and set it to `:gib`.
      gib = Helper.hash(ib, ib_gib_history, data)
      Logger.debug "gib: #{gib}"
      a = Map.put(a, :gib, gib)

      Logger.debug "a[:gib] set to gib: #{gib}"

      ib_gib = Helper.get_ib_gib!(ib, gib)
      register_result = IbGib.Expression.Registry.register(ib_gib, self)

      if (register_result === :ok) do
        Logger.debug "Registered ok. info: #{inspect a}"
        {:ok, %{:info => a}}
      else
        Logger.error "Register expression error: #{inspect register_result}"
        {:error, register_result}
      end
    else
      err_msg = "unknown combination: a: #{inspect a}, b: #{inspect b}"
      Logger.error err_msg
      {:error, err_msg}
    end
  end

  # ----------------------------------------------------------------------------
  # Client API
  # ----------------------------------------------------------------------------


  @doc """
  "Combines" two expression processes. This is usually going to be "apply
  transform".
  """
  def meet(expr_pid, other_expr_pid) when is_pid(expr_pid) and is_pid(other_expr_pid) do
    GenServer.call(expr_pid, {:meet, other_expr_pid})
  end

  def fork(expr_pid) when is_pid(expr_pid) do
    GenServer.call(expr_pid, :fork)
  end

  def get_info(expr_pid) when is_pid(expr_pid) do
    GenServer.call(expr_pid, :get_info)
  end

  # ----------------------------------------------------------------------------
  # Server
  # ----------------------------------------------------------------------------

  def handle_call({:meet, other_expr_pid}, _from, state) do
    Logger.debug ":ib_gib"
    {:reply, meet_impl(other_expr_pid, state), state}
  end
  def handle_call(:fork, _from, state) do
    Logger.debug "state: #{inspect state}"
    info = state[:info]
    Logger.debug "info: #{inspect info}"
    ib = info[:ib]
    gib = info[:gib]
    Logger.debug "ib: #{inspect ib}"

    # 1. Create transform
    fork_info = TransformFactory.fork(Helper.get_ib_gib!(ib, gib))
    Logger.debug "fork_info: #{inspect fork_info}"

    # 2. Save transform
    IbGib.Data.save(fork_info)

    # 3. Create instance process of fork
    Logger.debug "fork saved. Now trying to create fork transform expression process"
    {:ok, fork} = IbGib.Expression.Supervisor.start_expression({fork_info[:ib], fork_info[:gib]})

    # 4. Apply transform
    Logger.debug "will ib_gib the fork..."
    meet_result = meet_impl(fork, state)
    Logger.debug "meet_result: #{inspect meet_result}"

    {:reply, :ok, state}
  end
  def handle_call(:get_info, _from, state) do
    {:reply, state[:info], state}
  end

  defp meet_impl(other_expr_pid, state) when is_pid(other_expr_pid) and is_map(state) do
    Logger.debug "state: #{inspect state}"
    Logger.debug "other_expr_pid: #{inspect other_expr_pid}"

    other_info = get_info(other_expr_pid)
    Logger.debug "other_info: #{inspect other_info}"
    IbGib.Expression.Supervisor.start_expression({state[:info], other_info})
  end

end
