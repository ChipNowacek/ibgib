defmodule WebGib.Web.Components.Details.Link do
  @moduledoc """
  This contains the Link details view, shown when the user clicks the Link
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :link_details do

    # Link details
    # This is shown when the user presses the link button on an ibGib.
    div [id: "ib-link-details", class: "ib-details-off"] do
      form [action: "/ibgib/link", method: "post"] do
        input [id: "link_form_data_src_ib_gib", name: "link_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        p "Enter hyperlink URL: "
        input [id: "link_form_data_text", name: "link_form_data[link_text]", value: ""]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-link ib-green"]
            span [class: "ib-tooltiptext"], do: gettext("Add Link")
          end
        end
      end
    end


  end

end
