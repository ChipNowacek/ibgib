defmodule WebGib.IbGibView do
  use WebGib.Web, :view
  use WebGib.Web, :controller

  import WebGib.Web.Components.Login
  import WebGib.Web.Components.IbCircle1
  import WebGib.Web.Components.IbLine1
  import WebGib.Web.Components.IbScape

  template :index do
    div do
      p do
        "Yo this is the ibgib index template. #{@meta_query}"
      end
      div [class: "ib-info-border"] do
        p ["Meta Query"]
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