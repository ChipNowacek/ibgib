defmodule IbGib.Data.Schemas.ValidateHelperTest do
  use ExUnit.Case, async: true
  require Logger
  alias RandomGib.Get

  alias IbGib.Data.Schemas.ValidateHelper

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


  test "map_of_ib_gib_arrays valid" do
    [
      %{"history" => ["ib^gib"]},

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

  test "map_of_ib_gib_arrays invalid, lengths" do
    [
      %{"history" => ["ib^"]},
      %{"history" => ["^gib"]},
      %{"history" => ["^"]},
      %{"history" => [""]},
      %{"history" => ["a#{random_max_id}#{@delim}#{random_max_id}"]},
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
