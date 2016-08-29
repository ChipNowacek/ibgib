defmodule WebGib.PageControllerTest do
  @moduledoc """
  Tests the `WebGib.PageController`.
  """

  use WebGib.ConnCase

  @tag :capture_log
  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    # assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
