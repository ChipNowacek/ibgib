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


  template :enterpin do
    div [class: "ib-height-100"] do
      div [class: "ib-info-border ib-height-100"] do

        # Enter pin form
        # This is shown when the user has clicked on the login link in email
        # and needs to enter the confirmation pin to login.
        div [id: "ib-enterpin-details"] do
          form [action: "/ibgib/ident", method: "post"] do
            input [id: "enterpin_form_data_token", name: "enterpin_form_data[token]",type: "hidden", value: "#{@ident_email_token_key}"]
            input [name: "_utf8", type: "hidden", value: "✓"]
            p "Pin:"
            input [id: "enterpin_form_data_ident_pin", name: "enterpin_form_data[ident_pin]",  type: "password", value: ""]
            input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
            div [class: "ib-tooltip"] do
              button [type: "submit"] do
                span [class: "ib-center-glyph glyphicon glyphicon-flash ib-green"]
                span [class: "ib-tooltiptext"], do: gettext("Wah wah wah...")
              end
            end
          end
        end

      end
    end
  end

  def render("enterpin.html", assigns), do: enterpin(assigns)

end
