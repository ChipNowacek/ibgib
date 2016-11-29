defmodule WebGib.Web.Components.Details.AddIbGib do
  @moduledoc """
  This contains the fork details view, shown when the user clicks the fork
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  use IbGib.Constants, :ib_gib
  # Need to expose via function, because in the Marker component macro, the `@`
  # attempts to pull from assigns (not a module attribute).
  defp max_id_length, do: @max_id_length

  component :add_ib_gib_details do

    # AddIbGib details
    # This is shown when the user presses the Add IbGib button on an ibGib.
    div [id: "ib-addibgib-details", class: "ib-details-off"] do
      form [action: "/ibgib/addibgib", method: "post"] do
        input [id: "addibgib_form_data_src_ib_gib", name: "addibgib_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        p "Give it an ib:   "
        input [id: "addibgib_form_data_dest_ib",
               name: "addibgib_form_data[dest_ib]",
               type: "text",
               maxlength: max_id_length,
               value: ""]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-flash ib-green"]
            span [class: "ib-tooltiptext"], do: gettext("Go 8-)")
          end
        end
      end
    end

  end

end
