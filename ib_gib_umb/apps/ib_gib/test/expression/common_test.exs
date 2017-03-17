defmodule IbGib.Expression.CommonTest do
  @moduledoc """
  Tests IbGib.Common module.
  """

  import OK, only: ["~>>": 2]
  require Logger
  require OK
  use ExUnit.Case

  alias IbGib.Common
  import IbGib.{Expression, Helper}
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

  @tag :capture_log
  test "get_latest_ib_gib of root is root" do
    OK.with do
      latest_ib_gib <-
        Common.get_latest_ib_gib(@test_identities_1, @root_ib_gib)

      assert latest_ib_gib == @root_ib_gib

      OK.success :ok
    else
      error -> raise "test error: #{inspect error}"
    end
  end

  @tag :capture_log
  test "get_latest_ib_gib success" do
    OK.with do
      root <- IbGib.Expression.Supervisor.start_expression()
      a_ib = "a"
      a <- root |> fork(@test_identities_1, a_ib)
      a_ib_gib <- a |> get_info() ~>> get_ib_gib()
      
      a_4_ib_gib <- 
        {:ok, a}
        ~>> mut8(@test_identities_1, %{"i" => "1"})
        ~>> mut8(@test_identities_1, %{"i" => "2"})
        ~>> mut8(@test_identities_1, %{"i" => "3"})
        ~>> mut8(@test_identities_1, %{"i" => "4"})
        ~>> get_info() 
        ~>> get_ib_gib()

      a_latest_ib_gib <-
        Common.get_latest_ib_gib(@test_identities_1, a_ib_gib)

      assert a_latest_ib_gib == a_4_ib_gib
      assert a_latest_ib_gib != a_ib_gib # probably overkill testing for this

      OK.success :ok
    else
      error -> raise "test error: #{inspect error}"
    end
  end

  @tag :capture_log
  test "get_latest_ib_gib errors with identity_ib_gibs empty list" do
    OK.with do
      root <- IbGib.Expression.Supervisor.start_expression()
      a_ib = "a"
      a <- root |> fork(@test_identities_1, a_ib)
      a_ib_gib <- a |> get_info() ~>> get_ib_gib()
      
      a_4_ib_gib <- 
        {:ok, a}
        ~>> mut8(@test_identities_1, %{"i" => "1"})
        ~>> mut8(@test_identities_1, %{"i" => "2"})
        ~>> mut8(@test_identities_1, %{"i" => "3"})
        ~>> mut8(@test_identities_1, %{"i" => "4"})
        ~>> get_info() 
        ~>> get_ib_gib()

      a_latest_ib_gib <-
        Common.get_latest_ib_gib([], a_ib_gib)
      
      raise "should not get here"
    else
      error when is_bitstring(error) -> 
        if String.contains?(error, "Invalid args") do
          OK.success "test passes"
        else
          raise "expected error: Invalid args. actual error: #{error}"
        end
      
      error -> 
        raise "expected error: Invalid args. actual error: #{inspect error}"
    end
  end

  @tag :capture_log
  test "get_latest_ib_gib errors with identity_ib_gibs nil" do
    OK.with do
      root <- IbGib.Expression.Supervisor.start_expression()
      a_ib = "a"
      a <- root |> fork(@test_identities_1, a_ib)
      a_ib_gib <- a |> get_info() ~>> get_ib_gib()
      
      a_4_ib_gib <- 
        {:ok, a}
        ~>> mut8(@test_identities_1, %{"i" => "1"})
        ~>> mut8(@test_identities_1, %{"i" => "2"})
        ~>> mut8(@test_identities_1, %{"i" => "3"})
        ~>> mut8(@test_identities_1, %{"i" => "4"})
        ~>> get_info() 
        ~>> get_ib_gib()

      a_latest_ib_gib <-
        Common.get_latest_ib_gib(nil, a_ib_gib)
      
      raise "should not get here"
    else
      error when is_bitstring(error) -> 
        if String.contains?(error, "Invalid args") do
          OK.success "test passes"
        else
          raise "expected error: Invalid args. actual error: #{error}"
        end
      
      error -> 
        raise "expected error: Invalid args. actual error: #{inspect error}"
    end
  end

end
