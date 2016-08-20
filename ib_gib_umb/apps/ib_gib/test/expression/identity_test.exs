defmodule IbGib.Expression.IdentityTest do
  use ExUnit.Case
  use IbGib.Constants, :ib_gib

  alias IbGib.{Expression, Helper, Identity}
  import IbGib.{Expression, QueryOptionsFactory}
  require Logger

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    Logger.configure(level: :error)
    Code.load_file("priv/repo/seeds.exs")
    Logger.configure(level: :debug)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  @tag :capture_log
  test "user, session, email gib exist" do
    {:ok, root_user} = Expression.Supervisor.start_expression({"user", "gib"})
    {:ok, root_session} = Expression.Supervisor.start_expression({"session", "gib"})
    {:ok, root_email} = Expression.Supervisor.start_expression({"email", "gib"})
  end

  @tag :capture_log
  test "instance session" do
    {:ok, root_session} = Expression.Supervisor.start_expression({"session", "gib"})

    session_a_ib = "session_#{RandomGib.Get.some_letters(30)}"

    {_, session_a} = root_session |> instance!(session_a_ib)

    session_a_info = session_a |> get_info!

    assert session_a_info[:ib] == session_a_ib
  end

  @tag :capture_log
  test "query for session manually, fails, instance session, query for session, succeeds" do
    {:ok, root_session} = Expression.Supervisor.start_expression({"session", "gib"})

    # This particular test does not use `IbGib.Identity`. This is so that it
    # can check to be sure that it is getting the **latest** session ib_gib.
    # I already caught a bug (not using microseconds in schema).

    # Because the `ib` of any ib_gib only allows certain characters, we will
    # not use the session_id as the ib itself. Instead, we will use the hash
    # of the session_id.
    # So note: ib and id are DIFFERENT!
    # Personally, I pronounce these internally with "id" as "ID" (the
    # initialism "eye dee") and "ib" as "ib" (the noun).
    # I note it here because I know this may be confusing for newcomers.
    session_id = RandomGib.Get.some_characters(30)
    session_ib = Identity.get_session_ib!(session_id)

    # First, we will try to see if there is an existing session with that ib.
    # There should NOT be. This mimics when someone first visits us, and/or when
    # a new session is started.
    query_options = do_query |> where_ib("is", session_ib) |> most_recent_only
    query_result_info = root_session |> query!(query_options) |> get_info!
    result_list = query_result_info[:rel8ns]["result"]


    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    assert Enum.count(result_list) === 1

    ib_gib_only_result = Enum.at(result_list, 0)
    assert ib_gib_only_result == "ib#{delim}gib"


    # Next, since we didn't find an existing session, we instance a new session.
    {_, session} = root_session |> instance!(session_ib)

    # This session_ib actually has two different ib_gib. The first is the
    # "initial" snapshot with the fork not having any relationships.
    # The second is the snapshot **after** it has added the "instance_of"
    # rel8n with the `root_session`.
    # As an aside, the root_session also has a newer version than the one
    # that "instance_of" points to! This is because each's gib must take into
    # account the other's gib, i.e. a circular reference. IOW, we need the
    # root's gib to calculate the instance's gib, but we need the instance's
    # gib to calculate the root's gib.
    session_info = session |> get_info!
    assert session_info[:ib] == session_ib


    # Now, we run the query again, mimicking when a user has returned. Only
    # this time, it should be successful.
    # (We reuse the same query_options)
    query_result_info = root_session |> query!(query_options) |> get_info!
    result_list = query_result_info[:rel8ns]["result"]

    Logger.debug "result_list: #{inspect result_list}"
    # All results have ib^gib as the first result
    # There are two different results
    assert Enum.count(result_list) === 2

    single_result = Enum.at(result_list, 1)
    {single_result_ib, _} = Helper.separate_ib_gib!(single_result)
    assert single_result_ib === session_ib
    Logger.debug "single result ib: #{single_result_ib}"
  end

  @tag :capture_log
  test "query for session with identity module, fails, instance session, query for session, succeeds" do
    {:ok, root_session} = Expression.Supervisor.start_expression({"session", "gib"})

    # Because the `ib` of any ib_gib only allows certain characters, we will
    # not use the session_id as the ib itself. Instead, we will use the hash
    # of the session_id.
    # So note: ib and id are DIFFERENT!
    # Personally, I pronounce these internally with "id" as "ID" (the
    # initialism "eye dee") and "ib" as "ib" (the noun).
    # I note it here because I know this may be confusing for newcomers.
    session_id = RandomGib.Get.some_characters(30)
    session_ib = Identity.get_session_ib!(session_id)

    # First, we will try to see if there is an existing session with that ib.
    # There should NOT be. This mimics when someone first visits us, and/or when
    # a new session is started.
    # existing_session_ib_gib = Identity.get_latest
    existing_session_ib_gib = Identity.get_latest_session_ib_gib!(session_id, root_session)
    assert existing_session_ib_gib == nil

    # Next, since we didn't find an existing session, we instance a new session.
    {_, session} = root_session |> instance!(session_ib)

    session_info = session |> get_info!
    assert session_info[:ib] == session_ib


    # Now, we check again for the session
    existing_session_ib_gib = Identity.get_latest_session_ib_gib!(session_id, root_session)
    assert existing_session_ib_gib != nil
    {existing_session_ib, existing_session_gib} =
      Helper.separate_ib_gib!(existing_session_ib_gib)

    assert existing_session_ib == session_ib
  end

  @tag :capture_log
  test "query for session with identity module, fails, instance session, mut8 session, query for session, be sure to get the mut8d-latest- one" do
    {:ok, root_session} = Expression.Supervisor.start_expression({"session", "gib"})

    # Refer to the previous two test cases.
    # This adds to that. It does it by the Identity module. Then it double checks.

    # Because the `ib` of any ib_gib only allows certain characters, we will
    # not use the session_id as the ib itself. Instead, we will use the hash
    # of the session_id.
    # So note: ib and id are DIFFERENT!
    # Personally, I pronounce these internally with "id" as "ID" (the
    # initialism "eye dee") and "ib" as "ib" (the noun).
    # I note it here because I know this may be confusing for newcomers.
    session_id = RandomGib.Get.some_characters(30)
    session_ib = Identity.get_session_ib!(session_id)

    # First, we will try to see if there is an existing session with that ib.
    # There should NOT be. This mimics when someone first visits us, and/or when
    # a new session is started.
    # existing_session_ib_gib = Identity.get_latest
    existing_session_ib_gib = Identity.get_latest_session_ib_gib!(session_id, root_session)
    assert existing_session_ib_gib == nil

    # Next, since we didn't find an existing session, we instance a new session.
    {_, session} = root_session |> instance!(session_ib)
    session2_value = "2 yoooo"
    session2 = session |> mut8!(%{"value" => session2_value})

    session_info = session |> get_info!
    assert session_info[:ib] == session_ib

    session2_info = session2 |> get_info!

    # Now, we check again for the session
    existing_session_ib_gib = Identity.get_latest_session_ib_gib!(session_id, root_session)
    assert existing_session_ib_gib != nil
    {existing_session_ib, existing_session_gib} =
      Helper.separate_ib_gib!(existing_session_ib_gib)

    assert existing_session_ib == session_ib
    assert existing_session_gib == session2_info[:gib]
  end

  @tag :capture_log
  test "Identity start_or_resume_session" do
    {:ok, root_session} = Expression.Supervisor.start_expression({"session", "gib"})

    session_id = RandomGib.Get.some_characters(30)

    {:ok, session_ib_gib} = Identity.start_or_resume_session(session_id)

    assert session_ib_gib != nil

    # Get the actual process to be sure that the new session object actually
    # exists
    {:ok, session} = Expression.Supervisor.start_expression(session_ib_gib)

    session_info = session |> get_info!

    # verify completely separately from the process that it is the correct
    # session id.
    assert session_info[:ib] == Identity.get_session_ib!(session_id)
  end
end
