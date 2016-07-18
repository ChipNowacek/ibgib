defmodule IbGib.ExpressionTest do
  use ExUnit.Case
  alias IbGib.{Expression, Helper}
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

    assert mut8_result === :ok

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

  @tag :capture_log
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
  end

  @tag :capture_log
  test "hello world then fork instance, text then fork instance, relate" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(hw_ib)
    # hw_info = hw_thing |> Expression.get_info!
    # hw_ib_gib = Helper.get_ib_gib!(hw_info[:ib], hw_info[:gib])

    Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw_instance} =
      hw |> Expression.fork(hw_instance_ib)
    hw_instance_info = hw_instance |> Expression.get_info!
    hw_instance_ib_gib = Helper.get_ib_gib!(hw_instance_info[:ib], hw_instance_info[:gib])

    Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, text_instance} =
      text |> Expression.fork(text_instance_ib)
    text_instance_info = text_instance |> Expression.get_info!
    text_instance_ib_gib = Helper.get_ib_gib!(text_instance_info[:ib], text_instance_info[:gib])

    Logger.debug "gonna rel8"
    {:ok, {hw_instance_rel8d, text_instance_rel8d}} =
      hw_instance |> Expression.rel8(text_instance)

    assert is_pid(hw_instance_rel8d)
    assert is_pid(text_instance_rel8d)

    assert hw_instance !== hw_instance_rel8d
    assert text_instance !== text_instance_rel8d

    hw_instance_rel8d_info = hw_instance_rel8d |> Expression.get_info!
    _hw_instance_rel8d_ib_gib = Helper.get_ib_gib!(hw_instance_rel8d_info[:ib], hw_instance_rel8d_info[:gib])
    Logger.debug "hw_instance_rel8d_info: #{inspect hw_instance_rel8d_info}"
    text_instance_rel8d_info = text_instance_rel8d |> Expression.get_info!
    _text_instance_rel8d_ib_gib = Helper.get_ib_gib!(text_instance_rel8d_info[:ib], text_instance_rel8d_info[:gib])
    Logger.debug "text_instance_rel8d_info: #{inspect text_instance_rel8d_info}"

    assert hw_instance_rel8d_info[:relations]["rel8d"] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:relations]["rel8d"] === [hw_instance_ib_gib]
  end

  @tag :capture_log
  test "hello world then fork instance, text then fork instance, relate property" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(hw_ib)
    # hw_info = hw_thing |> Expression.get_info!
    # hw_ib_gib = Helper.get_ib_gib!(hw_info[:ib], hw_info[:gib])

    Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw_instance} =
      hw |> Expression.fork(hw_instance_ib)
    hw_instance_info = hw_instance |> Expression.get_info!
    hw_instance_ib_gib = Helper.get_ib_gib!(hw_instance_info[:ib], hw_instance_info[:gib])

    Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, text_instance} =
      text |> Expression.fork(text_instance_ib)
    text_instance_info = text_instance |> Expression.get_info!
    text_instance_ib_gib = Helper.get_ib_gib!(text_instance_info[:ib], text_instance_info[:gib])

    Logger.debug "gonna rel8 'text property'"
    {:ok, {hw_instance_rel8d, text_instance_rel8d}} =
      hw_instance |> Expression.rel8(text_instance, ["prop", "text"], ["prop_of"])

    assert is_pid(hw_instance_rel8d)
    assert is_pid(text_instance_rel8d)

    assert hw_instance !== hw_instance_rel8d
    assert text_instance !== text_instance_rel8d

    hw_instance_rel8d_info = hw_instance_rel8d |> Expression.get_info!
    _hw_instance_rel8d_ib_gib = Helper.get_ib_gib!(hw_instance_rel8d_info[:ib], hw_instance_rel8d_info[:gib])
    Logger.debug "hw_instance_rel8d_info: #{inspect hw_instance_rel8d_info}"
    text_instance_rel8d_info = text_instance_rel8d |> Expression.get_info!
    _text_instance_rel8d_ib_gib = Helper.get_ib_gib!(text_instance_rel8d_info[:ib], text_instance_rel8d_info[:gib])
    Logger.debug "text_instance_rel8d_info: #{inspect text_instance_rel8d_info}"

    assert hw_instance_rel8d_info[:relations]["rel8d"] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:relations]["rel8d"] === [hw_instance_ib_gib]
    assert hw_instance_rel8d_info[:relations]["prop"] === [text_instance_ib_gib]
    assert hw_instance_rel8d_info[:relations]["text"] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:relations]["prop_of"] === [hw_instance_ib_gib]
  end

  @tag :capture_log
  test "create expression, from scratch, hello world instance Thing with hello world text Thing" do
    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(hw_ib)

    Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, {hw_instance, _hw_instance_info, _hw_instance_ib_gib}} =
      hw |> Expression.gib(:fork, hw_instance_ib)

    Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, {text_instance, _text_instance_info, _text_instance_ib_gib}} =
      text |> Expression.gib(:fork, text_instance_ib)

    Logger.debug "gonna rel8 'text property'"
    {
      :ok,
      {_hw_instance, hw_instance_info, _hw_instance_ib_gib},
      {text_instance, _text_instance_info, _text_instance_ib_gib}
    } =
      hw_instance |> Expression.gib(:rel8, text_instance, ["prop", "text"], ["prop_of"])

    {:ok, {_text_instance, text_instance_info, _text_instance_ib_gib}} =
      text_instance
      |> Expression.gib(:mut8, %{"content" => "Hello World!"})

    Logger.debug "hw_instance_info: #{inspect hw_instance_info}"
    Logger.debug "text_instance_info: #{inspect text_instance_info}"
  end

  @tag :capture_log
  test "fork via gib" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, {hw, hw_info, hw_ib_gib}} = root |> Expression.gib(:fork, hw_ib)
    Logger.debug "hw: #{inspect hw}\nhw_info: #{inspect hw_info}\nhw_ib_gib: #{hw_ib_gib}"

    hw_info2 = hw |> Expression.get_info!
    assert hw_info === hw_info2

    hw_ib_gib2 = Helper.get_ib_gib!(hw_info[:ib], hw_info[:gib])
    assert hw_ib_gib === hw_ib_gib2
  end

  @tag :capture_log
  test "mut8 via gib" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, {hw, hw_info, hw_ib_gib}} = root |> Expression.gib(:fork, hw_ib)
    Logger.debug "hw: #{inspect hw}\nhw_info: #{inspect hw_info}\nhw_ib_gib: #{hw_ib_gib}"

    prop = "prop_name"
    prop_value = "prop value yo"
    # I would normally just say hw = hw ..., but since we'll do asserts, I'm
    # suffixing this with 2: hw2.
    {:ok, {hw2, hw2_info, hw2_ib_gib}} = hw |> Expression.gib(:mut8, %{prop => prop_value})
    Logger.debug "hw2: #{inspect hw2}\nhw2_info: #{inspect hw2_info}\nhw2_ib_gib: #{hw2_ib_gib}"
  end

  @tag :capture_log
  test "rel8 via gib" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    a_ib = "a_#{RandomGib.Get.some_letters(5)}"
    {:ok, {a, a_info, a_ib_gib}} = root |> Expression.gib(:fork, a_ib)
    Logger.debug "a: #{inspect a}\na_info: #{inspect a_info}\na_ib_gib: #{a_ib_gib}"

    b_ib = "b_#{RandomGib.Get.some_letters(5)}"
    {:ok, {b, b_info, b_ib_gib}} = root |> Expression.gib(:fork, b_ib)
    Logger.debug "b: #{inspect b}\nb_info: #{inspect b_info}\nb_ib_gib: #{b_ib_gib}"

    {
      :ok,
      {new_a, new_a_info, new_a_ib_gib},
      {new_b, new_b_info, new_b_ib_gib}
    } = a |> Expression.gib(:rel8, b)

    assert new_a_info === new_a |> Expression.get_info!
    assert new_b_info === new_b |> Expression.get_info!

    assert new_a_ib_gib === Helper.get_ib_gib!(new_a_info[:ib], new_a_info[:gib])
    assert new_b_ib_gib === Helper.get_ib_gib!(new_b_info[:ib], new_b_info[:gib])
  end
end
