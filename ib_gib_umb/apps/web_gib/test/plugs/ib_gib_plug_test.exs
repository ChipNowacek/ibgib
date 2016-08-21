defmodule WebGib.Test.Plugs.IbGibPlugTest do
  use WebGib.ConnCase
  require Logger

  setup context do
    Logger.configure(level: :error)
    Code.load_file("../../apps/ib_gib/priv/repo/seeds.exs")
    Logger.configure(level: :debug)
  end

  test "GET /", %{conn: conn} do
    Logger.warn "plug test here"
    conn = get conn, "/"

    root = conn.assigns[:root]
    Logger.debug "root: #{inspect root}"
    assert is_pid(root)
    # assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
