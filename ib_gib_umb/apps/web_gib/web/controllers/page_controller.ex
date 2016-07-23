defmodule WebGib.PageController do
  use WebGib.Web, :controller
  require Logger

  def index(conn, _params) do
    render conn, "index.html"
  end

  def fork(conn, %{"action" => action} = params) do
    render conn, "index.html"
  end
end
