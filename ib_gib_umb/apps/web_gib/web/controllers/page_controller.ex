defmodule WebGib.PageController do
  use WebGib.Web, :controller
  require Logger

  def index(conn, %{"action" => action} = params) do
    Logger.warn "yooooo fork huh"
    render conn, "index.html"
  end
  def index(conn, _params) do
    Logger.warn "yooooo index huh"
    render conn, "index.html"
  end
end
