defmodule IbGib.Expression.Supervisor do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: IbGib.Expression.Supervisor)
  end

  def init(:ok) do
    children = [
      # `:permanent` always restarted
      # `:temporary` not restarted
      # `:transient` restarted on abnormal shutdown
      worker(IbGib.Expression, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  # ----------------------------------------------------------------------------
  # start_expression Methods
  # These should map to the "constructors" of the `IbGib.Expression`.
  # ----------------------------------------------------------------------------

  @doc """
  Start a blank expression process.
  """
  def start_expression() do
    args = []
    start(args)
  end

  def start_expression({:fork, fork_transform}) when is_map(fork_transform) do
    Logger.debug "#{inspect(fork_transform)}"
    args = [{:fork, fork_transform}]
    start(args)
  end

  defp start(args) do
    result = Supervisor.start_child(IbGib.Expression.Supervisor, args)
    Logger.debug "start_child result yoooo: #{inspect result}"
    case result do
      {:ok, pid, expr_ib_gib} ->
        IbGib.Expression.Registry.register()
        result
      error ->
        result
    end
  end
end
