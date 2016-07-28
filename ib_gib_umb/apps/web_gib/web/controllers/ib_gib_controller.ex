defmodule WebGib.IbGibController do
  use WebGib.Web, :controller
  require Logger
  import IbGib.Helper

  @delim "^"
  @root_ib_gib "ib#{@delim}gib"

  def index(conn, params) do
    Logger.debug "index. params: #{inspect params}"
    # conn = init_session(conn)
    render conn, "index.html"
  end

  def show(conn, %{"ib_or_ib_gib" => ib_or_ib_gib} = params) do
    as_list = ib_or_ib_gib |> String.split(@delim)
    ib = as_list |> Enum.at(0)
    gib = as_list |> Enum.at(1, "huh, no gib")

    conn
    |> assign(:ib, ib)
    |> assign(:gib, gib)
    |> render "show.html"
  end

end
