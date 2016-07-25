defmodule IbGib.Expression.Supervisor do
  use Supervisor
  require Logger

  alias IbGib.{Helper, Expression.Registry}

  @delim "^"

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: IbGib.Expression.Supervisor)
  end

  def init(:ok) do
    children = [
      # `:permanent` always restarted
      # `:temporary` not restarted
      # `:transient` restarted on abnormal shutdown
      # Empty args, because args are passed when `start_child` is called.
      worker(IbGib.Expression, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  # ----------------------------------------------------------------------------
  # start_expression Methods
  # These should map to the "constructors" of the `IbGib.Expression`.
  # ----------------------------------------------------------------------------

  @doc """
  Start an `IbGib.Expression` process from a pre-existing ib^gib that has
  already been expressed and is in storage.

  Returns {:ok, expr_pid}. If the expression for the given `ib^gib` already
  has an existing process/pid, then it will return that. Otherwise, it will
  create a new process, load it from storage, register it with the process
  registry and return that process' pid.
  """
  def start_expression(args \\ "ib#{@delim}gib")
  def start_expression(expr_ib_gib) when is_bitstring(expr_ib_gib) do
    ib_gib = String.split(expr_ib_gib, @delim, parts: 2)
    Logger.debug "ib_gib: #{inspect ib_gib}"


    {get_result, expr_pid} = Registry.get_process(expr_ib_gib)
    if (get_result === :ok) do
      Logger.debug "already started expr: #{expr_ib_gib}"
      {:ok, expr_pid}
    else
      args = [{:ib_gib, {Enum.at(ib_gib, 0), Enum.at(ib_gib, 1)}}]

      start(args)
      # result = Supervisor.start_child(IbGib.Expression.Supervisor, args)
      # Logger.debug "start_child result: #{inspect result}"
      # case result do
      #   {:ok, expr_pid} ->
      #     Logger.debug "start_child result matches {ok, expr_pid}"
      #     register_result = IbGib.Expression.Registry.register(expr_ib_gib, expr_pid)
      #     Logger.debug "register_result: #{inspect register_result}"
      #     {:ok, expr_pid}
      #   error ->
      #     Logger.debug "start_child result matches error"
      #     {:error, "could not register expression with registry"}
      # end
    end
  end
  def start_expression({ib, gib}) when is_bitstring(ib) and is_bitstring(gib) do
    start_expression(Helper.get_ib_gib!(ib, gib))
  end
  def start_expression({a, b}) when is_map(a) and is_map(b) do
    Logger.debug "combining two ib"
    args = [{:apply, {a, b}}]
    start(args)
  end

  defp start(args) do
    Logger.debug "Existing expression process not found in registry. Going to start a new expression process. start args: #{inspect args}"

    with {:ok, expr_pid} <- Supervisor.start_child(IbGib.Expression.Supervisor, args),
      do: {:ok, expr_pid}
  end
  # def start_expression(:fork, fork_transform) when is_map(fork_transform) do
  #   Logger.debug "#{inspect(fork_transform)}"
  #   args = [{:fork, fork_transform}]
  #   start(args)
  # end
end
