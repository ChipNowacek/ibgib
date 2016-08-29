defmodule WebGib.Web.Components.IbCircle1 do
  @moduledoc """
  This is a circle with an ib text in it.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :ib_circle_1 do
    div do

      svg [width: 100, height: 100] do
        circle [class: "ib-svg-circle1", cx: 50, cy: 50, r: 40, value: "hello"]
        text [class: "ib-svg-text1", x: 45, y: 55] do
          "ib"
        end
      end

    end
  end

end
