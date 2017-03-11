defmodule IbGib.Libs.OK do
  @moduledoc """
  Tests expected behavior for the third-party library: OK
  
  https://github.com/CrowdHailer/OK
  """

  require Logger
  require OK
  use ExUnit.Case

  import IbGib.Macros, only: [handle_ok_error: 1, handle_ok_error: 2]

  setup context do
    test_name = 
      "#{context.test}" 
      |> String.replace(" ", "_") |> String.replace(",", "_") 
      |> String.replace(".", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  @tag :capture_log
  test "OK.with, minimal" do
    result = 
      OK.with do
        a <- func_ok(42)
        OK.success a
      end
    assert result === {:ok, 42}
  end

  @tag :capture_log
  test "OK.with, minimal error returned in func line 1 of 2" do
    result = 
      OK.with do
        _ <- func_err(42)
        b <- func_ok(6 * 9) # should not get here
        OK.success b
      end
    assert result === {:error, 42}
  end

  @tag :capture_log
  test "OK.with, minimal error returned in func line 2 of 2" do
    result = 
      OK.with do
        _ <- func_ok(6 * 9)
        b <- func_err(42)
        OK.success b
      end
    assert result === {:error, 42}
  end

  @tag :capture_log
  test "OK.with, else clause" do
    result = 
      OK.with do
        _ <- func_ok(6 * 9)
        b <- func_err(:answer)
        OK.success b
      else
        :answer -> OK.failure 42
      end
    assert result === {:error, 42}
  end

  # @tag :capture_log
  test "OK.with, else clause, use default error macro, reason is bitstring" do
    result = 
      OK.with do
        _ <- func_ok(6 * 9)
        b <- func_err("answer")
        OK.success b # does not get here
      else
        reason -> OK.failure handle_ok_error(reason)
      end
    assert result === {:error, "answer"}
  end

  # @tag :capture_log
  test "OK.with, else clause, use default error macro, reason is atom" do
    result = 
      OK.with do
        _ <- func_ok(6 * 9)
        b <- func_err(:answer)
        OK.success b # does not get here
      else
        reason -> OK.failure handle_ok_error(reason)
      end
    assert result === {:error, "answer"}
  end

  # @tag :capture_log
  test "OK.with, else clause, use default error macro, reason is map" do
    error_map = %{question: 6 * 9, answer: 42}
    result = 
      OK.with do
        _ <- func_ok(6 * 9)
        b <- func_err(error_map)
        OK.success b # does not get here
      else
        reason -> OK.failure handle_ok_error(reason, log: true)
      end
    assert result === {:error, inspect error_map} # NB this calls inspect
  end

  defp func_ok(x) do
    {:ok, x}
  end
  
  defp func_err(x) do
    {:error, x}
  end
end
