defmodule IbGib.Data.Schemas.ValidateHelperTest do
  use ExUnit.Case, async: true

  alias IbGib.Data.Schemas.ValidateHelper

  @too_long_id "12345678901234567890123456789012345678901234567890123456789012345"
  @too_short_id ""

  test "single valid id" do
    result = ValidateHelper.id_array(:some_field, ["123", "456", "wefoijwefoij"])
    assert result === []
  end

  test "multiple valid id" do
    result = ValidateHelper.id_array(:some_field, ["ib", "aswoeijwfoijwef", "weoifjwoeifjwoeifj"])
    assert result === []
  end

  test "has id too short" do
    result = ValidateHelper.id_array(:some_field, [@too_short_id])
    assert result[:some_field] === ValidateHelper.invalid_id_length_msg()
  end

  test "multiple valid id with single too short" do
    result = ValidateHelper.id_array(:some_field, ["ib", "aswoeijwfoijwef", "weoifjwoeifjwoeifj", @too_short_id])
    assert result[:some_field] === ValidateHelper.invalid_id_length_msg
  end

  test "multiple valid id with single too long" do
    result = ValidateHelper.id_array(:some_field, ["ib", "aswoeijwfoijwef", "weoifjwoeifjwoeifj", @too_short_id])
    assert result[:some_field] === ValidateHelper.invalid_id_length_msg
  end

  test "has id too long" do
    result = ValidateHelper.id_array(:some_field, [@too_long_id])
    assert result[:some_field] === ValidateHelper.invalid_id_length_msg
  end

  test "not an array of string" do
    result = ValidateHelper.id_array(:some_field, {1, :atomyo})
    assert result[:some_field] === ValidateHelper.invalid_unknown_msg
  end
end
