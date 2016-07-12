defmodule IbGib.Expression do
  use GenServer
  require Logger



  alias IbGib.{TransformFactory, Helper}

  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------
  def start_link({:ib_gib, {ib, gib}}) do
    # expr_id = Helper.new_id |> String.downcase
    Logger.debug "{ib, gib}: {#{inspect ib}, #{inspect gib}}"
    result = GenServer.start_link(__MODULE__, {:ib_gib, {ib, gib}})
    Logger.debug "start_link result: #{inspect result}"
    result
  end

  # ----------------------------------------------------------------------------
  # Inits
  # ----------------------------------------------------------------------------
  def init({:ib_gib, {ib, gib}}) when is_bitstring(ib) and is_bitstring(gib) do
    if ib === "ib" and gib === "gib" do
      Logger.debug "initializing ib_gib root expression."
      {
        :ok,
        %{
          :info =>
            %{:ib => ib, :gib => gib, :ib_gib => ["ib|gib"]}
        }
      }
    else
      Logger.debug "initializing ib_gib expression by loading data. ib: #{ib}, gib: #{gib}"
      {
        :ok,
        %{
          :info => IbGib.Data.load!(ib, gib)
        }
      }
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
