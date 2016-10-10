defmodule WebGib.Web.Components.Details.Help do
  @moduledoc """
  This contains the Help details view, shown when the user clicks the help
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :help_details do

    div [id: "ib-help-details", class: "ib-details-off"] do
      p [id: "ib-help-details-text"], do: "Help goes here."
    end

  end

end
