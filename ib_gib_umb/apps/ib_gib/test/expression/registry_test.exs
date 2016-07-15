defmodule IbGib.Expression.RegistryTest do
  use ExUnit.Case
  require Logger

  setup context do
    # ets doesn't like spaces in the names, and we use this for that?
    test_name = String.replace("#{context.test}", " ", "_")
    test_name = String.replace(test_name, ",", "_")
    {:ok, test_name: String.to_atom(test_name)}
    # {:ok, test_name: context.test}
  end

  @tag :capture_log
  test "start registry", %{test_name: test_name} do
    # Logger.debug "#{inspect test_name}"
    result = IbGib.Expression.Registry.start_link(test_name)
    Logger.debug inspect(result)
  end

  @tag :capture_log
  test "start registry twice should fail", %{test_name: test_name} do
    # name = "some_name"
    {result1, _term1} = IbGib.Expression.Registry.start_link(test_name)
    Logger.debug inspect("result1: #{result1}")
    assert result1 === :ok

    {result2, _term2}  = IbGib.Expression.Registry.start_link(test_name)
    Logger.debug inspect("result2: #{result2}")
    assert result2 === :error
  end

  @tag :capture_log
  test "register process", %{test_name: test_name} do
    # Logger.debug "#{inspect test_name}"
    _result = IbGib.Expression.Registry.start_link(test_name)

    {:ok, pid} = IbGib.Expression.start_link({:ib_gib, {"ib", "gib"}})

    register_result = IbGib.Expression.Registry.register("ib_gib", pid, test_name)

    assert register_result === :ok
  end

  @tag :capture_log
  test "register then get process", %{test_name: test_name} do
    # Logger.debug "#{inspect test_name}"
    _result = IbGib.Expression.Registry.start_link(test_name)

    {:ok, pid} = IbGib.Expression.start_link({:ib_gib, {"ib", "gib"}})

    register_result = IbGib.Expression.Registry.register("ib_gib", pid, test_name)

    assert register_result === :ok

    {get_result, get_pid} = IbGib.Expression.Registry.get_process("ib_gib", test_name)

    assert get_result === :ok
    assert get_pid === pid

    Logger.debug "get_pid: #{inspect get_pid}"
  end


  @tag :capture_log
  test "register, kill process, get process should fail", %{test_name: test_name} do
    # Logger.debug "#{inspect test_name}"
    _result = IbGib.Expression.Registry.start_link(test_name)

    {:ok, pid} = IbGib.Expression.start_link({:ib_gib, {"ib", "gib"}})

    Logger.debug "unlinking pid: #{inspect pid}"
    Process.unlink(pid)
    Logger.debug "unlinked pid: #{inspect pid}"

    register_result = IbGib.Expression.Registry.register("ib_gib", pid, test_name)

    assert register_result === :ok

    Logger.debug "killing pid"
    Process.exit(pid, :kill)
    Logger.debug "killed pid"

    # Register a dummy to ensure that the registry has processed the
    # handle_info
    _dummy_register_result = IbGib.Expression.Registry.register("ib_gib", pid, test_name)


    {get_result, get_term} = IbGib.Expression.Registry.get_process("ib_gib", test_name)

    assert get_result === :error
    assert get_term === :not_found

    Logger.debug "get_term: #{inspect get_term}"
  end

  @tag :capture_log
  test "get unregistered process should fail", %{test_name: test_name} do
    # Logger.debug "#{inspect test_name}"
    _result = IbGib.Expression.Registry.start_link(test_name)

    {:ok, _pid} = IbGib.Expression.start_link({:ib_gib, {"ib", "gib"}})

    {get_result, get_term} = IbGib.Expression.Registry.get_process("ib_gib", test_name)

    assert get_result === :error
    assert get_term === :not_found

    Logger.debug "get_term: #{get_term}"
  end
end
