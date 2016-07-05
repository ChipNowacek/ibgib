defmodule IbGib.ExpressionTest do
  use ExUnit.Case
  alias IbGib.{Expression, TransformFactory}
  require Logger

  test "create expression, from scratch, root Thing" do
    {result, _expression} = Expression.Supervisor.start_expression()
    assert result === :ok
  end

  test "create expression, from scratch, root Thing, get from registry" do
    {result, _expression} = Expression.Supervisor.start_expression()
    assert result === :ok
  end

  test "create expression, from scratch, fork transform instance" do
    transform_map = TransformFactory.fork()
    {result, _transform_instance} = Expression.Supervisor.start_expression({:fork, transform_map})
    assert result === :ok
  end

  test "create expression, from scratch, text Thing" do
    flunk("not implemented")
  end

  test "create expression, from scratch, text instance Thing" do
    flunk("not implemented")
  end

  test "create expression, from scratch, hello world Thing" do
    flunk("not implemented")
  end

  test "create expression, from scratch, hello world instance Thing with hello world text Thing" do
    flunk("not implemented")
  end
end
