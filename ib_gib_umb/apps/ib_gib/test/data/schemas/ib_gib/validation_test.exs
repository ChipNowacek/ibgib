defmodule IbGib.Data.Schemas.IbGib.ValidationTest do
  use ExUnit.Case
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs
  alias IbGib.TestHelper
  # alias IbGib.Data.Repo
  alias IbGib.Data.Schemas.{IbGibModel,ValidateHelper}
  alias RandomGib.Get

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
  test "valid (minimum)" do
    Logger.debug "start...yo...."

    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(20),
                    gib: Get.some_letters(20),
                    # data: %{Get.some_letters(5) => Get.some_letters(min_id_length)},
                    rel8ns: %{
                      Get.some_letters(5) => ["#{Get.some_letters(min_ib_gib_length)}#{delim}#{Get.some_letters(min_ib_gib_length)}"]
                    }
                  })

    Logger.debug "changeset: #{inspect changeset}"
    TestHelper.succeed_insert(changeset)
  end

  @tag :capture_log
  test "valid (with data)" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(20),
                    gib: Get.some_letters(20),
                    data: %{Get.some_letters(5) => Get.some_letters(min_id_length)},
                    rel8ns: %{
                      Get.some_letters(5) => ["#{Get.some_letters(min_ib_gib_length)}#{delim}#{Get.some_letters(min_ib_gib_length)}"]
                    }
                  })
    Logger.debug "changeset: #{inspect changeset}"

    TestHelper.succeed_insert(changeset)
  end

  @tag :capture_log
  test "required stuff" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                      #
                    })
    Logger.debug "changeset: #{inspect changeset}"

    TestHelper.flunk_insert(changeset, :ib, @required_msg)
    TestHelper.flunk_insert(changeset, :gib, @required_msg)
    TestHelper.flunk_insert(changeset, :rel8ns, @required_msg)
  end

  @tag :capture_log
  test "invalid ib and gib (too long)" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(max_id_length+1), # too many
                    gib: Get.some_letters(max_id_length+1) # too many
                  })
    Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :ib, @at_most_msg)
    TestHelper.flunk_insert(changeset, :gib, @at_most_msg)
  end

  @tag :capture_log
  test "invalid ib and gib (too short)" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: "", # too few
                    gib: "" # too few
                  })
    Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :ib, @required_msg)
    TestHelper.flunk_insert(changeset, :gib, @required_msg)
  end

  @tag :capture_log
  test "invalid rel8ns" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  rel8ns: %{Get.some_letters(5) => "some letters no delim"}
                })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  end

  @tag :capture_log
  test "invalid rel8ns2" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  rel8ns: %{Get.some_letters(5) => Get.some_letters((2 * max_id_length)+2)}
                })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  end

  @tag :capture_log
  test "invalid rel8ns3" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
      rel8ns: %{
          Get.some_letters(5) => Get.some_letters(2),
          Get.some_letters(5) => Get.some_letters((2 * max_id_length)+2),
          Get.some_letters(5) => Get.some_letters(5)
      }
    })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  end

  @tag :capture_log
  test "invalid rel8ns ib_gib is empty" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                      rel8ns: %{"a" => []}
                    })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  end

  @tag :capture_log
  test "invalid rel8ns is empty map" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                      rel8ns: %{}
                    })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations)
  end
end
