defmodule WebGib.Web.Components.Details.Download do
  @moduledoc """
  This contains the Download details view, shown when the user clicks the Download
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext


  component :download_details do

    # Download details
    # This is shown when the user presses the download button on an ibGib.
    div [id: "ib-download-details", class: "ib-details-off"] do
      h1 "Download Pic"

      label [class: "ib-details-label", for: "download_form_filename"] do
        "Filename: "
      end
      input [id: "download_form_filename", value: "Filename not set, so don't click download :-/"]

      div [class: "ib-tooltip download_form_submit_btn_div"] do
        a [id: "download_form_submit_btn", href: "#", download: "not set"] do
          span [class: "ib-center-glyph glyphicon glyphicon-cloud-download ib-green"]
        # span [class: "ib-tooltiptext"], do: gettext("Download")
        end
      end

      div do
        label [class: "ib-details-label", for: "ib-download-thumbnail"] do
          "Preview: "
        end
        div do
          img [id: "ib-download-thumbnail"]
        end
      end

      label [class: "ib-details-label", for: "download_form_filetype"] do
        "URL: "
      end
      p [id: "download_form_url", value: "not set"]

      label [class: "ib-details-label", for: "download_form_filetype"] do
        "Filetype: "
      end
      p [id: "download_form_filetype", value: "not set"]
    end

  end

end
