defmodule WebGib.Web.Components.Details.Info do
  @moduledoc """
  This contains the info details view, shown when the user clicks the info
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext


  component :info_details do

    # Info details
    div [id: "ib-info-details", class: "ib-details-off"] do
      form [action: "/ibgib/info", method: "post"] do
        input [id: "info_form_data_src_ib_gib", name: "info_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        p "Ibformation: "
        div [id: "ib-info-details-container"] do
          # input [id: "info_form_data_dest_ib", name: "info_form_data[dest_ib]",  type: "text", value: ""]
          # Here is where js will populate tags based on the ibGib
        end
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-floppy-disk ib-green"]
            span [class: "ib-tooltiptext"], do: gettext("Save it :-O")
          end
        end
      end
    end

  end

end
