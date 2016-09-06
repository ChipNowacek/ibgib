defmodule WebGib.Web.Components.IbScape do
  @moduledoc """
  This is an ib landscape, stage, canvas, whatever. It's an area that basically
  will have a canvas to start with.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :ib_scape do
    p ["ib scape"]
    div [name: @canvas_div_name,
         id: "ib-d3-graph-div",
         class: "ib-scape-main-div ib-height-100"] do
      # canvas
      # svg [width: 100, height: 100] do
      #   # line [class: "ib-svg-line1, x1: 0, y1: 0, x2: 50, y2: 50, stroke: "green", "stroke-width": 1] do
      #   line [class: "ib-svg-line1", x1: 0, y1: 0, x2: 50, y2: 50] do
      #   end
      # end

    end
  end

end
