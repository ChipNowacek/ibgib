defmodule WebGib.Web.Components.Details.IdentEmail do
  @moduledoc """
  This contains the ident (email) details view, shown when the user clicks the
  identemail menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :ident_email_details do

    # Ident (Email) details
    div [id: "ib-ident-details", class: "ib-details-off"] do
      form [action: "/ibgib/ident", method: "post"] do
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [id: "ident_form_data_src_ib_gib", name: "ident_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "ident_form_data[ident_type]", type: "hidden", value: "email"]
        p "Email Address: "
        div do
          input [id: "ident_form_data_text", name: "ident_form_data[ident_text]", value: ""]
        end
        p [class: "ib-tooltip"] do
          "1-time Security Pin (optional): "
          span [class: "ib-center-glyph glyphicon glyphicon-question-sign ib-green"]
          span [class: "ib-tooltiptext-smallfont"], do: gettext("If provided, you will enter this pin in a proceeding screen for an additional layer of optional security. Choose a random, short pin just for this login.")
        end
        div do
          input [id: "ident_form_data_pin", name: "ident_form_data[ident_pin]",type: "password", value: ""]
        end
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-envelope ib-green"]
            span [class: "ib-tooltiptext"], do: gettext("Send Login Email")
          end
        end
      end
    end

  end

end
