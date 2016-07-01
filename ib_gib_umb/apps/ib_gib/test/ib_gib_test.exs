defmodule IbGibTest do
  use ExUnit.Case
  doctest IbGib

  test "create expression, from scratch, root Thing" do
    result = IbGib.Expression.Supervisor.start_expression()
    inspect result
  end

  test "create expression, from scratch, text Thing" do
    flunk("not implemented")
    # fork_transform = IbGib.TransformFactory.
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
