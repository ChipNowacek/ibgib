defmodule IbGibTest do
  @moduledoc """
  Test things common to the entire app.

  This is also where I've imported doctests.
  """
  use ExUnit.Case
  require Logger

  use IbGib.Constants, :ib_gib

  doctest IbGib
  doctest IbGib.TransformFactory
  doctest IbGib.Helper
  doctest IbGib.Auth.Identity
  # doctest IbGib.Auth.Session
  doctest IbGib.Data.Schemas.ValidateHelper
  doctest IbGib.TransformBuilder

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
  test "root" do
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()
    info = root |> get_info!
    assert info.ib == "ib"
    assert info.gib == "gib"
  end

  @tag :capture_log
  test "default ib_gib expressions" do
    ["fork", "mut8", "rel8", "query"]
    |> Enum.each(fn(test_ib) ->
         test_ib_gib = "#{test_ib}#{@delim}gib"
         Logger.debug "test_ib_gib: #{test_ib_gib}"
         {:ok, test} = IbGib.Expression.Supervisor.start_expression(test_ib_gib)
         test_info = test |> get_info!
         assert test_info.ib == test_ib
         assert test_info.gib == "gib"
       end)
  end
end
