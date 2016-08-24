defmodule RandomGibTest do
  @moduledoc """
  For testing RandomGib functions. Most tests are here.
  """

  use ExUnit.Case
  require Logger
  doctest RandomGib.Get

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

  @tag :capture_log
  test "RandomGib.Get.some_characters, count only" do
    count = 1000
    result = RandomGib.Get.some_characters(count)
    assert String.length(result) === count
  end

  @tag :capture_log
  test "RandomGib.Get.some_characters, valid_characters)" do
    count = 1000
    valid_characters = "abAB^"
    result = RandomGib.Get.some_characters(count, valid_characters)
    Logger.debug "result: #{result}"
    assert String.length(result) === count

    # out of a thousand, there should be a freakin a usually
    assert String.contains?(result, "a")
    assert String.contains?(result, "^")
    # No letters/characters that are not explicitly given in valid_characters
    assert !String.contains?(result, "c")
    assert !String.contains?(result, "C")
    assert !String.contains?(result, "z")
    assert !String.contains?(result, "&")
  end


end
