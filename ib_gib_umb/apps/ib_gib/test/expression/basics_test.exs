defmodule IbGib.Expression.BasicsTest do
  @moduledoc """
  This exercises the very basics of manipulating ib_gib: create root, `fork`,
  `mut8`, `rel8`. I also have the `instance` in here, but I should probably move
  that out.
  """


  use ExUnit.Case
  require Logger

  alias IbGib.{Expression, Helper}
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :test


  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

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

    {fork_result, new_forked_pid} = Expression.fork(expr_pid, @test_identities_1, Helper.new_id)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"
  end

  @tag :capture_log
  test "create expression, from scratch, root Thing, fork, mut8" do
    {result, expr_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(expr_pid, @test_identities_1, Helper.new_id)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"

    forked_info = Expression.get_info!(new_forked_pid)
    Logger.debug "forked_info: #{inspect forked_info}"
    Logger.debug "forked_info: #{inspect forked_info}"
    Logger.debug "forked_info: #{inspect forked_info}"
    Logger.debug "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"
    Logger.warn "forked_info: #{inspect forked_info}"

    forked_ib_gib = Helper.get_ib_gib!(forked_info[:ib], forked_info[:gib])
    Logger.debug "forked_ib_gib: #{forked_ib_gib}"

    prop = "prop_name"
    prop_value = "prop value yo"
    {mut8_result, new_mut8_pid} = Expression.mut8(new_forked_pid, @test_identities_1, %{prop => prop_value}, @default_transform_options)

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

    {fork_result, new_forked_pid} = Expression.fork(expr_pid, @test_identities_1, text)
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
    # and take place, and it will be the ib_gib_dna that will create a
    # different gib.

    # Randomized to keep unit tests from overlapping.
    text = "text_#{RandomGib.Get.some_letters(5)}"

    {result, expr_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(expr_pid, @test_identities_1, text)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"

    forked_info = Expression.get_info!(new_forked_pid)
    Logger.debug "forked_info: #{inspect forked_info}"

    assert forked_info[:ib] === text

    forked_ib_gib = Helper.get_ib_gib!(forked_info[:ib], forked_info[:gib])
    Logger.debug "forked_ib_gib: #{forked_ib_gib}"

    {fork_result_b, new_forked_pid_b} = Expression.fork(new_forked_pid, @test_identities_1, text)
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
    # When the same ib_gib thing is created twice, the second one will NOT error
    # out. I'm not sure if this is desired behavior or not!?

    # Randomized to keep unit tests from overlapping.
    text = "text_#{RandomGib.Get.some_letters(5)}"

    {result, ib_gib_pid} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_result, new_forked_pid} = Expression.fork(ib_gib_pid, @test_identities_1, text)
    assert fork_result === :ok
    assert is_pid(new_forked_pid)

    Logger.debug "fork_result: #{fork_result}, new_forked_pid: #{inspect new_forked_pid}"

    forked_info = Expression.get_info!(new_forked_pid)
    Logger.debug "forked_info: #{inspect forked_info}"

    assert forked_info[:ib] === text

    forked_ib_gib = Helper.get_ib_gib!(forked_info[:ib], forked_info[:gib])
    Logger.debug "forked_ib_gib: #{forked_ib_gib}"

    {fork_result_b, _reason_b} = Expression.fork(ib_gib_pid, @test_identities_1, text)
    Logger.debug "fork_result_b: #{inspect fork_result_b}"

    # I've changed this so that it will NOT error out
    # assert fork_result_b === :error
    assert fork_result_b === :ok
  end

  @tag :capture_log
  test "create text, create instance from text" do
    # Pids are essentially references to objects. So that is why I'm going to_
    # start changing some of the _pid variables to the actual "instance" itself.

    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"

    {result, root} = Expression.Supervisor.start_expression()
    assert result === :ok

    {fork_root_for_text_result, text_thing} = root |> Expression.fork(@test_identities_1, text_ib)
    assert fork_root_for_text_result === :ok
    assert is_pid(text_thing)

    text_info = text_thing |> Expression.get_info!
    Logger.debug "text_info: #{inspect text_info}"

    assert text_info[:ib] === text_ib

    text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])
    Logger.debug "text_ib_gib: #{text_ib_gib}"

    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {fork_text_for_instance_result, text_instance} =
      text_thing |> Expression.fork(@test_identities_1, text_instance_ib)

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
  test "instance via instance function" do
    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    a_ib = "a_#{RandomGib.Get.some_letters(5)}"
    # {:ok, {a, a_info, a_ib_gib}} = root |> Expression.gib(:fork, @test_identities_1, a_ib)
    a = root |> Expression.fork!(@test_identities_1, a_ib)
    a_info = a |> Expression.get_info!
    a_ib_gib = Helper.get_ib_gib!(a_info)
    Logger.debug "a: #{inspect a}\na_info: #{inspect a_info}\na_ib_gib: #{a_ib_gib}"

    Logger.warn "gonna instance"
    {:ok, {new_a, a_instance}} = a |> Expression.instance(@test_identities_1, Helper.new_id)
    Logger.debug "a: #{inspect a}\n\nnew_a: #{inspect new_a}\ninstance: #{inspect a_instance}"

    new_a_info = new_a |> Expression.get_info!
    a_instance_info = a_instance |> Expression.get_info!

    _new_a_ib_gib = Helper.get_ib_gib!(new_a_info[:ib], new_a_info[:ib])
    a_instance_ib_gib = Helper.get_ib_gib!(a_instance_info[:ib], a_instance_info[:gib])

    Logger.debug "Infos\na: #{inspect a_info}\nnew_a: #{inspect new_a_info}\ninstance: #{inspect a_instance_info}"

    Logger.debug "new_a_info[:rel8ns][\"instance\"]: #{inspect new_a_info[:rel8ns]["instance"]}"
    Logger.debug "a_instance_ib_gib: #{inspect a_instance_ib_gib}"

    assert(
      new_a_info[:rel8ns]["instance"]
      |> Enum.map(&(String.split(&1, @delim) |> Enum.at(0)))
      |> Enum.member?(a_instance_info[:ib])
    )
    assert a_instance_info[:rel8ns]["instance_of"] |> Enum.member?(a_ib_gib)
  end

  @tag :capture_log
  test "fork with dest_ib" do
    {:ok, root} = Expression.Supervisor.start_expression()

    dest_ib = "test ib here yo"
    a = root |> Expression.fork!(@test_identities_1, dest_ib)
    a_info = a |> Expression.get_info!

    assert a_info[:ib] == dest_ib
  end

  @tag :capture_log
  test "fork twice, assert ancestor" do
    {:ok, root} = Expression.Supervisor.start_expression()

    dest_ib_a = "test ib a yo"
    a = root |> Expression.fork!(@test_identities_1, dest_ib_a)
    a_info = a |> Expression.get_info!
    a_ib_gib = Helper.get_ib_gib!(a_info)

    dest_ib_b = "test ib b huh"
    b = a |> Expression.fork!(@test_identities_1, dest_ib_b)
    b_info = b |> Expression.get_info!
    # b_ib_gib = Helper.get_ib_gib!(b_info)

    assert b_info[:rel8ns]["ancestor"] == [@root_ib_gib, a_ib_gib]
  end

end
