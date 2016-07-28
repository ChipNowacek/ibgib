defmodule WebGib.PageView do
  use WebGib.Web, :view

  def test_list do
    ["one", "two", "three^threegib"]
  end
end
