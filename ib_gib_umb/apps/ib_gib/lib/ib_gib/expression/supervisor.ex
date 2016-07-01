defmodule IbGib.Expression.Supervisor do
  use Supervisor

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
    Supervisor.start_child(IbGib.Expression.Supervisor, [])
  end
end
