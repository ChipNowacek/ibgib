defmodule IbGib.Expression.ExpressionQueryTest do
  @moduledoc """
  This is for testing the query ib_gib, not the repo query. Since all this
  vocab is still new, I'll spell this out: This is for when you create a query
  ib_gib, just like you would create a fork, mut8, or rel8 transform ib_gib.
  See `IbGib.Expression.query/6` and `IbGib.Data.Schemas.IbGib.QueryTest`.
  """


  use ExUnit.Case
  require Logger

  alias IbGib.{Helper, Auth.Identity}
  import IbGib.{Expression, QueryOptionsFactory}
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :test


  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}

    Logger.disable(self)
    Code.load_file("../../apps/ib_gib/priv/repo/seeds.exs")
    Logger.enable(self)
  end

  @tag :capture_log
  test "Fork a couple ib, query, simplest baby steps" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    Logger.configure(level: :info)
      1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}") |> fork!(@test_identities_1, "ib2_#{&1}")))
    Logger.configure(level: :debug)

    query_options = do_query
    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.warn "query_result_info: #{inspect query_result_info}"
    assert Enum.count(query_result_info[:rel8ns]["result"]) > 0
  end

  @tag :capture_log
  test "Fork a couple ib, query, ib is" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)

    query_options =
      do_query
      |> where_ib("is", test_ib)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, query, ib like" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)

    search_term = "is is a"
    query_options =
      do_query
      |> where_ib("like", search_term)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, query, ib isnt" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, _test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)

    # search_term = test_ib
    query_options =
      do_query
      |> where_ib("isnt", test_ib)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) > 2
    Logger.info "result_list count: #{Enum.count(result_list)}"

    assert !Enum.any?(result_list, fn(res_ib_gib) ->
        # Logger.warn "res_ib_gib: #{res_ib_gib}"
        {:ok, res_instance} = IbGib.Expression.Supervisor.start_expression(res_ib_gib)
        res_info = res_instance |> IbGib.Expression.get_info!
        res_info[:ib] === test_ib
      end)
  end

  @tag :capture_log
  test "Fork a couple ib, query, gib is" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)
    {_, test_gib} = Helper.separate_ib_gib!(test_ib_gib)

    query_options =
      do_query
      |> where_gib("is", test_gib)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, query, gib like" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)
    {_, test_gib} = Helper.separate_ib_gib!(test_ib_gib)

    search_term = String.slice(test_gib, 2..25)
    query_options =
      do_query
      |> where_gib("like", search_term)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, query, gib isnt" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)
    {_, test_gib} = Helper.separate_ib_gib!(test_ib_gib)

    # search_term = test_ib
    query_options =
      do_query
      |> where_gib("isnt", test_gib)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) > 2
    Logger.info "result_list count: #{Enum.count(result_list)}"

    assert !Enum.any?(result_list, fn(res_ib_gib) ->
        # Logger.warn "res_ib_gib: #{res_ib_gib}"
        {:ok, res_instance} = IbGib.Expression.Supervisor.start_expression(res_ib_gib)
        res_info = res_instance |> IbGib.Expression.get_info!
        res_info[:gib] === test_gib
      end)
  end

  @tag :capture_log
  test "Fork a couple ib, query, data key is" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key"
    test_value = "my test value yoooo"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)
    # Reassign the same vars because we really want the version with the data
    {:ok, {_test, _test_info, test_ib_gib}} = test |> gib(:mut8, test_data)

    search_term = test_key
    query_options =
      do_query
      |> where_data("key", "is", search_term)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, query, data key like" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key yo yo yo1234"
    test_value = "my test value yoooo"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)
    # Reassign the same vars because we really want the version with the data
    {:ok, {_test, _test_info, test_ib_gib}} = test |> gib(:mut8, test_data)

    search_term = "y key yo yo yo123"
    query_options =
      do_query
      |> where_data("key", "like", search_term)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, query, data value is" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key"
    test_value = "my test value yoooo"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)
    # Reassign the same vars because we really want the version with the data
    {:ok, {_test, _test_info, test_ib_gib}} = test |> gib(:mut8, test_data)

    search_term = test_value
    query_options =
      do_query
      |> where_data("value", "is", search_term)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, query, data value like" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!(@test_identities_1, Helper.new_id)

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key yo yo yo1234"
    test_value = "my test value yoooo1q23451235"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, @test_identities_1, test_ib)
    # Reassign the same vars because we really want the version with the data
    {:ok, {_test, _test_info, test_ib_gib}} = test |> gib(:mut8, test_data)

    search_term = "y test value yoooo1q23451"
    query_options =
      do_query
      |> where_ib("is", test_ib)
      |> where_data("value", "like", search_term)

    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"
    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2
    # there are three locations where the data value will be the test value:
    # 1) The mut8 transform which gave the ib_gib the data value
    # 2) The actual ib_gib that we want.
    # 3) The query ib_gib that we're making to find it! (because we're using
    #    the search term in our query's data!)
    # So we can either expect 3 results or we can filter by dest_ib
    # (but not gib)

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, fork b, then c from b, query, rel8n ancestor with ibgib b" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    test_ib_b = "hey this is a test ib yuk yuk"
    {:ok, {test_b, _test_info_b, test_ib_gib_b}} = a |> gib(:fork, @test_identities_1, test_ib_b)
    test_ib_c = "this is c"
    {:ok, {_test_c, _test_info_c, test_ib_gib_c}} = test_b |> gib(:fork, @test_identities_1, test_ib_c)

    query_options =
      do_query
      |> where_rel8ns("ancestor", "with", "ibgib", test_ib_gib_b)
    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.info "query_result_info: #{inspect query_result_info}"

    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib_c
    Logger.debug "single result: #{single_result}"
  end

  @tag :capture_log
  test "Fork a couple ib, fork b, then c from b, query, rel8n ancestor without ibgib b" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    # b = a |> fork!
    test_ib_b = "hey this is a test ib yuk yuk"
    {:ok, {test_b, _test_info_b, test_ib_gib_b}} = a |> gib(:fork, @test_identities_1, test_ib_b)
    test_ib_c = "this is c"
    {:ok, {_test_c, _test_info_c, test_ib_gib_c}} = test_b |> gib(:fork, @test_identities_1, test_ib_c)

    query_options =
      do_query
      |> where_rel8ns("ancestor", "without", "ibgib", test_ib_gib_b)
    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.info "query_result_info: #{inspect query_result_info}"

    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list(count=#{Enum.count(result_list)}): #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) > 2

    # should be everything except test_c
    assert !Enum.any?(result_list, &(&1 === test_ib_gib_c))
  end

  @tag :capture_log
  test "Fork a couple ib, fork b, then c from b, query, rel8n ancestor with ib b" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    test_ib_b = "hey this is a test ib yuk yuk"
    {:ok, {test_b, _test_info_b, _test_ib_gib_b}} = a |> gib(:fork, @test_identities_1, test_ib_b)
    test_ib_c = "this is c"
    {:ok, {_test_c, _test_info_c, test_ib_gib_c}} = test_b |> gib(:fork, @test_identities_1, test_ib_c)

    query_options =
      do_query
      |> where_rel8ns("ancestor", "with", "ib", test_ib_b)
    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.info "query_result_info: #{inspect query_result_info}"

    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    assert single_result === test_ib_gib_c
    Logger.debug "single result: #{single_result}"

    {:ok, result_c} = IbGib.Expression.Supervisor.start_expression(single_result)
    result_c_info = result_c |> get_info!
    Logger.warn "result_c_info should have yuk yuk ib in rel8n: #{inspect result_c_info}"
  end

  @tag :capture_log
  test "Fork a couple ib, fork b, then c and d from b, query, rel8n ancestor with ib b" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
    Logger.configure(level: :debug)

    test_ib_b = "hey this is a test ib yuk yuk"
    {:ok, {test_b, _test_info_b, _test_ib_gib_b}} = a |> gib(:fork, @test_identities_1, test_ib_b)
    test_ib_c = "this is c"
    {:ok, {_test_c, _test_info_c, test_ib_gib_c}} = test_b |> gib(:fork, @test_identities_1, test_ib_c)
    test_ib_d = "this is d"
    {:ok, {_test_d, _test_info_d, test_ib_gib_d}} = test_b |> gib(:fork, @test_identities_1, test_ib_d)

    query_options =
      do_query
      |> where_rel8ns("ancestor", "with", "ib", test_ib_b)
    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.info "query_result_info: #{inspect query_result_info}"

    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 3

    first_result = Enum.at(result_list, 1)
    assert first_result === test_ib_gib_c or first_result === test_ib_gib_d
    Logger.debug "first_result: #{first_result}"

    second_result = Enum.at(result_list, 2)
    assert second_result === test_ib_gib_c or second_result === test_ib_gib_d
    Logger.debug "second_result: #{second_result}"

    {:ok, result_c} = IbGib.Expression.Supervisor.start_expression(first_result)
    result_c_info = result_c |> get_info!
    Logger.warn "result_c_info should have yuk yuk ib in rel8n: #{inspect result_c_info}"

    {:ok, result_2} = IbGib.Expression.Supervisor.start_expression(second_result)
    result_2_info = result_2 |> get_info!
    Logger.warn "result_2_info should have yuk yuk ib in rel8n: #{inspect result_2_info}"

  end

  # not going to worry about implementing this right now since low
  # priority
  # @tag :capture_log
  # test "Fork a couple ib, fork b, then c from b, query, rel8n ancestor without ib b" do
  #   test_count = 5
  #   {:ok, root} = IbGib.Expression.Supervisor.start_expression()
  #
  #   a = root |> fork!(@test_identities_1, Helper.new_id)
  #   Logger.configure(level: :info)
  #   1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}")))
  #   Logger.configure(level: :debug)
  #
  #   # b = a |> fork!
  #   test_ib_b = "hey this is a test ib b"
  #   {:ok, {test_b, _test_info_b, test_ib_gib_b}} = a |> gib(:fork, @test_identities_1, test_ib_b)
  #   test_ib_c = "this is c"
  #   {:ok, {_test_c, _test_info_c, test_ib_gib_c}} = test_b |> gib(:fork, @test_identities_1, test_ib_c)
  #
  #   query_options =
  #     do_query
  #     |> where_rel8ns("ancestor", "without", "ib", test_ib_b)
  #   {:ok, query_result} = root |> query(query_options)
  #   Logger.debug "query_result: #{inspect query_result}"
  #   query_result_info = query_result |> get_info!
  #   Logger.info "query_result_info: #{inspect query_result_info}"
  #
  #   result_list = query_result_info[:rel8ns]["result"]
  #   Logger.debug "result_list(count=#{Enum.count(result_list)}): #{inspect result_list}"
  #   # All results have ib^gib as the first result
  #   assert Enum.count(result_list) > 2
  #
  #   # should be everything except test_c
  #   assert Enum.each(result_list, fn (res_ib_gib) ->
  #     {:ok, res} = IbGib.Expression.Supervisor.start_expression(res_ib_gib)
  #     res_info = res |> get_info!
  #     res_info[:rel8ns] |> Enum.each(fn (rel8n) ->
  #
  #       end)
  #     {res_ib, _res_gib} = Helper.separate_ib_gib!(res_ib_gib)
  #     res_ib === test_ib_b
  #     end)
  # end

  @tag :capture_log
  test "Fork, mut8s, query most recent only" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()


    a_ib = RandomGib.Get.some_letters(5)
    a = root |> fork!(@test_identities_1, a_ib)
    Logger.configure(level: :info)

    {_a_n, a_n_gib} =
      1..test_count
      |> Enum.reduce({a, nil}, fn(n, {a_m, _}) ->
           new_a = a_m |> mut8!(%{"value" => "#{n}"})
           new_a_info = new_a |> get_info!
          #  Logger.warn "new_a_info[:ib]: #{new_a_info[:ib]}"
           Logger.warn "new_a_info[:gib]: #{new_a_info[:gib]}"
           {new_a, new_a_info[:gib]}
         end)
    Logger.configure(level: :debug)

    query_opts =
      do_query
      |> where_ib("is", a_ib)
      |> most_recent_only
    query_result_info = a |> query!(query_opts) |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"

    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list(count=#{Enum.count(result_list)}): #{inspect result_list}"
    # All results have ib^gib as the first result, so ignore one of the list
    assert Enum.count(result_list) === 2
    single_result = Enum.at(result_list, 1)

    {_, single_result_gib} = Helper.separate_ib_gib!(single_result)
    assert single_result_gib == a_n_gib
  end

  @tag :capture_log
  test "Fork, forks, query most recent only" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()


    a_ib = RandomGib.Get.some_letters(5)
    a = root |> fork!(@test_identities_1, a_ib)
    Logger.configure(level: :info)

    {_a_n, a_n_gib} =
      1..test_count
      |> Enum.reduce({a, nil}, fn(_n, {a_m, _}) ->
           new_a = a_m |> fork!(@test_identities_1, a_ib)
           new_a_info = new_a |> get_info!
          #  Logger.warn "new_a_info[:ib]: #{new_a_info[:ib]}"
           Logger.warn "new_a_info[:gib]: #{new_a_info[:gib]}"
           {new_a, new_a_info[:gib]}
         end)
    Logger.configure(level: :debug)

    query_opts =
      do_query
      |> where_ib("is", a_ib)
      |> most_recent_only
    query_result_info = a |> query!(query_opts) |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"

    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list(count=#{Enum.count(result_list)}): #{inspect result_list}"
    # All results have ib^gib as the first result, so ignore one of the list
    assert Enum.count(result_list) === 2
    single_result = Enum.at(result_list, 1)

    {_, single_result_gib} = Helper.separate_ib_gib!(single_result)
    assert single_result_gib == a_n_gib
  end

  @tag :capture_log
  test "Fork, mut8s, union 2 query most recent only" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()


    a_ib = RandomGib.Get.some_letters(5)
    a = root |> fork!(@test_identities_1, a_ib)
    Logger.configure(level: :info)

    {_a_n, a_n_gib} =
      1..test_count
      |> Enum.reduce({a, nil}, fn(n, {a_m, _}) ->
           new_a = a_m |> mut8!(%{"value" => "#{n}"})
           new_a_info = new_a |> get_info!
          #  Logger.warn "new_a_info[:ib]: #{new_a_info[:ib]}"
           Logger.warn "new_a_info[:gib]: #{new_a_info[:gib]}"
           {new_a, new_a_info[:gib]}
         end)
    Logger.configure(level: :debug)

    b_ib = RandomGib.Get.some_letters(5)
    b = root |> fork!(@test_identities_1, b_ib)
    Logger.configure(level: :info)

    {_b_n, b_n_gib} =
      1..test_count
      |> Enum.reduce({b, nil}, fn(n, {b_m, _}) ->
           new_b = b_m |> mut8!(%{"value" => "#{n}"})
           new_b_info = new_b |> get_info!
          #  Logger.warn "new_b_info[:ib]: #{new_b_info[:ib]}"
           Logger.warn "new_b_info[:gib]: #{new_b_info[:gib]}"
           {new_b, new_b_info[:gib]}
         end)
    Logger.configure(level: :debug)

    query_opts =
      do_query
      |> where_ib("is", a_ib)
      |> most_recent_only
      |> union
      |> where_ib("is", b_ib)
      |> most_recent_only

    query_result_info = a |> query!(query_opts) |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"

    result_list = query_result_info[:rel8ns]["result"]
    Logger.debug "result_list(count=#{Enum.count(result_list)}): #{inspect result_list}"
    # All results have ib^gib as the first result, so ignore one of the list
    assert Enum.count(result_list) === 3

    first_result = Enum.at(result_list, 1)
    {_, first_result_gib} = Helper.separate_ib_gib!(first_result)
    assert first_result_gib == a_n_gib

    second_result = Enum.at(result_list, 2)
    {_, second_result_gib} = Helper.separate_ib_gib!(second_result)
    assert second_result_gib == b_n_gib
  end

  @tag :capture_log
  test "single identity, rel8 to forks, query all rel8d to identity" do
    # -------------------------------------------------------------------------
    Logger.disable(self)
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    priv_data = %{"yo" => "this is some private data hrmm"}
    pub_data = %{"public" => "public data hizzah"}
    {:ok, identity_ib_gib} = Identity.get_identity(priv_data, pub_data)
    {:ok, identity} = IbGib.Expression.Supervisor.start_expression(identity_ib_gib)

    test_ibgibs = %{}
    test_rel8n = "identity_rel8n"

    # We're going to create some test ibgibs. The even ones we'll rel8
    # to the test identity. The others will not be rel8d.
    test_count = 10
    1..test_count
    |> Enum.each(fn(i) ->
         test = root |> fork!(@test_identities_1, "#{i}")
         test_info = test |> get_info!
         test_ib_gib = test_info |> Helper.get_ib_gib!
         if rem(i, 2) == 0 do
           IbGib.Expression.rel8!(test, identity, [test_rel8n])
         end
       end)
    Logger.enable(self)
    # -------------------------------------------------------------------------

    query_opts =
      do_query
      |> where_rel8ns(test_rel8n, "withany", "ibgib", [identity_ib_gib])
      # |> where_rel8ns(test_rel8n, "with", "ibgib", identity_ib_gib)
    query_result_info = identity |> query!(query_opts) |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"

    result_ib_gib_list =
      query_result_info[:rel8ns]["result"]
      |> Enum.map(fn(res_ib_gib) ->
           {res_ib, _res_ib_gib} = Helper.separate_ib_gib!(res_ib_gib)
           res_ib
         end)
      |> Enum.sort

    expected_result_list = ["ib", "2", "4", "6", "8", "10"] |> Enum.sort
    Logger.debug "result_ib_gib_list: #{inspect result_ib_gib_list}"

    assert result_ib_gib_list == expected_result_list
  end

  @tag :capture_log
  test "two identities, rel8 to forks, query all rel8d to either identity" do
    # -------------------------------------------------------------------------
    Logger.disable(self)
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    priv_data = %{"yo" => "this is some private data hrmm"}
    pub_data = %{"public" => "public data hizzah"}
    {:ok, identity_ib_gib} = Identity.get_identity(priv_data, pub_data)
    {:ok, identity} = IbGib.Expression.Supervisor.start_expression(identity_ib_gib)

    priv_data2 = %{"yo2" => "this is some private data hrmm2"}
    pub_data2 = %{"public2" => "public data hizzah2"}
    {:ok, identity_ib_gib2} = Identity.get_identity(priv_data2, pub_data2)
    {:ok, identity2} = IbGib.Expression.Supervisor.start_expression(identity_ib_gib2)

    test_ibgibs = %{}
    test_rel8n = "identity_rel8n"

    # We're going to create some test ibgibs. The even ones we'll rel8
    # to the test identity. The others will not be rel8d.
    test_count = 10
    1..test_count
    |> Enum.each(fn(i) ->
         test = root |> fork!(@test_identities_1, "#{i}")
         test_info = test |> get_info!
         test_ib_gib = test_info |> Helper.get_ib_gib!
         cond do
           # 2,4,6,8,10
           rem(i, 2) == 0 ->
             IbGib.Expression.rel8!(test, identity, [test_rel8n])

           # 3,9 (6 already matched)
           rem(i, 3) == 0 ->
             IbGib.Expression.rel8!(test, identity2, [test_rel8n])

           # 1,5,7
           true ->
             # do nothing
         end
       end)
    Logger.enable(self)
    # -------------------------------------------------------------------------

    query_opts =
      do_query
      |> where_rel8ns(test_rel8n, "withany", "ibgib", [identity_ib_gib, identity_ib_gib2])
    query_result_info = identity |> query!(query_opts) |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"

    result_ib_gib_list =
      query_result_info[:rel8ns]["result"]
      |> Enum.map(fn(res_ib_gib) ->
           {res_ib, _res_ib_gib} = Helper.separate_ib_gib!(res_ib_gib)
           res_ib
         end)
      |> Enum.sort

    Logger.debug "result_ib_gib_list: #{inspect result_ib_gib_list}"

    expected_result_list = ["ib", "2", "3", "4", "6", "8", "9", "10"] |> Enum.sort
    Logger.debug "expected_result_list: #{inspect expected_result_list}"
    assert result_ib_gib_list == expected_result_list
  end

  @tag :capture_log
  test "two identities, rel8 to forks, query all rel8d to BOTH identities, use ANDing of rel8ns" do
    # -------------------------------------------------------------------------
    Logger.disable(self)
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    priv_data = %{"yo" => "this is some private data hrmm"}
    pub_data = %{"public" => "public data hizzah"}
    {:ok, identity_ib_gib} = Identity.get_identity(priv_data, pub_data)
    {:ok, identity} = IbGib.Expression.Supervisor.start_expression(identity_ib_gib)

    priv_data2 = %{"yo2" => "this is some private data hrmm2"}
    pub_data2 = %{"public2" => "public data hizzah2"}
    {:ok, identity_ib_gib2} = Identity.get_identity(priv_data2, pub_data2)
    {:ok, identity2} = IbGib.Expression.Supervisor.start_expression(identity_ib_gib2)

    test_ibgibs = %{}
    test_rel8n = "identity_rel8n"

    # We're going to create some test ibgibs. The even ones we'll rel8
    # to the test identity. The others will not be rel8d.
    test_count = 10
    1..test_count
    |> Enum.each(fn(i) ->
         test = root |> fork!(@test_identities_1, "#{i}")
         test_info = test |> get_info!
         test_ib_gib = test_info |> Helper.get_ib_gib!
         cond do
           # 4,8
           rem(i, 4) == 0 ->
             {new_test, _new_identity} = IbGib.Expression.rel8!(test, identity, [test_rel8n])
             IbGib.Expression.rel8!(new_test, identity2, [test_rel8n])

           # 2,6,10
           rem(i, 2) == 0 ->
             IbGib.Expression.rel8!(test, identity, [test_rel8n])

           # 3,9 (6 already matched)
           rem(i, 3) == 0 ->
             IbGib.Expression.rel8!(test, identity2, [test_rel8n])

           # 1,5,7
           true ->
             # do nothing
         end
       end)
    Logger.enable(self)
    # -------------------------------------------------------------------------

    query_opts =
      do_query
      |> where_rel8ns(test_rel8n, "with", "ibgib", identity_ib_gib)
      |> where_rel8ns(test_rel8n, "with", "ibgib", identity_ib_gib2)

    query_result_info = identity |> query!(query_opts) |> get_info!
    Logger.debug "query_result_info: #{inspect query_result_info}"

    result_ib_gib_list =
      query_result_info[:rel8ns]["result"]
      |> Enum.map(fn(res_ib_gib) ->
           {res_ib, _res_ib_gib} = Helper.separate_ib_gib!(res_ib_gib)
           res_ib
         end)
      |> Enum.sort

    Logger.debug "result_ib_gib_list: #{inspect result_ib_gib_list}"

    expected_result_list = ["ib", "4", "8"] |> Enum.sort
    Logger.debug "expected_result_list: #{inspect expected_result_list}"
    assert result_ib_gib_list == expected_result_list
  end

  @tag :capture_log
  test "Fork a couple ib, query, asked_by single ib_gib bitstring" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    Logger.configure(level: :info)
      1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}") |> fork!(@test_identities_1, "ib2_#{&1}")))
    Logger.configure(level: :debug)


    test_identities_1_ib_gib = "some ib#{@delim}gib"
    test_identities_1_ib_gibs = [test_identities_1_ib_gib]
    # testing single one in this test
    query_options =
      do_query
      |> asked_by(test_identities_1_ib_gib)
    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.warn "query_result_info: #{inspect query_result_info}"
    assert Enum.count(query_result_info[:rel8ns]["result"]) > 1
    query_ib_gib = Enum.at(query_result_info[:rel8ns]["query"], 0)

    # this is the query itself (not the result). We want to make sure
    # that the query itself is "signed" by the `asked_by` part of the
    # query_options
    {:ok, query} = IbGib.Expression.Supervisor.start_expression(query_ib_gib)
    query_info = query |> get_info!
    Logger.warn "query_info: #{inspect query_info}"
    Logger.warn "blah: #{inspect query_info[:data]}"

    assert query_info[:rel8ns]["identity"] == test_identities_1_ib_gibs
    assert query_result_info[:rel8ns]["identity"] == test_identities_1_ib_gibs
  end

  @tag :capture_log
  test "Fork a couple ib, query, asked_by list of ib_gib bitstrings" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!(@test_identities_1, Helper.new_id)
    Logger.configure(level: :info)
      1..test_count |> Enum.each(&(a |> fork!(@test_identities_1, "ib_#{&1}") |> fork!(@test_identities_1, "ib2_#{&1}")))
    Logger.configure(level: :debug)


    test_identities_1_ib_gib = "some ib#{@delim}gib"
    test_identities_1_ib_gib2 = "some other ib#{@delim}gib"
    test_identities_1_ib_gibs = [test_identities_1_ib_gib, test_identities_1_ib_gib2]
    # testing multiple overload in this test
    query_options =
      do_query
      |> asked_by(test_identities_1_ib_gibs)
    {:ok, query_result} = root |> query(query_options)
    Logger.debug "query_result: #{inspect query_result}"
    query_result_info = query_result |> get_info!
    Logger.warn "query_result_info: #{inspect query_result_info}"
    assert Enum.count(query_result_info[:rel8ns]["result"]) > 1
    query_ib_gib = Enum.at(query_result_info[:rel8ns]["query"], 0)

    # this is the query itself (not the result). We want to make sure
    # that the query itself is "signed" by the `asked_by` part of the
    # query_options
    {:ok, query} = IbGib.Expression.Supervisor.start_expression(query_ib_gib)
    query_info = query |> get_info!
    Logger.warn "query_info: #{inspect query_info}"
    Logger.warn "blah: #{inspect query_info[:data]}"

    assert query_info[:rel8ns]["identity"] == test_identities_1_ib_gibs
    assert query_result_info[:rel8ns]["identity"] == test_identities_1_ib_gibs
  end

end
