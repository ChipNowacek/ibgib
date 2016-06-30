defmodule RandomGibTest do
  use ExUnit.Case
  require Logger
  doctest RandomGib

  setup do
    :ok
  end

  @tag :capture_log
  test "RandomGib.Get.generate_seed" do
    result = RandomGib.Get.generate_seed()
    assert result === :ok
  end

  @tag :capture_log
  test "RandomGib.Get.one_of char list" do
    src = 'abcdefg'
    result = RandomGib.Get.one_of(src)
    Logger.debug("list: #{:erlang.iolist_to_binary(<<result>>)}")
    assert Enum.member?(src, result)
  end

  @tag :capture_log
  test "RandomGib.Get.one_of empty char list []" do
    src = []
    result = RandomGib.Get.one_of(src)
    assert result === nil
  end

  @tag :capture_log
  test "RandomGib.Get.one_of string (binary)" do
    src = "abcdefg"
    result = RandomGib.Get.one_of(src)
    Logger.debug("string: #{result}")
    assert String.contains?(src, result)
  end

  @tag :capture_log
  test "RandomGib.Get.one_of empty string (binary)" do
    src = ""
    result = RandomGib.Get.one_of(src)
    Logger.debug("string: #{result}")
    assert result === ""
  end

  @tag :capture_log
  test "RandomGib.Get.some_of char list" do
    src = 'abcdefg'
    result = RandomGib.Get.some_of(src)
    for c <- result do
      assert String.contains?(to_string(src), to_string(<<c>>))
    end
  end

  @tag :capture_log
  test "RandomGib.Get.some_of char list should not be empty" do
    src = 'a'
    for _ <- 1..100 do
      result = RandomGib.Get.some_of(src)
      assert Enum.count(result) > 0
    end
  end

  @tag :capture_log
  test "RandomGib.Get.some_of empty char list []" do
    src = []
    result = RandomGib.Get.some_of(src)
    assert result === []
  end

  @tag :capture_log
  test "RandomGib.Get.some_of string (binary)" do
    src = "abcdef"
    result = RandomGib.Get.some_of(src)
    Logger.debug("result string: #{result}")
    for <<c <- src>>, do: assert String.contains?(src, <<c>>)
  end

  @tag :capture_log
  test "RandomGib.Get.some_of string (binary) should not be empty" do
    src = "ab"
    for _ <- 1..100 do
      result = RandomGib.Get.some_of(src)
      Logger.debug("result string: #{result}")
      assert String.length(result) > 0
    end
  end

  @tag :capture_log
  test "RandomGib.Get.some_of empty string (binary) returns empty string" do
    src = ""
    result = RandomGib.Get.some_of(src)
    Logger.debug("string: #{result}")
    assert result === ""
  end

  @tag :capture_log
  test "RandomGib.Get.some_letters(1)" do
    result = RandomGib.Get.some_letters(1)
    assert String.length(result) === 1
  end

  @tag :capture_log
  test "RandomGib.Get.some_letters(100)" do
    result = RandomGib.Get.some_letters(100)
    assert String.length(result) === 100
  end
end
