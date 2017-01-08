defmodule WebGib.Test.Plugs.EnsureIbGibSessionTest do
  @moduledoc """
  Test the `WebGib.Plugs.EnsureIbGibSession` plug which ensures that there is
  an ibgib session in session. If not, then it redirects.
  """
  use WebGib.ConnCase
  require Logger

  setup context do
    Logger.disable(self())
    Code.load_file("../../apps/ib_gib/priv/repo/seeds.exs")
    Logger.enable(self())
  end

  @tag :capture_log
  test "GET /", %{conn: conn} do
    _ = Logger.warn "plug test here"
    conn = get conn, "/"

    _ = Logger.debug "conn: #{inspect conn}"
    assert conn.status === 200
    assert !conn.halted
    # root = conn.assigns[:root]
    # _ = Logger.debug "root: #{inspect root}"
    # assert is_pid(root)
    # assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end

  @tag :capture_log
  test "GET /login, should redirect/halt", %{conn: conn} do
    _ = Logger.warn "plug test here"
    conn = get conn, "/ibgib"

    _ = Logger.debug "conn: #{inspect conn}"
    assert conn.status === 302
    assert conn.halted
  end

end
