defmodule WebGib.Web.Components.Details.IdentEmail do
  @moduledoc """
  This contains the ident (email) details view, shown when the user clicks the
  identemail menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  use IbGib.Constants, :validation
  use WebGib.Constants, :validation
  # Need to expose via function, because in the Marker component macro, the `@`
  # attempts to pull from assigns (not a module attribute).
  defp min_email_addr_size, do: @min_email_addr_size
  defp max_email_addr_size, do: @max_email_addr_size
  defp max_ident_pin_size, do: @max_ident_pin_size


  component :ident_email_details do

    # Ident (Email) details
    div [id: "ib-identemail-details", class: "ib-details-off"] do
      form [id: "ib-identemail-details-form", action: "/ibgib/ident", method: "post"] do
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [id: "identemail_form_data_src_ib_gib", name: "identemail_form_data[src_ib_gib]", type: "hidden", value: ""]
        input [name: "identemail_form_data[ident_type]", type: "hidden", value: "email"]
        p "Email Address: "
        div do
          input [
            id: "identemail_form_data_text",
            name: "identemail_form_data[ident_text]",
            type: "email",
            pattern: ".{#{min_email_addr_size},#{max_email_addr_size}}",
            required: "",
            title: "Please enter a valid email address with a maximum of #{max_email_addr_size} characters.",
            value: ""
          ]
        end
        p [class: "ib-tooltip"] do
          "1-time Security Pin (optional): "
          span [class: "ib-center-glyph glyphicon glyphicon-question-sign ib-green"]
          span [class: "ib-tooltiptext-smallfont"], do: gettext("For additional security, you can enter a short pin here. If you enter this, you will be re-prompted for it after opening the link in your email. This is just a 1-time 'throwaway' pin! Make it random and short for this login.")
        end
        div do
          input [id: "identemail_form_data_pin", name: "identemail_form_data[ident_pin]",type: "password", maxlength: max_ident_pin_size, value: ""]
        end
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-envelope ib-green"]
          # span [class: "ib-tooltiptext"], do: gettext("Send Login Email")
          end
        end
      end
    end

  end

end
