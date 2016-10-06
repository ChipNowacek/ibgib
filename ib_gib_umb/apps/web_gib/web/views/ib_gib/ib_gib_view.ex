defmodule WebGib.IbGibView do
  use WebGib.Web, :view

  import WebGib.Web.Components.Login
  import WebGib.Web.Components.IbCircle1
  import WebGib.Web.Components.IbLine1
  import WebGib.Web.Components.IbScape

  template :show do
    div [class: "ib-height-100"] do
      div [class: "ib-info-border ib-height-100"] do
        WebGib.Web.Components.IbScape.ib_scape([conn: @conn, canvas_div_name: "ib-div-meta-query", class: "ib-height-100"])
        span [
          id: "ibgib-data",
          "ibgib": "#{@ib_gib}",
          "data-metaqueryibgib": "#{@meta_query_ib_gib}",
          "data-metaqueryresultibgib": "#{@meta_query_result_ib_gib}",
          "data-path": "#{WebGib.Router.Helpers.ib_gib_path(WebGib.Endpoint, :get, "")}",
          "d3-data-path": "#{WebGib.Router.Helpers.ib_gib_path(WebGib.Endpoint, :getd3, "")}",
          "data-open-path": "#{WebGib.Router.Helpers.ib_gib_path(WebGib.Endpoint, :show, "")}",
          "visibility": "hidden"
        ]
      end
    end
  end

  def render("show.html", assigns), do: show(assigns)
end
