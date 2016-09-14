defmodule IbGib.Expression.ExtraMut8Test do
  @moduledoc """
  I'm putting additional mut8 tests here. This includes
  `Mut8Factory.add_or_update_key/3`, `Mut8Factory.remove_key/2`, etc.

  The default mut8 transform adds/overwrites existing keys only.
  """


  use ExUnit.Case
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :test
  alias IbGib.{Helper, TransformFactory.Mut8Factory}
  import IbGib.Expression

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  @tag :capture_log
  test "mut8, remove key" do
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    test_key = "yo key uh huh"
    test_value = "yo test value uh huh"


    a =
      root
      |> fork!(@test_identities_1, Helper.new_id)
      |> mut8!(Mut8Factory.add_or_update_key(test_key, test_value))

    b =
      a
      |> mut8!(Mut8Factory.remove_key(test_key))

    b_info = b |> get_info!

    Logger.debug "b_info: #{inspect b_info}"

    assert map_size(b_info[:data]) === 0
  end

  @tag :capture_log
  test "mut8, rename key" do
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    test_key = "yo key uh huh"
    test_value = "yo test value uh huh"
    test_key2 = "key was renamed yo"

    test_identities_1 = @test_identities_1

    Logger.warn "test_identities_1: #{inspect @test_identities_1}"
    Logger.warn "test_identities_1: #{inspect @test_identities_1}"
    Logger.warn "test_identities_1: #{inspect @test_identities_1}"
    a =
      root
      |> fork!(test_identities_1, Helper.new_id)
      |> mut8!(Mut8Factory.add_or_update_key(test_key, test_value))

    b =
      a
      |> mut8!(Mut8Factory.rename_key(test_key, test_key2))

    b_info = b |> get_info!

    Logger.debug "b_info: #{inspect b_info}"

    assert Map.keys(b_info[:data]) === [test_key2]
  end

end
