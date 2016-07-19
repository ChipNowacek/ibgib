defmodule IbGib.Data.CacheTest do
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
  test "start cache", %{test_name: test_name} do
    # Logger.debug "#{inspect test_name}"
    result = IbGib.Data.Cache.start_link(test_name)
    Logger.debug inspect(result)
  end

  @tag :capture_log
  test "start cache twice, should fail", %{test_name: test_name} do
    {result1, _term1} = IbGib.Data.Cache.start_link(test_name)
    Logger.debug inspect("result1: #{result1}")
    assert result1 === :ok

    {result2, _term2}  = IbGib.Data.Cache.start_link(test_name)
    Logger.debug inspect("result2: #{result2}")
    assert result2 === :error
  end

  @tag :capture_log
  test "start cache, put value", %{test_name: test_name} do
    _result = IbGib.Data.Cache.start_link(test_name)

    key = "key_#{test_name}"
    value = %{"abc" => 12345}

    put_result = IbGib.Data.Cache.put(key, value, test_name)

    assert put_result === {:ok, :ok}
  end

  @tag :capture_log
  test "start cache, put value, get value", %{test_name: test_name} do
    _result = IbGib.Data.Cache.start_link(test_name)

    key = "key_#{test_name}"
    value = %{"abc" => 12345}

    put_result = IbGib.Data.Cache.put(key, value, test_name)

    assert put_result === {:ok, :ok}

    {get_result, get_value} = IbGib.Data.Cache.get(key, test_name)

    assert get_result === :ok
    assert get_value === value
  end

  @tag :capture_log
  test "dont start cache, put value", %{test_name: test_name} do
    # result = IbGib.Data.Cache.start_link(test_name)

    key = "key_#{test_name}"
    value = %{"abc" => 12345}

    put_result = IbGib.Data.Cache.put(key, value)

    assert put_result === {:ok, :ok}
  end

  @tag :capture_log
  test "dont start cache, put value, get value", %{test_name: test_name} do
    key = "some_key#{test_name}"
    value = %{"abc" => 12345}

    put_result = IbGib.Data.Cache.put(key, value)

    assert put_result === {:ok, :ok}

    {get_result, get_value} = IbGib.Data.Cache.get(key)

    assert get_result === :ok
    assert get_value === value
  end

  #
  # @tag :capture_log
  # test "register then get process", %{test_name: test_name} do
  #   # Logger.debug "#{inspect test_name}"
  #   result = IbGib.Data.Cache.start_link(test_name)
  #
  #   {:ok, pid} = IbGib.Expression.start_link({"ib", "gib"})
  #
  #   register_result = IbGib.Data.Cache.register("ib_gib", pid, test_name)
  #
  #   assert register_result === :ok
  #
  #   {get_result, get_pid} = IbGib.Data.Cache.get_process("ib_gib", test_name)
  #
  #   assert get_result === :ok
  #   assert get_pid === pid
  #
  #   Logger.debug "get_pid: #{inspect get_pid}"
  # end


  # @tag :capture_log
  # test "get unregistered process should fail", %{test_name: test_name} do
  #   # Logger.debug "#{inspect test_name}"
  #   result = IbGib.Data.Cache.start_link(test_name)
  #
  #   {:ok, pid} = IbGib.Expression.start_link({"ib", "gib"})
  #
  #   {get_result, get_term} = IbGib.Data.Cache.get_process("ib_gib", test_name)
  #
  #   assert get_result === :error
  #   assert get_term === :not_found
  #
  #   Logger.debug "get_term: #{get_term}"
  # end
end
