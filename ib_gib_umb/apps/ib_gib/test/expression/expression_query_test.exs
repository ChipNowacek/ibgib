defmodule IbGib.Expression.ExpressionQueryTest do
  @moduledoc """
  This is for testing the query ib_gib, not the repo query. Since all this
  vocab is still new, I'll spell this out: This is for when you create a query
  ib_gib, just like you would create a fork, mut8, or rel8 transform ib_gib.
  See `IbGib.Expression.query/6` and `IbGib.Data.Schemas.IbGib.QueryTest`.
  """

  use ExUnit.Case
  use IbGib.Constants, :ib_gib
  alias IbGib.Helper
  # alias IbGib.Data.Repo
  import IbGib.Expression
  import IbGib.QueryOptionsFactory
  require Logger

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  @tag :capture_log
  test "Fork a couple ib, query, simplest baby steps" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
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
    a = root |> fork!

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, test_ib_gib}} = root |> gib(:fork, test_ib)

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
    a = root |> fork!

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, test_ib_gib}} = root |> gib(:fork, test_ib)

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
    a = root |> fork!

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_ib = "hey this is a test ib"
    {:ok, {_test, _test_info, _test_ib_gib}} = root |> gib(:fork, test_ib)

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
  test "Fork a couple ib, query, data key is" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    # Create some random other ib_gib
    a = root |> fork!

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key"
    test_value = "my test value yoooo"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, test_ib)
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
    a = root |> fork!

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key yo yo yo1234"
    test_value = "my test value yoooo"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, test_ib)
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
    a = root |> fork!

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key"
    test_value = "my test value yoooo"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, test_ib)
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
    a = root |> fork!

    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # Create the one ib_gib we want to query for
    test_key = "my key yo yo yo1234"
    test_value = "my test value yoooo1q23451235"
    test_data = %{test_key => test_value}
    test_ib = "test ib data key is"
    {:ok, {test, _test_info, _test_ib_gib}} = root |> gib(:fork, test_ib)
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
  test "Fork a couple ib, fork b, then c from b, query, rel8n ancestor is b" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    test_ib_b = "hey this is a test ib yuk yuk"
    {:ok, {test_b, _test_info_b, test_ib_gib_b}} = a |> gib(:fork, test_ib_b)
    test_ib_c = "this is c"
    {:ok, {_test_c, _test_info_c, test_ib_gib_c}} = test_b |> gib(:fork, test_ib_c)

    query_options =
      do_query
      |> where_rel8ns("ancestor", "with", "ib_gib", test_ib_gib_b)
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
  test "Fork a couple ib, fork b, then c from b, query, rel8n ancestor is not b" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()

    a = root |> fork!
    Logger.configure(level: :info)
    1..test_count |> Enum.each(&(a |> fork!("ib_#{&1}")))
    Logger.configure(level: :debug)

    # b = a |> fork!
    test_ib_b = "hey this is a test ib yuk yuk"
    {:ok, {test_b, _test_info_b, test_ib_gib_b}} = a |> gib(:fork, test_ib_b)
    test_ib_c = "this is c"
    {:ok, {_test_c, _test_info_c, test_ib_gib_c}} = test_b |> gib(:fork, test_ib_c)

    query_options =
      do_query
      |> where_rel8ns("ancestor", "without", "ib_gib", test_ib_gib_b)
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
  test "Fork, mut8s, query most recent only" do
    test_count = 5
    {:ok, root} = IbGib.Expression.Supervisor.start_expression()


    a_ib = RandomGib.Get.some_letters(5)
    a = root |> fork!(a_ib)
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
    a = root |> fork!(a_ib)
    Logger.configure(level: :info)

    {_a_n, a_n_gib} =
      1..test_count
      |> Enum.reduce({a, nil}, fn(_n, {a_m, _}) ->
           new_a = a_m |> fork!(a_ib)
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

end
