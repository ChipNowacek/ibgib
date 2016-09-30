defmodule IbGib.Data.Schemas.Binary.QueryTest do
  @moduledoc """
  This is for testing the repo side of querying binaries, i.e. the data layer.

  Note: <<0>> is the null byte and when appended to a bitstring. It's probably
  not necessary but I'm doing it anyway.
  """


  use ExUnit.Case
  require Logger
  import Ecto.Query

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  alias IbGib.TestHelper
  alias IbGib.Data.Repo
  alias IbGib.Data.Schemas.BinaryModel
  alias RandomGib.Get
  import IbGib.Helper


  @at_least_msg "should have at least %{count} item(s)"
  @at_most_msg "should be at most %{count} character(s)"
  @required_msg "can't be blank"

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end


  @tag :capture_log
  test "insert, query" do
    data_size = 32
    binary_data = Get.some_letters(data_size) <> <<0>>
    binary_id = hash(binary_data)

    model = %{
      binary_id: binary_id,
      binary_data: binary_data
    }
    changeset = BinaryModel.changeset(%BinaryModel{}, model)

    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.succeed_insert(changeset)
    _ = Logger.debug "succeed insert. changeset: #{inspect changeset}"

    got_model =
      BinaryModel
      |> where(binary_id: ^binary_id)
      |> Repo.one

    _ = Logger.debug "got_model: #{inspect got_model}"
    assert got_model.binary_id === binary_id
    assert got_model.binary_data === binary_data
  end

  @tag :capture_log
  test "insert, query, 1 KB" do
    data_size = 1_024
    binary_data = Get.some_letters(data_size) <> <<0>>
    binary_id = hash(binary_data)

    model = %{
      binary_id: binary_id,
      binary_data: binary_data
    }
    changeset = BinaryModel.changeset(%BinaryModel{}, model)

    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.succeed_insert(changeset)
    _ = Logger.debug "succeed insert. changeset: #{inspect changeset}"

    got_model =
      BinaryModel
      |> where(binary_id: ^binary_id)
      |> Repo.one

    _ = Logger.debug "got_model: #{inspect got_model}"
    assert got_model.binary_id === binary_id
    assert got_model.binary_data === binary_data
  end

end
