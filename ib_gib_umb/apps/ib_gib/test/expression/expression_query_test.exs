defmodule IbGib.Expression.ExpressionQueryTest do
  @moduledoc """
  This is for testing the query ib_gib, not the repo query. Since all this
  vocab is still new, I'll spell this out: This is for when you create a query
  ib_gib, just like you would create a fork, mut8, or rel8 transform ib_gib.
  See `IbGib.Expression.query/6` and `IbGib.Data.Schemas.IbGib.QueryTest`.
  """

  use ExUnit.Case
  use IbGib.Constants, :ib_gib
  alias IbGib.{Expression, Helper}
  # alias IbGib.Data.Repo
  import IbGib.Expression
  require Logger

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  test "Fork a couple ib, query, simplest baby steps" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    query_result = root |> query(%{},%{},%{},%{},%{})
    Logger.warn "query_result: #{inspect query_result}"
  end
end
