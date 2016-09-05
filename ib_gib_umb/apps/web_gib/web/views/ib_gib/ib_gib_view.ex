defmodule WebGib.IbGibView do
  use WebGib.Web, :view

  import WebGib.Web.Components.Login
  import WebGib.Web.Components.IbCircle1
  import WebGib.Web.Components.IbLine1
  import WebGib.Web.Components.IbScape

  template :index do
    div do
      p do
        "Yo this is the ibgib index template."
      end
      div do
        div [id: "messages"] do

        end
        input [id: "chat-input", type: "text", value: "chat input here"]
      end

      div [class: "ib-info-border"] do
        p ["Meta Query"]
        div [
          id: "metaqueryibgib",
          "data-metaqueryibgib": "#{@meta_query_ib_gib}",
          "data-metaqueryresultibgib": "#{@meta_query_result_ib_gib}",
          "data-path": "#{WebGib.Router.Helpers.ib_gib_path(WebGib.Endpoint, :getd3, "")}",
          "visibility": "hidden"
        ]
        p ["meta_query_ib_gib: #{@meta_query_ib_gib}"]
        p ["meta_query_result_ib_gib: #{@meta_query_result_ib_gib}"]
        div [id: "ib-d3-graph-div"] do
          # canvas [id: "ib-d3-graph-canvas"] do
          #
          # end
          svg [id: "ib-d3-graph-canvas"] do

          end
        end
        WebGib.Web.Components.IbScape.ib_scape([conn: @conn, canvas_div_name: "ib-div-meta-query"])
      end
      div [class: "ib-info-border"] do
        WebGib.Web.Components.Login.login([conn: @conn])
      end
      div [class: "ib-info-border"] do
        WebGib.Web.Components.IbCircle1.ib_circle_1([conn: @conn])
      end
      div [class: "ib-info-border"] do
        WebGib.Web.Components.IbLine1.ib_line_1([conn: @conn])
      end
      div [class: "ib-info-border"] do
        WebGib.Web.Components.IbScape.ib_scape([conn: @conn, canvas_div_name: "ib-div-test"])
      end

    end
  end

  def render("index.html", assigns), do: index(assigns)
end
