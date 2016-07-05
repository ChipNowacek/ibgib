defmodule IbGib.Expression.RegistryTest do
  use ExUnit.Case
  require Logger

  test "start registry" do
    result = IbGib.Expression.Registry.start_link()
    Logger.debug inspect(result)
  end
end
