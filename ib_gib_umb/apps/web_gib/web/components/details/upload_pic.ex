defmodule WebGib.Web.Components.Details.UploadPic do
  @moduledoc """
  This contains the Upload details view, shown when the user clicks the upload
  pic menu command.
  """

  use Marker

  import WebGib.Gettext
  use WebGib.MarkerElements

  component :upload_pic_details do

    # Upload pic details
    # This is shown when the user presses the image button on an ibGib.
    div [id: "ib-pic-details", class: "ib-details-off"] do
      form [id: "ib-pic-details-form", action: "/ibgib/pic", method: "post", enctype: "multipart/form-data"] do
        div [class: "form-group ib-hidden"] do
          input [name: "_utf8", type: "hidden", value: "✓"]
          input [id: "pic_form_data_src_ib_gib", name: "pic_form_data[src_ib_gib]",type: "hidden", value: ""]
          input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        end
        div [class: "form-group"] do
          label "Select an image to upload: ", for: "pic_form_data_file"
          input [id: "pic_form_data_file", name: "pic_form_data[pic_data]", class: "form-control", type: "file", required: "true"]
        end
        div [class: "form-group"] do
          div [class: "ib-tooltip"] do
            button [type: "submit"] do
              span [class: "ib-center-glyph glyphicon glyphicon-cloud-upload ib-green"]
            # span [class: "ib-tooltiptext"], do: gettext("Upload picture")
            end
          end
        end
      end
    end

  end

end
