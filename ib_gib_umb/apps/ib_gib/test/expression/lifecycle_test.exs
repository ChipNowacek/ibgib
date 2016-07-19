defmodule IbGib.Expression.LifecycleTest do
  use ExUnit.Case
  alias IbGib.{Expression, Helper}
  import IbGib.Expression
  require Logger

  @delim "^"

  @tag :capture_log
  test "Many forks" do
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!
    Logger.configure(level: :info)
    # I lower this for regular unit tests. I change it to a big number if I
    # want to see if it can handle a bunch of processes. Each iteration here
    # will create the transform process and the end result process, so it will
    # double the number in the range.
    1..100 |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)
  end

  @tag :capture_log
  test "create expressions, kill one, others should still be alive" do
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!
    a_info = a |> get_info!
    a_ib_gib = Helper.get_ib_gib!(a_info[:ib], a_info[:gib])

    b = a |> fork!
    b_info = b |> get_info!
    b_ib_gib = Helper.get_ib_gib!(b_info[:ib], b_info[:gib])

    c = b |> fork!
    c_info = c |> get_info!
    c_ib_gib = Helper.get_ib_gib!(c_info[:ib], c_info[:gib])


    # Make sure we can get all of them from the registry
    {a_result, _} = IbGib.Expression.Registry.get_process(a_ib_gib)
    assert a_result === :ok
    {b_result, _} = IbGib.Expression.Registry.get_process(b_ib_gib)
    assert b_result === :ok
    {c_result, _} = IbGib.Expression.Registry.get_process(c_ib_gib)
    assert c_result === :ok

    Process.exit(c, :test_kill)

    {a_result2, _} = IbGib.Expression.Registry.get_process(a_ib_gib)
    assert a_result2 === :ok
    {b_result2, b2} = IbGib.Expression.Registry.get_process(b_ib_gib)
    assert b_result2 === :ok
    {c_result2, _} = IbGib.Expression.Registry.get_process(c_ib_gib)
    assert c_result2 === :error

    Logger.warn "b2: #{inspect b2}"
  end


  @tag :capture_log
  test "create expressions, kill one, start back up on demand" do
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!
    a_info = a |> get_info!
    _a_ib_gib = Helper.get_ib_gib!(a_info[:ib], a_info[:gib])

    b = a |> fork!
    b_info = b |> get_info!
    _b_ib_gib = Helper.get_ib_gib!(b_info[:ib], b_info[:gib])

    c = b |> fork!
    c_info = c |> get_info!
    c_ib_gib = Helper.get_ib_gib!(c_info[:ib], c_info[:gib])

    Process.exit(c, :test_kill)

    # we fork another thing to be sure that the registry has processed
    # the removal and avoid the race condition of the test_kill and the
    # following c2 registration.
    _dummy = root |> fork!

    {:ok, c2} = IbGib.Expression.Supervisor.start_expression(c_ib_gib)
    Logger.debug "c2: #{inspect c2}"
    c2_info = c2 |> get_info!

    d = c2 |> fork!
    d_info = d |> get_info!
    Logger.warn "c2_info: #{inspect c2_info}"
    Logger.warn "d_info: #{inspect d_info}"
  end

end
