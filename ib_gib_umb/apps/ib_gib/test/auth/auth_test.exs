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
      "ip" => ip
    }

    {:ok, identity_ib_gib} = Identity.get_identity(priv_data, pub_data)

    {:ok, identity} = Expression.Supervisor.start_expression(identity_ib_gib)
    identity_info = identity |> get_info!

    Logger.debug "identity_info: #{inspect identity_info}"

    {_identity_ib, identity_gib} = Helper.separate_ib_gib!(identity_ib_gib)
    assert Helper.gib_stamped?(identity_gib)
  end

  @tag :capture_log
  test "get_identity, email, token, baby steps" do

    # This is the token that we would generate in the email sent to the user.
    # token = RandomGib.Get.some_characters(30)
    # This is the email address we send the login link to
    email = "example@emailaddr.essyoo"

    priv_data = %{
      "email" => email
    }

    ip = "1.2.3.4"
    pub_data = %{
      "ip" => ip,
      "email" => email
    }

    {:ok, identity_ib_gib} = Identity.get_identity(priv_data, pub_data)

    {:ok, identity} = Expression.Supervisor.start_expression(identity_ib_gib)
    identity_info = identity |> get_info!

    Logger.warn "identity_info: #{inspect identity_info}"
  end

  @tag :capture_log
  test "fork with invalid identity_ib_gib, no gib" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = ["invalid ib gib here"]
    dest_ib = "valid ib here"

    {:error, result} =
      root |> fork(identity_ib_gibs, dest_ib)

    Logger.debug "result: #{inspect result}"
  end

  @tag :capture_log
  test "fork with invalid identity_ib_gib, empty string" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = [""]
    dest_ib = "valid ib here"

    {:error, result} =
      root |> fork(identity_ib_gibs, dest_ib)

    Logger.debug "result: #{inspect result}"
  end

  @tag :capture_log
  test "fork with invalid identity_ib_gib, two identity ib gib, one invalid" do
    {:ok, root} = Expression.Supervisor.start_expression()

    identity_ib_gibs = ["valid#{@delim}gib", "invalid ib gib here"]
    dest_ib = "valid ib here"

    {:error, result} =
      root |> fork(identity_ib_gibs, dest_ib)

    Logger.debug "result: #{inspect result}"
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

    Logger.debug "result: #{inspect result}"
  end

end
