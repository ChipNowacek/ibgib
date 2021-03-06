defmodule IbGib.Auth.AuthTest do
  @moduledoc """
  See `IbGib.Auth.Identity`, `IbGib.Auth.Session`.
  """

  use ExUnit.Case
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :test
  alias IbGib.{Expression, Helper, Auth.Identity}
  import IbGib.Expression


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
  test "identity gib root" do
    {:ok, _root_identity} = Expression.Supervisor.start_expression({"identity", "gib"})
  end

  @tag :capture_log
  test "get_identity, session, baby steps" do

    session_id = RandomGib.Get.some_characters(30)
    priv_data = %{
      "session_id" => session_id
    }

    ip = "1.2.3.4"
    pub_data = %{
      "type" => "session",
      "ip" => ip
    }

    {:ok, identity_ib_gib} = Identity.get_identity(priv_data, pub_data)

    {:ok, identity} = Expression.Supervisor.start_expression(identity_ib_gib)
    identity_info = identity |> get_info!

    _ = Logger.debug "identity_info: #{inspect identity_info}"

    {_identity_ib, identity_gib} = Helper.separate_ib_gib!(identity_ib_gib)
    assert Helper.gib_stamped?(identity_gib)
  end

  @tag :capture_log
  test "get_identity, email, token, baby steps" do

    # This is the token that we would generate in the email sent to the user.
    # token = RandomGib.Get.some_characters(30)
    # This is the email address we send the login link to
    email_addr = "example@emailaddr.essyoo"

    priv_data = %{
      "email_addr" => email_addr
    }

    ip = "1.2.3.4"
    pub_data = %{
      "type" => "email",
      "ip" => ip,
      "email_addr" => email_addr
    }

    {:ok, identity_ib_gib} = Identity.get_identity(priv_data, pub_data)

    {:ok, identity} = Expression.Supervisor.start_expression(identity_ib_gib)
    identity_info = identity |> get_info!

    _ = Logger.warn "identity_info: #{inspect identity_info}"
  end


  @tag :capture_log
  test "fork with single valid identity_ib_gib, assure identity is rel8d" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = @test_identities_1
    dest_ib = "valid ib here"

    {:ok, a} = root |> fork(identity_ib_gibs, dest_ib)
    a_info = a |> get_info!

    _ = Logger.debug "a_info: #{inspect a_info}"

    assert Map.has_key?(a_info[:rel8ns], "identity")
    assert a_info[:rel8ns]["identity"] == identity_ib_gibs
  end

  @tag :capture_log
  test "fork with multiple valid identity_ib_gib, assure identity is rel8d" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = @test_identities_2
    dest_ib = "valid ib here"

    {:ok, a} = root |> fork(identity_ib_gibs, dest_ib)
    a_info = a |> get_info!

    _ = Logger.debug "a_info: #{inspect a_info}"

    assert Map.has_key?(a_info[:rel8ns], "identity")
    assert a_info[:rel8ns]["identity"] == identity_ib_gibs
  end

  @tag :capture_log
  test "fork with invalid identity_ib_gib, no gib" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = ["invalid ib gib here"]
    dest_ib = "valid ib here"

    {:error, result} =
      root |> fork(identity_ib_gibs, dest_ib)

    _ = Logger.debug "result: #{inspect result}"
  end

  @tag :capture_log
  test "fork with invalid identity_ib_gib, empty string" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = [""]
    dest_ib = "valid ib here"

    {:error, result} =
      root |> fork(identity_ib_gibs, dest_ib)

    _ = Logger.debug "result: #{inspect result}"
  end

  @tag :capture_log
  test "fork with invalid identity_ib_gib, two identity ib gib, one invalid" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = ["valid#{@delim}gib", "invalid ib gib here"]
    dest_ib = "valid ib here"

    {:error, result} =
      root |> fork(identity_ib_gibs, dest_ib)

    _ = Logger.debug "result: #{inspect result}"
  end

  @tag :capture_log
  test "fork with invalid identity_ib_gib, many identity ib gib, one invalid" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = [
      "valid#{@delim}gib",
      "valid 2#{@delim}gibYO",
      "invalid ib gib here",
      "valid 3#{@delim}gibHUH",
      "valid 4#{@delim}gibWHAT"
    ]
    dest_ib = "valid ib here"

    {:error, result} =
      root |> fork(identity_ib_gibs, dest_ib)

    _ = Logger.debug "result: #{inspect result}"
  end

  @tag :capture_log
  test "mut8 with single valid identity_ib_gib, assure identity is rel8d" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = @test_identities_1
    test_key = "valid key here"
    test_value = "valid value here"
    test_kv = %{test_key => test_value}

    {:ok, a} = root |> mut8(identity_ib_gibs, test_kv, @default_transform_options)
    a_info = a |> get_info!

    _ = Logger.debug "a_info: #{inspect a_info}"

    assert Map.has_key?(a_info[:rel8ns], "identity")
    assert a_info[:rel8ns]["identity"] == identity_ib_gibs
  end

  @tag :capture_log
  test "mut8 with multiple valid identity_ib_gib, assure identity is rel8d" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = @test_identities_2
    test_key = "valid key here"
    test_value = "valid value here"
    test_kv = %{test_key => test_value}

    {:ok, a} = root |> mut8(identity_ib_gibs, test_kv, @default_transform_options)
    a_info = a |> get_info!

    _ = Logger.debug "a_info: #{inspect a_info}"

    assert Map.has_key?(a_info[:rel8ns], "identity")
    assert a_info[:rel8ns]["identity"] == identity_ib_gibs
  end

  @tag :capture_log
  test "fork, add identity, rel8, ensure new identity is on rel8d thing" do
    {:ok, root} = Expression.Supervisor.start_expression()

    initial_test_identities = @test_identities_1
    a_ib = "a ib here huha"
    b_ib = "bb bo beee"
    a  = root |> fork!(initial_test_identities, a_ib)
    b  = root |> fork!(initial_test_identities, b_ib)

    session_id = RandomGib.Get.some_characters(30)
    priv_data = %{
      "session_id" => session_id
    }
    ip = "1.2.3.4"
    pub_data = %{
      "type" => "session",
      "ip" => ip
    }
    {:ok, new_identity_ib_gib} = Identity.get_identity(priv_data, pub_data)

    more_identities = initial_test_identities ++ [new_identity_ib_gib]
    a = a |> rel8!(b, more_identities, ["rel8d"], @default_transform_options)

    a_info = a |> get_info!

    _ = Logger.debug "a_info:\n#{inspect a_info, pretty: true}"
    _ = Logger.debug "more_identities: #{inspect more_identities}"

    more_identities
    |> Enum.each(fn(i) ->
         assert Enum.member?(a_info[:rel8ns]["identity"], i)
       end)
  end

end
