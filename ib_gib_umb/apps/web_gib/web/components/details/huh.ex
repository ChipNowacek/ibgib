defmodule WebGib.Web.Components.Details.Huh do
  @moduledoc """
  This contains the Huh details view, shown when the user clicks the huh
  menu command.

  Help is for a quick little explanation. Huh is for "Huh?! What is going on
  right now? I'm very confused."

  See also `WebGib.Web.Components.Details.Help`.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :huh_details do

    div [id: "ib-huh-details", class: "ib-details-off"] do
      # new <p> tags (and whatever) will be added to this div.
    end

  end

end
