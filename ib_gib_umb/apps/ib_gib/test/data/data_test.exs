defmodule IbGib.Data.DataTest do
  use ExUnit.Case
  require Logger
  # import Ecto.Query

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs
  # alias IbGib.TestHelper
  # alias IbGib.Data.Repo
  alias IbGib.Data
  # alias IbGib.Data.Schemas.IbGibModel
  alias RandomGib.Get

  # @at_least_msg "should have at least %{count} item(s)"
  # @at_most_msg "should be at most %{count} character(s)"
  # @required_msg "can't be blank"

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end


  @ib_gib_dna %{"dna" => ["ib^gib"]}

  @tag :capture_log
  test "save, no data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    # data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      # data: data,
      rel8ns: rel8ns
    }

    {:ok, :ok} = Data.save(model)
  end

  @tag :capture_log
  test "save!, no data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    # data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      # data: data,
      rel8ns: rel8ns
    }

    Data.save!(model)
  end

  @tag :capture_log
  test "load, no data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    # data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      # data: data,
      rel8ns: rel8ns
    }

    Data.save!(model)
    {:ok, got_model} = Data.load(ib, gib)

    _ = Logger.debug "got_model: #{inspect got_model}"
    assert got_model.ib === ib
    assert got_model.gib === model.gib
    assert got_model.rel8ns === model.rel8ns
  end

  @tag :capture_log
  test "load!, no data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    # data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      # data: data,
      rel8ns: rel8ns
    }

    Data.save!(model)
    got_model = Data.load!(ib, gib)

    _ = Logger.debug "got_model: #{inspect got_model}"
    assert got_model.ib === ib
    assert got_model.gib === model.gib
    assert got_model.rel8ns === model.rel8ns
  end

  @tag :capture_log
  test "save, simple data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      data: data,
      rel8ns: rel8ns
    }

    {:ok, :ok} = Data.save(model)
  end

  @tag :capture_log
  test "save!, simple data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      data: data,
      rel8ns: rel8ns
    }

    Data.save!(model)
  end

  @tag :capture_log
  test "load, simple data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      data: data,
      rel8ns: rel8ns
    }

    Data.save!(model)
    {:ok, got_model} = Data.load(ib, gib)

    _ = Logger.debug "got_model: #{inspect got_model}"
    assert got_model.ib === ib
    assert got_model.gib === model.gib
    assert got_model.rel8ns === model.rel8ns
  end

  @tag :capture_log
  test "load!, simple data" do
    ib = Get.some_letters(20)
    gib = Get.some_letters(20)
    data = %{Get.some_letters(5) => Get.some_letters(100)}
    rel8ns = @ib_gib_dna
    model = %{
      ib: ib,
      gib: gib,
      data: data,
      rel8ns: rel8ns
    }

    Data.save!(model)
    got_model = Data.load!(ib, gib)

    _ = Logger.debug "got_model: #{inspect got_model}"
    assert got_model.ib === ib
    assert got_model.gib === model.gib
    assert got_model.rel8ns === model.rel8ns
  end

end
