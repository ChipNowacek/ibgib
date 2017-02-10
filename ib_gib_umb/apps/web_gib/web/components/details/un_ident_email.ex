defmodule WebGib.Web.Components.Details.UnIdentEmail do
  @moduledoc """
  This contains the unident (email) details view, shown when the user clicks the
  unidentemail menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  use IbGib.Constants, :validation
  use WebGib.Constants, :validation

  component :un_ident_email_details do

    # UnIdent (Email) details
    div [id: "ib-unidentemail-details", class: "ib-details-off"] do
      form [id: "ib-unidentemail-details-form", action: "/ibgib/ident", method: "post"] do
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [id: "unidentemail_form_data_src_ib_gib", name: "unidentemail_form_data[src_ib_gib]", type: "hidden", value: ""]
        # input [id: "unidentemail_form_data_email_addr", name: "unidentemail_form_data[email_addr]", type: "hidden", value: ""]
        input [name: "unidentemail_form_data[ident_type]", type: "hidden", value: "email"]
        p do
          "Remove " 
          span [id: "unidentemail_form_data_email_addr", class: "ib-bold"]
          " from your current identification?"
        end

        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [id: "ib-unidentemail-details-submit", class: "ib-tooltip"] do
          button [id: "ib-unidentemail-details-submit-btn", type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-envelope ib-green ib-left-icon-span"]
            span [class: "ib-center-glyph glyphicon glyphicon-log-out ib-green"]
          end
        end
        
        br
        
        p [id: "ib-unidentemail-details-note"] do
          "Note: This will not log out any other email address(es) you are identified by."
        end
      end
    end

  end

end
