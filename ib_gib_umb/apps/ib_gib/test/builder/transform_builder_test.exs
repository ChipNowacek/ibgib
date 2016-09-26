defmodule IbGib.Builder.TransformBuilderTest do
  @moduledoc """
  Test the transform builder, which builds transform plans. It used
  to be a factory module. Now it's a fluent-style builder module. I dunno
  what's going on anymore these days.
  """


  use ExUnit.Case
  require Logger

  # import IbGib.{Expression, Helper}
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

    {:ok, _plan} = TB.plan(identities, @default_transform_src, @default_transform_options)
  end

  @tag :capture_log
  test "plan, invalid identities" do
    identities = @test_identities_1 ++ ["invalid identity here NO GIB"]

    {:error, _reason} = TB.plan(identities, @default_transform_src, @default_transform_options)
  end

  @tag :capture_log
  test "plan yo, valid identities" do
    identities = @test_identities_1

    # need legit happy pipe.
    with \
      {:ok, plan} <- TB.plan(identities, @default_transform_src, @default_transform_options),
      {:ok, plan} <- TB.yo(plan) do

      Logger.debug "plan:\n#{inspect plan, [pretty: true]}"
      {:ok, plan}
    end
  end

  @tag :capture_log
  test "plan yo, add fork, verbose" do
    # We will add a simple fork step, but using the more general and verbose
    # `add_step` function, which gives you named parameters.
    identities = @test_identities_1

    {:ok, _plan} =
      with \
        {:ok, plan} <- TB.plan(identities, @default_transform_src, @default_transform_options),
        {:ok, plan} <-
          TB.add_step(plan, %{
            # The name here is just for readability for us, since we aren't
            # referencing it in any subsequent steps.
            "name" => "just fork",
            "f_data" => %{
              "type" => "fork",
              "dest_ib" => "[src.ib]"
            }
          }),
        {:ok, plan} <- TB.yo(plan) do

        Logger.debug "plan:\n#{inspect plan, [pretty: true]}"
        {:ok, plan}
      end

  end

  @tag :capture_log
  test "plan yo, add fork, concise" do
    # We will add a simple fork step, but using the concise `add_fork` function,
    # which is shorter, but does not give you named parameters.

    identities = @test_identities_1

    name = "just fork"
    dest_ib = "[src.ib]"

    with \
      {:ok, plan} <- TB.plan(identities, @default_transform_src, @default_transform_options),
      {:ok, plan} <- TB.add_fork(plan, name, dest_ib),
      {:ok, plan} <- TB.yo(plan) do

      Logger.debug "plan:\n#{inspect plan, [pretty: true]}"
      {:ok, plan}
    end
  end

end
