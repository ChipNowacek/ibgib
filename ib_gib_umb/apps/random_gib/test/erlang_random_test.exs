defmodule ErlangRandomTests do
  use ExUnit.Case
  require Logger

  @moduletag :capture_log

  # :random tests
  test "erlang random seed os timestamp" do
    result = :random.seed(:os.timestamp)
    _ = Logger.debug(result)
  end



  # :rand tests
  test "erlang rand uniform" do
    # If a process calls uniform/0 or uniform/1 without setting a seed first,
    # seed/1 is called automatically with the default algorithm and creates a
    # non-constant seed.

    result = :rand.uniform()
    _ = Logger.debug(result)
  end

  # fails because wrong argument
  # test "erlang rand seed erlang now" do
  #   result = :rand.seed(:erlang.now)
  #   _ = Logger.debug result
  # end

  test "erlang rand seed :exs1024" do
    _result = :rand.seed(:exs1024)
    # IO.inspect(result)
  end
end
