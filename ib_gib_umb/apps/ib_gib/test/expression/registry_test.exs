defmodule IbGib.Expression.RegistryTest do
  use ExUnit.Case
  require Logger

  setup context do
    # ets doesn't like spaces in the names, and we use this for that?
    test_name = String.replace("#{context.test}", " ", "_")
    {:ok, test_name: test_name}
    # {:ok, test_name: context.test}
  end

  test "start registry", %{test_name: test_name} do
    # Logger.debug "#{inspect test_name}"
    result = IbGib.Expression.Registry.start_link(:test_name_1)
    Logger.debug inspect(result)
  end

  test "start registry twice should fail", %{test_name: test_name} do
    name = "some_name"
    result1 = IbGib.Expression.Registry.start_link(test_name)
    Logger.debug inspect(result1)

    result2 = IbGib.Expression.Registry.start_link(test_name)
    Logger.debug inspect(result2)
  end
end
