defmodule IbGib.Data.Schemas.ValidateHelperTest do
  use ExUnit.Case, async: true
  require Logger
  alias RandomGib.Get

  alias IbGib.Data.Schemas.ValidateHelper
  use IbGib.Constants, :ib_gib

  @min 1
  @max 64
  @min_ib_gib (@min*2)+1
  @max_ib_gib (@max*2)+1
  @delim "^"

  def random_min_id, do: Get.some_letters(@min)
  def random_max_id, do: Get.some_letters(@max)

  def too_long_id, do: Get.some_letters(@max+1)
  def too_short_id, do: ""

  def random_mid_id, do: Get.some_letters(10)

  def random_valid_ib_gib do
    Get.one_of([
      "#{random_min_id}#{@delim}#{random_min_id}",
      "#{random_min_id}#{@delim}#{random_max_id}",
      "#{random_max_id}#{@delim}#{random_min_id}",
      "#{random_max_id}#{@delim}#{random_max_id}",
      "#{random_mid_id}#{@delim}#{random_mid_id}",
    ])
  end


  @tag :capture_log
  test "valid ib_gibs" do
    [
      "#{random_min_id}#{@delim}#{random_min_id}",
      "#{random_min_id}#{@delim}#{random_max_id}",
      "#{random_max_id}#{@delim}#{random_min_id}",
      "#{random_max_id}#{@delim}#{random_max_id}",
      "#{random_mid_id}#{@delim}#{random_mid_id}",
    ]
    |> Enum.each(fn(ib_gib) ->
      assert ValidateHelper.valid_ib_gib?(ib_gib)
    end)
  end

  @tag :capture_log
  test "invalid ib_gib, not string" do
    [
      :some_atom,
      ["some", "list"],
      %{"some" => :map},
      {:some, :tuple},
    ]
    |> Enum.each(fn(ib_gib) ->
      assert !ValidateHelper.valid_ib_gib?(ib_gib)
    end)
  end

  @tag :capture_log
  test "invalid ib_gib, no delim" do
    [
      "#{random_min_id}#{random_min_id}",
      "#{random_min_id}#{random_max_id}",
      "#{random_max_id}#{random_min_id}",
      "#{random_max_id}#{random_max_id}",
      "#{random_mid_id}#{random_mid_id}",
    ]
    |> Enum.each(fn(ib_gib) ->
      assert !ValidateHelper.valid_ib_gib?(ib_gib)
    end)
  end

  @tag :capture_log
  test "invalid ib_gib, ib_gib lengths" do
    [
      # a is extra character
      "a#{random_max_id}#{@delim}#{random_max_id}",
      "#{random_max_id}#{@delim}a#{random_max_id}",
    ]
    |> Enum.each(fn(ib_gib) ->
      assert !ValidateHelper.valid_ib_gib?(ib_gib)
    end)
  end

  @tag :capture_log
  test "invalid ib_gib, ib lengths" do
    [
      "#{@delim}#{random_min_id}",
      "#{@delim}#{random_max_id}",
      "a#{random_max_id}#{@delim}#{random_min_id}",
      "a#{random_max_id}#{@delim}#{random_max_id}",
    ]
    |> Enum.each(fn(ib_gib) ->
      assert !ValidateHelper.valid_ib_gib?(ib_gib)
    end)
  end

  @tag :capture_log
  test "invalid ib_gib, gib lengths" do
    [
      "#{random_min_id}#{@delim}",
      "#{random_max_id}#{@delim}",
      "#{random_min_id}#{@delim}a#{random_max_id}",
      "#{random_max_id}#{@delim}a#{random_max_id}",
    ]
    |> Enum.each(fn(ib_gib) ->
      assert !ValidateHelper.valid_ib_gib?(ib_gib)
    end)
  end


  @tag :capture_log
  test "map_of_ib_gib_arrays valid" do
    [
      %{"dna" => ["ib^gib"]},

      %{"a" => [random_valid_ib_gib]},

      %{"a" => [random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib],

      "b" => [random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib]
      },
    ]
    |> Enum.each(fn(test_map) ->
      Logger.debug "test_map: #{inspect test_map}"
      assert ValidateHelper.map_of_ib_gib_arrays?(:some_field, test_map)
    end)
  end

  @tag :capture_log
  test "map_of_ib_gib_arrays invalid, lengths" do
    [
      %{"dna" => ["ib^"]},
      %{"dna" => ["^gib"]},
      %{"dna" => ["^"]},
      %{"dna" => [""]},
      %{"dna" => ["a#{random_max_id}#{@delim}#{random_max_id}"]},
      %{"" => ["ib^gib"]},

      %{"a" => [random_valid_ib_gib, ""]},

      %{
        "a" => [random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib],

        "b" => [random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, random_valid_ib_gib, ""]
      },
    ]
    |> Enum.each(fn(test_map) ->
      Logger.debug "test_map: #{inspect test_map}"
      assert !ValidateHelper.map_of_ib_gib_arrays?(:some_field, test_map)
    end)
  end

  # ----------------------------------------------------------------------------
  # valid_data?
  # ----------------------------------------------------------------------------

  @tag :capture_log
  test "valid_data?, valid, empty map" do
    test_map = %{}

    assert ValidateHelper.valid_data?(:some_field, test_map)
  end

  @tag :capture_log
  test "valid_data?, valid, nil map" do
    test_map = nil

    assert ValidateHelper.valid_data?(:some_field, test_map)
  end

  @tag :capture_log
  test "valid_data?, invalid, other" do
    [
      :some_atom,
      "some string",
      123
    ]
    |> Enum.each(fn(test_non_map) ->
      assert !ValidateHelper.valid_data?(:some_field, test_non_map)
    end)
  end

  @tag :capture_log
  test "valid_data?, invalid, non-string keys/values" do
    [
      %{:some_atom => "some string"},
      %{123 => "some string"},
      %{"some string" => :some_atom},
      %{"some string" => 123},
      %{"a" => "a value", "b" => "b value", :some_atom => "some string"},
      %{"a" => "a value", "b" => "b value", 123 => "some string"},
      %{"a" => "a value", "b" => "b value", "some string" => :some_atom},
      %{"a" => "a value", "b" => "b value", "some string" => 123},
    ]
    |> Enum.each(fn(test_non_map) ->
      assert !ValidateHelper.valid_data?(:some_field, test_non_map)
    end)
  end

  @tag :capture_log
  test "valid_data?, valid, at max data size" do
    test_max_size = 100000
    test_value_length = div(test_max_size, 2) - 1 # reserve 1 length for key
    test_value = Enum.reduce(1..test_value_length, "", fn(_, acc) -> "a" <> acc end)
    Logger.debug "test_value: #{test_value}"
    # test_value = Enum.reduce([0, 5], fn(x, acc) -> "a" <<>> acc end)
    test_map = %{
      "a" => test_value,
      "b" => test_value
    }
    assert ValidateHelper.valid_data?(:some_field, test_map, test_max_size)
  end

  @tag :capture_log
  test "valid_data?, invalid, key puts it just over max data size" do
    test_max_size = 100000
    test_value_length = div(test_max_size, 2) - 1 # reserve 1 length for key
    test_value = Enum.reduce(1..test_value_length, "", fn(_, acc) -> "a" <> acc end)
    Logger.debug "test_value: #{test_value}"
    # test_value = Enum.reduce([0, 5], fn(x, acc) -> "a" <<>> acc end)
    test_map = %{
      "a" => test_value,
      "b" => test_value,
      "c" => "" # Just the key itself should make it too big
    }
    assert !ValidateHelper.valid_data?(:some_field, test_map, test_max_size)
  end

  @tag :capture_log
  test "valid_data?, invalid, value puts it just over max data size" do
    test_max_size = 100000
    test_value_length = div(test_max_size, 2) - 2
    test_value = Enum.reduce(1..test_value_length, "", fn(_, acc) -> "a" <> acc end)
    Logger.debug "test_value: #{test_value}"
    # test_value = Enum.reduce([0, 5], fn(x, acc) -> "a" <<>> acc end)
    test_map = %{
      "a" => test_value,
      "b" => test_value,
      # This takes a little thought, but the -2 test value length reserves
      # a total of 2 bytes to still be valid. So a third key: "c" => "c" would
      # still be valid. But the extra "c" juts puts it over the max size.
      "c" => "cc"
    }
    assert !ValidateHelper.valid_data?(:some_field, test_map, test_max_size)
  end

  # test "single valid id" do
  #   result = ValidateHelper.id_array(:some_field, ["123", "456", "wefoijwefoij"])
  #   assert result === []
  # end
  #
  # test "multiple valid id" do
  #   result = ValidateHelper.id_array(:some_field, ["ib", "aswoeijwfoijwef", "weoifjwoeifjwoeifj"])
  #   assert result === []
  # end
  #
  # test "has id too short" do
  #   result = ValidateHelper.id_array(:some_field, [@too_short_id])
  #   assert result[:some_field] === ValidateHelper.invalid_id_length_msg()
  # end
  #
  # test "multiple valid id with single too short" do
  #   result = ValidateHelper.id_array(:some_field, ["ib", "aswoeijwfoijwef", "weoifjwoeifjwoeifj", @too_short_id])
  #   assert result[:some_field] === ValidateHelper.invalid_id_length_msg
  # end
  #
  # test "multiple valid id with single too long" do
  #   result = ValidateHelper.id_array(:some_field, ["ib", "aswoeijwfoijwef", "weoifjwoeifjwoeifj", @too_short_id])
  #   assert result[:some_field] === ValidateHelper.invalid_id_length_msg
  # end
  #
  # test "has id too long" do
  #   result = ValidateHelper.id_array(:some_field, [@too_long_id])
  #   assert result[:some_field] === ValidateHelper.invalid_id_length_msg
  # end
  #
  # test "not an array of string" do
  #   result = ValidateHelper.id_array(:some_field, {1, :atomyo})
  #   assert result[:some_field] === ValidateHelper.invalid_unknown_msg
  # end
end
