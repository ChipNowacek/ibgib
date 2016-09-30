defmodule WebGib.Test.Plugs.IbGibRootTest do
  @moduledoc """
  Test the `WebGib.Plugs.IbGibRoot` plug which adds in the root instance to
  conn assigns.
  """
  use WebGib.ConnCase
  require Logger

  setup context do
    Logger.disable(self)
    Code.load_file("../../apps/ib_gib/priv/repo/seeds.exs")
    Logger.enable(self)
  end

  @tag :capture_log
  test "GET /, home page doesn't get root injected", %{conn: conn} do
    _ = Logger.warn "plug test here"
    conn = get conn, "/"

    root = conn.assigns[:root]
    _ = Logger.debug "root: #{inspect root}"
    assert is_nil(root)
    # assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
