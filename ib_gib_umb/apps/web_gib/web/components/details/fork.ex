defmodule WebGib.Web.Components.Details.Fork do
  @moduledoc """
  This contains the fork details view, shown when the user clicks the fork
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext


  component :fork_details do

    # Fork details
    # This is shown when the user presses the fork button on an ibGib.
    div [id: "ib-fork-details", class: "ib-details-off"] do
      form [action: "/ibgib/fork", method: "post"] do
        input [id: "fork_form_data_src_ib_gib", name: "fork_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        p "Give it an ib:   "
        input [id: "fork_form_data_dest_ib", name: "fork_form_data[dest_ib]",  type: "text", value: ""]
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
