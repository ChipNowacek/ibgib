defmodule IbGib.Expression.GibStampsTest do
  @moduledoc """
  Test stamping the `gib` of an ib_gib to be "official".
  """


  use ExUnit.Case
  require Logger

  import IbGib.Expression
  alias IbGib.{Expression, Helper}
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

  # ----------------------------------------------------------------------------
  # fork
  # ----------------------------------------------------------------------------

  @tag :capture_log
  test "fork stamp" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    test = root |> fork!(@test_identities_1, test_ib, %{"gib_stamp" => "true"})
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "fork NOT stamped, implicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    # opts = nada
    test = root |> fork!(@test_identities_1, test_ib)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "fork NOT stamped, explicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    opts = %{"gib_stamp" => "false"}
    test = root |> fork!(@test_identities_1, test_ib, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "fork NOT stamped, empty map" do
    {:ok, root} = Expression.Supervisor.start_expression()

    test_ib = "test ib here uh hrm"
    opts = %{}
    test = root |> fork!(@test_identities_1, test_ib, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  # yagni
  # @tag :capture_log
  # test "fork NOT stamped, nil" do
  #   {:ok, root} = Expression.Supervisor.start_expression()
  #
  #   test_ib = "test ib here uh hrm"
  #   opts = nil
  #   test = root |> fork!(@test_identities_1, test_ib, opts)
  #   test_info = test |> get_info!
  #   test_gib = test_info[:gib]
  #
  #   assert !Helper.gib_stamped?(test_gib)
  # end

  # ----------------------------------------------------------------------------
  # mut8
  # ----------------------------------------------------------------------------

  @tag :capture_log
  test "mut8 stamp" do
    {:ok, root} = Expression.Supervisor.start_expression()

    new_data = %{"data" => "some data here"}
    test = root |> mut8!(@test_identities_1, new_data, %{"gib_stamp" => "true"})
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "mut8 NOT stamped, implicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()

    new_data = %{"data" => "some data here"}
    # opts = nada
    test = root |> mut8!(@test_identities_1, new_data)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "mut8 NOT stamped, explicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()

    new_data = %{"data" => "some data here"}
    opts = %{"gib_stamp" => "false"}
    test = root |> mut8!(@test_identities_1, new_data, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "mut8 NOT stamped, empty map" do
    {:ok, root} = Expression.Supervisor.start_expression()

    new_data = %{"data" => "some data here"}
    opts = %{}
    test = root |> mut8!(@test_identities_1, new_data, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  # @tag :capture_log
  # test "mut8 NOT stamped, nil" do
  #   {:ok, root} = Expression.Supervisor.start_expression()
  #
  #   new_data = %{"data" => "some data here"}
  #   opts = nil
  #   test = root |> mut8!(@test_identities_1, new_data, opts)
  #   test_info = test |> get_info!
  #   test_gib = test_info[:gib]
  #
  #   assert !Helper.gib_stamped?(test_gib)
  # end

  # ----------------------------------------------------------------------------
  # rel8
  # ----------------------------------------------------------------------------

  @tag :capture_log
  test "rel8 stamp" do
    {:ok, root} = Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    b = root |> fork!(@test_identities_1, Helper.new_id)

    opts = %{"gib_stamp" => "true"}
    new_a = a |> rel8!(b, @test_identities_1, ["rel8d"], opts)

    {_new_a_ib, new_a_gib} = new_a |> get_info! |> Helper.get_ib_gib! |> Helper.separate_ib_gib!

    assert Helper.gib_stamped?(new_a_gib)
  end

  # During refactoring, I've removed the default opts to allow this test.
  # I plan on enabling it again though at some point.
  # @tag :capture_log
  # test "rel8 NOT stamped, implicit false" do
  #   {:ok, root} = Expression.Supervisor.start_expression()
  #
  #   a = root |> fork!(@test_identities_1, Helper.new_id)
  #   b = root |> fork!(@test_identities_1, Helper.new_id)
  #
  #   opts = %{"gib_stamp" => "false"}
  #   new_a = a |> rel8!(b, @test_identities_1, ["rel8d"], opts)
  #
  #   {_new_a_ib, new_a_gib} = new_a |> get_info! |> Helper.get_ib_gib! |> Helper.separate_ib_gib!
  #
  #   assert !Helper.gib_stamped?(new_a_gib)
  # end

  @tag :capture_log
  test "rel8 NOT stamped, explicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    b = root |> fork!(@test_identities_1, Helper.new_id)

    opts = %{"gib_stamp" => "false"}
    new_a = a |> rel8!(b, @test_identities_1, ["rel8d"], opts)

    {_new_a_ib, new_a_gib} = new_a |> get_info! |> Helper.get_ib_gib! |> Helper.separate_ib_gib!

    assert !Helper.gib_stamped?(new_a_gib)
  end

  @tag :capture_log
  test "rel8 NOT stamped, empty map" do
    {:ok, root} = Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    b = root |> fork!(@test_identities_1, Helper.new_id)

    opts = %{}
    new_a = a |> rel8!(b, @test_identities_1, ["rel8d"], opts)

    {_new_a_ib, new_a_gib} = new_a |> get_info! |> Helper.get_ib_gib! |> Helper.separate_ib_gib!

    assert !Helper.gib_stamped?(new_a_gib)
  end

  # @tag :capture_log
  # test "rel8 NOT stamped, nil" do
  #   {:ok, root} = Expression.Supervisor.start_expression()
  #
  #   a = root |> fork!(@test_identities_1, Helper.new_id)
  #   b = root |> fork!(@test_identities_1, Helper.new_id)
  #
  #   opts = nil
  #   new_a = a |> rel8!(b, @test_identities_1, ["rel8d"], opts)
  #
  #   {_new_a_ib, new_a_gib} = new_a |> get_info! |> Helper.get_ib_gib! |> Helper.separate_ib_gib!
  #
  #   assert !Helper.gib_stamped?(new_a_gib)
  # end

  # ----------------------------------------------------------------------------
  # instance
  # ----------------------------------------------------------------------------

  @tag :capture_log
  test "instance stamp" do
    {:ok, root} = Expression.Supervisor.start_expression()
    test_base = root |> fork!(@test_identities_1, Helper.new_id)

    test_ib = "test ib here uh hrm"
    test = test_base |> instance!(@test_identities_1, test_ib, %{"gib_stamp" => "true"})
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "instance NOT stamped, implicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()
    test_base = root |> fork!(@test_identities_1, Helper.new_id)

    test_ib = "test ib here uh hrm"
    # opts = nada
    test = test_base |> instance!(@test_identities_1, test_ib)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "instance NOT stamped, explicit false" do
    {:ok, root} = Expression.Supervisor.start_expression()
    test_base = root |> fork!(@test_identities_1, Helper.new_id)

    test_ib = "test ib here uh hrm"
    opts = %{"gib_stamp" => "false"}
    test = test_base |> instance!(@test_identities_1, test_ib, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  @tag :capture_log
  test "instance NOT stamped, empty map" do
    {:ok, root} = Expression.Supervisor.start_expression()
    test_base = root |> fork!(@test_identities_1, Helper.new_id)

    test_ib = "test ib here uh hrm"
    opts = %{}
    test = test_base |> instance!(@test_identities_1, test_ib, opts)
    test_info = test |> get_info!
    test_gib = test_info[:gib]

    assert !Helper.gib_stamped?(test_gib)
  end

  # @tag :capture_log
  # test "instance NOT stamped, nil" do
  #   {:ok, root} = Expression.Supervisor.start_expression()
  #   test_base = root |> fork!(@test_identities_1, Helper.new_id)
  #
  #   test_ib = "test ib here uh hrm"
  #   opts = nil
  #   test = test_base |> instance!(@test_identities_1, test_ib, opts)
  #   test_info = test |> get_info!
  #   test_gib = test_info[:gib]
  #
  #   assert !Helper.gib_stamped?(test_gib)
  # end

end
