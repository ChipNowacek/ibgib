defmodule WebGib.IbGibView do
  use WebGib.Web, :view

  def test_list do
    ["one", "two", "three^threegib", "three", "four^fourgib", "four"]
  end
end
