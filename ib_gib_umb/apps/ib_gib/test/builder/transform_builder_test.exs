defmodule IbGib.Builder.TransformBuilderTest do
  @moduledoc """
  Test the transform builder, which builds transform plans. It used
  to be a factory module. Now it's a fluent-style builder module. I dunno
  what's going on anymore these days.
  """


  use ExUnit.Case
  require Logger

  # https://github.com/CrowdHailer/OK
  import OK, only: :macros

  import IbGib.{Expression, Helper}
  alias IbGib.TransformBuilder, as: TB

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
  test "plan, valid identities" do
    identities = @test_identities_1

    {:ok, plan} = TB.plan(identities, @default_transform_src)
  end

  @tag :capture_log
  test "plan, invalid identities" do
    identities = @test_identities_1 ++ ["invalid identity here NO GIB"]

    {:error, _reason} = TB.plan(identities, @default_transform_src)
  end

  @tag :capture_log
  test "plan yo, valid identities" do
    identities = @test_identities_1

    {:ok, plan} =
      TB.plan(identities, @default_transform_src)
      ~>> &TB.yo/2
  end

  @tag :capture_log
  test "plan yo, add fork, verbose" do
    # We will add a simple fork step, but using the more general and verbose
    # `add_step` function, which gives you named parameters.
    identities = @test_identities_1

    {:ok, plan} =
      TB.plan(identities, @default_transform_src)
      ~>> &TB.add_step(&1, %{
          # The name here is just for readability for us, since we aren't
          # referencing it in any subsequent steps.
          "name" => "just fork",
          "arg" => @root_ib_gib,
          "f" => %{
            "name" => "fork",
            "dest_ib" => "~[src.ib]"
          }
        })
      ~>> &TB.yo/2

    Logger.debug "plan: #{inspect plan}"
  end

  @tag :capture_log
  test "plan yo, add fork, concise" do
    # We will add a simple fork step, but using the concise `add_fork` function,
    # which is shorter, but does not give you named parameters.

    identities = @test_identities_1

    name = "just fork"
    arg = @root_ib_gib
    dest_ib = "~[src.ib]"

    {:ok, plan} =
      TB.plan(identities, @default_transform_src)
      ~>> &TB.add_fork(&1, name, arg, dest_ib)
      ~>> &TB.yo/2

    Logger.debug "plan: #{inspect plan}"
  end

  @tag :capture_log
  test "OK library, fn and & works, oks propagate" do
    result =
      {:ok, "yo"}
      ~>> fn(b) ->
            Logger.debug "fun b: #{b}"
            {:ok, "huh"}
          end
      ~>> fn(c) ->
            Logger.debug "fun c: #{c}"
            {:ok, "wha"}
          end
      ~>> &foo(&1, "arg b here", "arg c here")

    assert result == {:ok, "foo"}
  end

  @tag :capture_log
  test "OK library, error does not propagate" do
    result =
      {:ok, "yo"}
      ~>> fn(b) ->
            Logger.debug "fun b: #{b}"
            {:error, "huh"}
          end
      ~>> fn(c) ->
            Logger.debug "fun c: #{c}"
            {:ok, "wha"}
          end
      ~>> &foo(&1, "arg b here", "arg c here")

    assert result == {:error, "huh"}
  end

  def foo(a, b, c) do
    Logger.debug "foo a: #{a}\nb: #{b}\nc: #{c}"
    {:ok, "foo"}
  end

end
