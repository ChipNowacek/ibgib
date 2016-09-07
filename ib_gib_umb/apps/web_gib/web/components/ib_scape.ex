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
      # div [id: "ib-d3-graph-menu-div"] do
        
      # end       
    end
  end

end
