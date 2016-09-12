defmodule WebGib.Web.Components.IbScape do
  @moduledoc """
  This is an ib landscape, stage, canvas, whatever. It's an area that basically
  will have a canvas to start with.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :ib_scape do
    div [name: @canvas_div_name,
         id: "ib-d3-graph-div",
         class: "ib-height-100"] do

      div [id: "ib-scape-details", class: "ib-hidden ib-pos-abs ib-info-border"] do
        div [id: "ib-fork-details", class: "ib-hidden"] do
          form [action: "/ibgib/fork", method: "post"] do
            input [id: "fork_form_data_src_ib_gib", name: "fork_form_data[src_ib_gib]",type: "hidden", value: ""]
            input [name: "_utf8", type: "hidden", value: "✓"]
            p "Give it an ib (usually a name):   "
            input [id: "fork_form_data_dest_ib", name: "fork_form_data[dest_ib]",  type: "text", value: "ib"]
            input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
            div [class: "ib-tooltip"] do
              button [type: "submit"] do
                span [class: "ib-center-glyph glyphicon glyphicon-flash ib-green"]
                span [class: "ib-tooltiptext"], do: gettext("Go 8-)")
              end
            end
          end
          div [id: "ib-scape-details-close"] do
            button [id: "ib-scape-details-close-btn"], do: "Cancel"
          end
        end
      end
    end
  end

end
