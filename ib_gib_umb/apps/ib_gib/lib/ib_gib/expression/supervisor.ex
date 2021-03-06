defmodule IbGib.Expression.Supervisor do
  @moduledoc """
  Besides obviously supervising `IbGib.Expression` process, this is actually
  in practice with `start_expression/1` and `start_expression/2`.

  Each of these child processes represents the immutable state of an ib_gib
  "snapshot" in time, with the `ib` acting usually as the id, and the `gib`
  acting usually as the hash.
  """

  use Supervisor
  require Logger

  use IbGib.Constants, :ib_gib
  alias IbGib.{Helper, Expression.Registry}

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
  def start_expression(args \\ @root_ib_gib)
  def start_expression(expr_ib_gib) when is_bitstring(expr_ib_gib) do
    ib_gib = String.split(expr_ib_gib, @delim, parts: 2)
    _ = Logger.debug "ib_gib: #{inspect ib_gib}"


    {get_result, expr_pid} = Registry.get_process(expr_ib_gib)
    if get_result == :ok do
      _ = Logger.debug "already started expr: #{expr_ib_gib}"
      {:ok, expr_pid}
    else
      args = [{:ib_gib, {Enum.at(ib_gib, 0), Enum.at(ib_gib, 1)}}]

      start(args)
    end
  end
  def start_expression({ib, gib}) when is_bitstring(ib) and is_bitstring(gib) do
    start_expression(Helper.get_ib_gib!(ib, gib))
  end
  def start_expression({a, b}) when is_map(a) and is_map(b) do
    _ = Logger.debug "combining two ib"
    args = [{:apply, {a, b}}]
    start(args)
  end
  def start_expression({_identity_ib_gibs, a, @root_ib_gib}) when is_bitstring(a) do
    _ = Logger.warn "Attempted to start_expression with identity transform"
    {:ok, a}
  end
  def start_expression({identity_ib_gibs, a, a_info, b})
    when is_list(identity_ib_gibs) and is_bitstring(a) and
         (is_map(a_info) or is_nil(a_info)) and is_bitstring(b) do
    _ = Logger.debug "combining two ib via ib^gib"
    args = [{:express, {identity_ib_gibs, a, a_info, b}}]
    start(args)
  end

  defp start(args) do
    _ = Logger.debug "Starting new expression process... args: #{inspect args}"

    with {:ok, expr_pid} <- Supervisor.start_child(IbGib.Expression.Supervisor, args),
      do: {:ok, expr_pid}
  end
end
