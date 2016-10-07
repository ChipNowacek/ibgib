defmodule WebGib.EnterPinView do
  use WebGib.Web, :view

  template :emaillogin do
    div [class: "ib-height-100"] do
      div [class: "ib-info-border ib-height-100"] do

        # Enter pin form
        # This is shown when the user has clicked on the login link in email
        # and needs to enter the confirmation pin to login.
        div [id: "ib-enterpin-details"] do
          form [action: "/ibgib/ident", method: "post"] do
            input [id: "enterpin_form_data_token", name: "enterpin_form_data[token]",type: "hidden", value: ""]
            input [name: "_utf8", type: "hidden", value: "✓"]
            p "Pin:"
            input [id: "enterpin_form_data_ident_pin", name: "enterpin_form_data[ident_pin]",  type: "text", value: "ib"]
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

  def render("emaillogin.html", assigns), do: emaillogin(assigns)
end
