defmodule IbGib.ExpressionTest do
  use ExUnit.Case
  alias IbGib.{Expression, TransformFactory, Helper}
  require Logger

  @delim "^"

  @tag :capture_log
  test "create expression, from scratch, root Thing" do
    {result, _expression} = Expression.Supervisor.start_expression()
    assert result === :ok
  end

  @tag :capture_log
  test "create expression, from scratch, root Thing, get from registry" do
    {result, expr_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {get_result, get_expr_pid} = Expression.Registry.get_process("ib#{@delim}gib")
    assert get_result === :ok
    assert get_expr_pid === expr_pid
  end

  @tag :capture_log
  test "create expression, from scratch, root Thing, fork" do
    {result, expr_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(expr_pid)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"
  end

  # @tag :capture_log
  test "create expression, from scratch, root Thing, fork, mut8" do
    {result, expr_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(expr_pid)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"

    forked_info = Expression.get_info!(new_forked_pid)
    Logger.debug "forked_info: #{inspect forked_info}"

    forked_ib_gib = Helper.get_ib_gib!(forked_info[:ib], forked_info[:gib])
    Logger.debug "forked_ib_gib: #{forked_ib_gib}"

    {mut8_result, new_mut8_pid} = Expression.mut8(new_forked_pid, %{"name" => "text"})

    mut8d_info = Expression.get_info!(new_mut8_pid)
    Logger.debug "mut8d_info: #{inspect mut8d_info}"
  end

  # test "create expression, from scratch, fork transform instance" do
  #   transform_map = TransformFactory.fork()
  #   {result, _transform_instance} = Expression.Supervisor.start_expression({:fork, transform_map})
  #   assert result === :ok
  # end
  #
  # test "create expression, from scratch, text Thing" do
  #   flunk("not implemented")
  # end
  #
  # test "create expression, from scratch, text instance Thing" do
  #   flunk("not implemented")
  # end
  #
  # test "create expression, from scratch, hello world Thing" do
  #   flunk("not implemented")
  # end
  #
  # test "create expression, from scratch, hello world instance Thing with hello world text Thing" do
  #   flunk("not implemented")
  # end
end
