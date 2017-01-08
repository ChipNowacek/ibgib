defmodule IbGib.Data.Schemas.IbGib.ValidationTest do
  @moduledoc """
  This tests the IbGibModel changeset functionality.
  """


  use ExUnit.Case
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs
  alias IbGib.TestHelper
  alias IbGib.Data.Schemas.IbGibModel
  alias RandomGib.Get


  # @at_least_msg "should have at least %{count} item(s)"
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
  test "model, valid, minimum" do
    _ = Logger.debug "start...yo...."

    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(20),
                    gib: Get.some_letters(20),
                    # data: %{Get.some_letters(5) => Get.some_letters(@min_id_length)},
                    rel8ns: %{
                      Get.some_letters(5) => ["#{Get.some_letters(@min_ib_gib_length)}#{@delim}#{Get.some_letters(@min_ib_gib_length)}"]
                    }
                  })

    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.succeed_insert(changeset)
  end

  @tag :capture_log
  test "model, valid, with data" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(20),
                    gib: Get.some_letters(20),
                    data: %{Get.some_letters(5) => Get.some_letters(@min_id_length)},
                    rel8ns: %{
                      Get.some_letters(5) => ["#{Get.some_letters(@min_ib_gib_length)}#{@delim}#{Get.some_letters(@min_ib_gib_length)}"]
                    }
                  })
    _ = Logger.debug "changeset: #{inspect changeset}"

    TestHelper.succeed_insert(changeset)
  end

  @tag :capture_log
  test "model, valid, data is empty map" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(20),
                    gib: Get.some_letters(20),
                    data: %{},
                    rel8ns: %{
                      Get.some_letters(5) => ["#{Get.some_letters(@min_ib_gib_length)}#{@delim}#{Get.some_letters(@min_ib_gib_length)}"]
                    }
                  })
    _ = Logger.debug "changeset: #{inspect changeset}"

    TestHelper.succeed_insert(changeset)
  end

  @tag :capture_log
  test "model, valid, data is nil" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(20),
                    gib: Get.some_letters(20),
                    data: nil,
                    rel8ns: %{
                      Get.some_letters(5) => ["#{Get.some_letters(@min_ib_gib_length)}#{@delim}#{Get.some_letters(@min_ib_gib_length)}"]
                    }
                  })
    _ = Logger.debug "changeset: #{inspect changeset}"

    TestHelper.succeed_insert(changeset)
  end

  @tag :capture_log
  test "required, invalids, stuff aint provided" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                      #
                    })
    _ = Logger.debug "changeset: #{inspect changeset}"

    TestHelper.flunk_insert(changeset, :ib, @required_msg)
    TestHelper.flunk_insert(changeset, :gib, @required_msg)
    TestHelper.flunk_insert(changeset, :rel8ns, @required_msg)
  end

  @tag :capture_log
  test "ib and gib, invalid, too long" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: Get.some_letters(@max_id_length + 1), # too many
                    gib: Get.some_letters(@max_id_length + 1) # too many
                  })
    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :ib, @at_most_msg)
    TestHelper.flunk_insert(changeset, :gib, @at_most_msg)
  end

  @tag :capture_log
  test "ib and gib, invalid, too short" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                    ib: "", # too few
                    gib: "" # too few
                  })
    _ = Logger.debug "changeset: #{inspect changeset}"
    TestHelper.flunk_insert(changeset, :ib, @required_msg)
    TestHelper.flunk_insert(changeset, :gib, @required_msg)
  end

  @tag :capture_log
  test "rel8ns, invalid, no delim" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  rel8ns: %{Get.some_letters(5) => "some letters no delim"}
                })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations())
  end

  @tag :capture_log
  test "rel8ns, invalid, ib_gib too long" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  rel8ns: %{Get.some_letters(5) => Get.some_letters((2 * @max_id_length) + 2)}
                })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations())
  end

  @tag :capture_log
  test "rel8ns, invalid, ib_gib too long among other valid ib_gib" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
      rel8ns: %{
          Get.some_letters(5) => Get.some_letters(2),
          Get.some_letters(5) => Get.some_letters((2 * @max_id_length) + 2),
          Get.some_letters(5) => Get.some_letters(5)
      }
    })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations())
  end

  @tag :capture_log
  test "rel8ns, invalid, ib_gib list is empty" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                      rel8ns: %{"a" => []}
                    })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations())
  end

  @tag :capture_log
  test "rel8ns, invalid, rel8ns is empty map" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                      rel8ns: %{}
                    })
    TestHelper.flunk_insert(changeset, :rel8ns, emsg_invalid_relations())
  end

  @tag :capture_log
  test "data, invalid, key is atom" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  data: %{:some_atom => Get.some_letters(5)}
                })
    TestHelper.flunk_insert(changeset, :data, emsg_invalid_data())
  end

  @tag :capture_log
  test "data, invalid, value is atom" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  data: %{Get.some_letters(5) => :some_atom}
                })
    TestHelper.flunk_insert(changeset, :data, emsg_invalid_data())
  end

  @tag :capture_log
  test "data, invalid, key is integer" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  data: %{123 => Get.some_letters(5)}
                })
    TestHelper.flunk_insert(changeset, :data, emsg_invalid_data())
  end

  @tag :capture_log
  test "data, invalid, value is integer" do
    changeset = IbGibModel.changeset(%IbGibModel{}, %{
                  data: %{Get.some_letters(5) => 123}
                })
    TestHelper.flunk_insert(changeset, :data, emsg_invalid_data())
  end

  # @tag :capture_log
  # test "data, invalid, data is too big (THIS SHOULD ONLY BE RUN WITH CONSTANT CHANGED)" do
  #   # The max data size is currently set to 10 MB, making this unit test way
  #   # too long. So for a single run, I'm going to change that value to a smaller
  #   # max size and run it. Then, when done, we should change it back and
  #   # comment out this unit test.
  #   temp_max_size = 1000
  #   changeset = IbGibModel.changeset(%IbGibModel{}, %{
  #                 # data size is 1 (key = "a") + temp_max_size, so is too big.
  #                 data: %{"a" => Get.some_letters(temp_max_size)}
  #               })
  #   TestHelper.flunk_insert(changeset, :data, emsg_invalid_data())
  # end
end
