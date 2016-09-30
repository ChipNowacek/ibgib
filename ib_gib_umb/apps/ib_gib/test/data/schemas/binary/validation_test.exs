defmodule IbGib.Data.Schemas.Binary.ValidationTest do
  @moduledoc """
  This tests the BinaryModel changeset functionality.
  """


  use ExUnit.Case
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  alias IbGib.TestHelper
  alias IbGib.Data.Schemas.BinaryModel
  alias RandomGib.Get
  import IbGib.Helper


  @at_least_chars_msg "should be at least %{count} character(s)"
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
  test "model, valid" do
    _ = Logger.debug "start...yo...."

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
  end

  @tag :capture_log
  test "invalid, binary_id and binary_data are nil" do
    _ = Logger.debug "start...yo...."

    # data_size = 32
    # binary_data = Get.some_letters(data_size) <> <<0>>
    binary_data = nil
    # binary_id = hash(binary_data)
    binary_id = nil

    model = %{
      binary_id: binary_id,
      binary_data: binary_data
    }

    changeset = BinaryModel.changeset(%BinaryModel{}, model)

    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :binary_id, @required_msg)
    TestHelper.flunk_insert(changeset, :binary_data, @required_msg)
  end

  @tag :capture_log
  test "invalid, binary_id and binary_id are empty string" do
    _ = Logger.debug "start...yo...."

    # data_size = 32
    # binary_data = Get.some_letters(data_size) <> <<0>>
    binary_data = ""
    # binary_id = hash(binary_data)
    binary_id = ""

    model = %{
      binary_id: binary_id,
      binary_data: binary_data
    }

    changeset = BinaryModel.changeset(%BinaryModel{}, model)

    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :binary_id, @required_msg)
    TestHelper.flunk_insert(changeset, :binary_data, @required_msg)
  end

  @tag :capture_log
  test "binary_id, invalid, too long" do
    data_size = 32
    binary_data = Get.some_letters(data_size) <> <<0>>
    binary_id = hash(binary_data) <> "1"

    model = %{
      binary_id: binary_id,
      binary_data: binary_data
    }

    changeset = BinaryModel.changeset(%BinaryModel{}, model)

    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :binary_id, @at_most_msg)
  end

  @tag :capture_log
  test "binary_id, invalid, too short" do
    data_size = 32
    binary_data = Get.some_letters(data_size) <> <<0>>
    binary_id = hash(binary_data) |> String.slice(0, @hash_length - 1)

    model = %{
      binary_id: binary_id,
      binary_data: binary_data
    }

    changeset = BinaryModel.changeset(%BinaryModel{}, model)

    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :binary_id, @at_least_chars_msg)
  end

  #
  # @tag :capture_log
  # test "rel8ns, invalid, no delim" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                 rel8ns: %{Get.some_letters(5) => "some letters no delim"}
  #               })
  #   TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  # end
  #
  # @tag :capture_log
  # test "rel8ns, invalid, ib_gib too long" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                 rel8ns: %{Get.some_letters(5) => Get.some_letters((2 * @max_id_length) + 2)}
  #               })
  #   TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  # end
  #
  # @tag :capture_log
  # test "rel8ns, invalid, ib_gib too long among other valid ib_gib" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #     rel8ns: %{
  #         Get.some_letters(5) => Get.some_letters(2),
  #         Get.some_letters(5) => Get.some_letters((2 * @max_id_length) + 2),
  #         Get.some_letters(5) => Get.some_letters(5)
  #     }
  #   })
  #   TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  # end
  #
  # @tag :capture_log
  # test "rel8ns, invalid, ib_gib list is empty" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                     rel8ns: %{"a" => []}
  #                   })
  #   TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  # end
  #
  # @tag :capture_log
  # test "rel8ns, invalid, rel8ns is empty map" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                     rel8ns: %{}
  #                   })
  #   TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  # end
  #
  # @tag :capture_log
  # test "data, invalid, key is atom" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                 data: %{:some_atom => Get.some_letters(5)}
  #               })
  #   TestHelper.flunk_insert(changeset, :data, emsg_invalid_data)
  # end
  #
  # @tag :capture_log
  # test "data, invalid, value is atom" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                 data: %{Get.some_letters(5) => :some_atom}
  #               })
  #   TestHelper.flunk_insert(changeset, :data, emsg_invalid_data)
  # end
  #
  # @tag :capture_log
  # test "data, invalid, key is integer" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                 data: %{123 => Get.some_letters(5)}
  #               })
  #   TestHelper.flunk_insert(changeset, :data, emsg_invalid_data)
  # end
  #
  # @tag :capture_log
  # test "data, invalid, value is integer" do
  #   changeset = BinaryModel.changeset(%BinaryModel{}, %{
  #                 data: %{Get.some_letters(5) => 123}
  #               })
  #   TestHelper.flunk_insert(changeset, :data, emsg_invalid_data)
  # end
end
