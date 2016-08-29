defmodule WebGib.Web.Components.IbLine1 do
  @moduledoc """
  This is a line.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :ib_line_1 do
    div do

      p ["ib line 1"]
      svg [width: 100, height: 100] do
        # line [class: "ib-svg-line1, x1: 0, y1: 0, x2: 50, y2: 50, stroke: "green", "stroke-width": 1] do
        line [class: "ib-svg-line1", x1: 0, y1: 0, x2: 50, y2: 50] do
        end
      end

    end
  end

end
