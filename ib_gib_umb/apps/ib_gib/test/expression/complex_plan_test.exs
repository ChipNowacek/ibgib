defmodule IbGib.Expression.ComplexPlanTest do
  @moduledoc """
  I've just added `update_rel8n` plan for updating an ibGib's rel8n (reference)
  for a given ibGib (see `IbGib.Transform.Plan.Factory.update_rel8n/5`).

  I am planning on creating more of these more complex plans going forward, so
  this test file is for those (until the point if/when it gets too large).
  """

  use ExUnit.Case
  require Logger

  alias IbGib.{Expression, Helper}
  alias IbGib.Transform.Plan.Factory, as: PlanFactory
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :test


  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  @tag :capture_log
  test "update_rel8n, rel8 a and b, update b, update_rel8n a-b to b2" do
    {:ok, root} = Expression.Supervisor.start_expression()

    # We start by creating two ibGib, a and b
    a_ib = "a ib #{RandomGib.Get.some_letters(5)}"
    a = root |> Expression.fork!(@test_identities_1, a_ib)
    a_info = a |> Expression.get_info!
    a_ib_gib = Helper.get_ib_gib!(a_info)
    _ = Logger.debug "a: #{inspect a}\na_info: #{inspect a_info}\na_ib_gib: #{a_ib_gib}"

    b_ib = "b ib #{RandomGib.Get.some_letters(5)}"
    b = root |> Expression.fork!(@test_identities_1, b_ib)
    b_info = b |> Expression.get_info!
    b_ib_gib = Helper.get_ib_gib!(b_info)
    _ = Logger.debug "b: #{inspect b}\nb_info: #{inspect b_info}\nb_ib_gib: #{b_ib_gib}"

    # Now we relate b to a via test_rel8n
    test_rel8n = "rel8d yo"
    a_rel8d_to_b = a |> Expression.rel8!(b, @test_identities_1, [test_rel8n])

    # Now we mut8 b to create a more recent version in its timeline.
    b2 = b |> Expression.mut8!(@test_identities_1, %{"yo" => "wha"})
    b2_info = b2 |> Expression.get_info!
    b2_ib_gib = Helper.get_ib_gib!(b2_info)

    {:ok, update_rel8n_plan} =
      PlanFactory.update_rel8n(@test_identities_1, test_rel8n, b_ib_gib, b2_ib_gib)

    a_rel8d_to_b2_instead =
      a_rel8d_to_b |> Expression.execute_plan!(update_rel8n_plan)
    a_rel8d_to_b2_instead_info = a_rel8d_to_b2_instead |> Expression.get_info!

    _ = Logger.debug("b_ib_gib: #{b_ib_gib}" |> ExChalk.bg_yellow |> ExChalk.blue)
    _ = Logger.debug("b2_ib_gib: #{b2_ib_gib}" |> ExChalk.bg_yellow |> ExChalk.blue)
    _ = Logger.debug("a_rel8d_to_b2_instead_info:\n#{inspect a_rel8d_to_b2_instead_info}" |> ExChalk.bg_yellow |> ExChalk.blue)

    rel8n_that_should_have_b2 = a_rel8d_to_b2_instead_info[:rel8ns][test_rel8n]
    assert rel8n_that_should_have_b2 === [b2_ib_gib]
  end

end
