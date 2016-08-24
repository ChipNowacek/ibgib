defmodule IbGib.Expression.GibStampsTest do
  use ExUnit.Case
  import IbGib.Expression
  alias IbGib.{Expression, Helper}
  require Logger

  use IbGib.Constants, :ib_gib

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  @tag :capture_log
  test "fork stamp" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    test = root |> fork!(test_ib, %{:gib_stamp => true})
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "fork NOT stamped, implicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    # opts = nada
    test = root |> fork!(test_ib)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "fork NOT stamped, explicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    opts = %{:gib_stamp => false}
    test = root |> fork!(test_ib, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "fork NOT stamped, empty map" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    opts = %{}
    test = root |> fork!(test_ib, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "fork NOT stamped, nil" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    opts = nil
    test = root |> fork!(test_ib, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

end
