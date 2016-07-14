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

  @tag :capture_log
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

    prop = "prop_name"
    prop_value = "prop value yo"
    {mut8_result, new_mut8_pid} = Expression.mut8(new_forked_pid, %{prop => prop_value})

    mut8d_info = Expression.get_info!(new_mut8_pid)
    Logger.debug "mut8d_info: #{inspect mut8d_info}"

    assert mut8d_info[:data][prop] === prop_value
  end

  @tag :capture_log
  test "create text" do
    # Randomized to keep unit tests from overlapping.
    text = "text_#{RandomGib.Get.some_letters(5)}"

    {result, expr_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(expr_pid, text)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"

    forked_info = Expression.get_info!(new_forked_pid)
    Logger.debug "forked_info: #{inspect forked_info}"

    assert forked_info[:ib] === text

    forked_ib_gib = Helper.get_ib_gib!(forked_info[:ib], forked_info[:gib])
    Logger.debug "forked_ib_gib: #{forked_ib_gib}"
  end

  @tag :capture_log
  test "create text, fork but with same ib" do
    # I'm not sure how this will work, but I think that the fork should go ahead
    # and take place, and it will be the ib_gib_history that will create a
    # different gib.

    # Randomized to keep unit tests from overlapping.
    text = "text_#{RandomGib.Get.some_letters(5)}"

    {result, expr_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(expr_pid, text)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"

    forked_info = Expression.get_info!(new_forked_pid)
    Logger.debug "forked_info: #{inspect forked_info}"

    assert forked_info[:ib] === text

    forked_ib_gib = Helper.get_ib_gib!(forked_info[:ib], forked_info[:gib])
    Logger.debug "forked_ib_gib: #{forked_ib_gib}"

    {fork_result_b, new_forked_pid_b} = Expression.fork(new_forked_pid, text)
    assert fork_result_b === :ok
    assert is_pid(new_forked_pid_b)
    assert new_forked_pid_b !== new_forked_pid

    Logger.debug "fork_result_b: #{fork_result_b}, new_forked_pid_b: #{inspect new_forked_pid_b}"

    forked_info_b = Expression.get_info!(new_forked_pid_b)
    Logger.debug "forked_info_b: #{inspect forked_info_b}"

    assert forked_info_b[:ib] === text

    forked_ib_gib_b = Helper.get_ib_gib!(forked_info_b[:ib], forked_info_b[:gib])
    Logger.debug "forked_ib_gib_b: #{forked_ib_gib_b}\nforked_ib_gib: #{forked_ib_gib}"

    assert forked_ib_gib_b !== forked_ib_gib

    # So even if two ib_gib things have the same `dest_ib`, if they fork
    # different `ib_gib` sources, then their histories will be different and
    # they will produce different output `ib_gib` - same `ib`, different `gib`.
  end

  @tag :capture_log
  test "create text from root, create text from root again" do
    # When the same ib_gib thing is created twice, the second one will error
    # out. I'm not sure if this is desired behavior or not!?

    # Randomized to keep unit tests from overlapping.
    text = "text_#{RandomGib.Get.some_letters(5)}"

    {result, ib_gib_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(ib_gib_pid, text)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"

    forked_info = Expression.get_info!(new_forked_pid)
    Logger.debug "forked_info: #{inspect forked_info}"

    assert forked_info[:ib] === text

    forked_ib_gib = Helper.get_ib_gib!(forked_info[:ib], forked_info[:gib])
    Logger.debug "forked_ib_gib: #{forked_ib_gib}"

    {fork_result_b, _reason_b} = Expression.fork(ib_gib_pid, text)
    Logger.debug "fork_result_b: #{inspect fork_result_b}"

    assert fork_result_b === :error
  end

  # @tag :capture_log
  test "create text, create instance from text" do
    # Pids are essentially references to objects. So that is why I'm going to_
    # start changing some of the _pid variables to the actual "instance" itself.

    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"

    {result, root} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_root_for_text_result, text_thing} = root |> Expression.fork(text_ib)
    assert fork_root_for_text_result === :ok
    assert is_pid(text_thing)

    text_info = text_thing |> Expression.get_info!
    Logger.debug "text_info: #{inspect text_info}"

    assert text_info[:ib] === text_ib

    text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])
    Logger.debug "text_ib_gib: #{text_ib_gib}"

    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {fork_text_for_instance_result, text_instance} =
      text_thing |> Expression.fork(text_instance_ib)

    assert fork_text_for_instance_result === :ok
    assert is_pid(text_instance)
    assert text_instance !== text_thing

    Logger.debug "fork_text_for_instance_result: #{fork_text_for_instance_result}, text_instance: #{inspect text_instance}"

    text_instance_info = text_instance |> Expression.get_info!
    Logger.debug "text_instance_info: #{inspect text_instance_info}"

    assert text_instance_info[:ib] === text_instance_ib

    text_instance_ib_gib = Helper.get_ib_gib!(text_instance_info[:ib], text_instance_info[:gib])
    Logger.debug "text_instance_ib_gib: #{text_instance_ib_gib}\ntext_ib_gib: #{text_ib_gib}"

    assert text_instance_ib_gib !== text_ib_gib

    # So even if two ib_gib things have the same `dest_ib`, if they fork
    # different `ib_gib` sources, then their histories will be different and
    # they will produce different output `ib_gib` - same `ib`, different `gib`.
  end
  #
  # test "create expression, from scratch, hello world Thing" do
  #   flunk("not implemented")
  # end
  #
  # test "create expression, from scratch, hello world instance Thing with hello world text Thing" do
  #   flunk("not implemented")
  # end
end
