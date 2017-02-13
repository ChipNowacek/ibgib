defmodule WebGib.Web.Components.Details.Tag do
  @moduledoc """
  This contains the Tag details view, shown when the user clicks the Tag
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  use IbGib.Constants, :validation
  # Need to expose via function, because in the Marker component macro, the `@`
  # attempts to pull from assigns (not a module attribute).
  defp max_tag_text_size, do: @max_tag_text_size
  defp max_tag_icons_text_size, do: @max_tag_icons_text_size

  component :tag_details do

    # Tag details
    # This is shown when the user presses the tag button on an ibGib.
    div [id: "ib-tag-details", class: "ib-details-off"] do
      form [id: "ib-tag-details-form", action: "/ibgib/tag", method: "post"] do
        input [id: "tag_form_data_src_ib_gib", name: "tag_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        p "Tag: "
        input [id: "tag_form_data_text", required: "", name: "tag_form_data[tag_text]", maxlength: max_tag_text_size, title: "Enter your tags separated by spaces. Tags can only contains letters, numbers, and dashes. The max total length is #{max_tag_text_size} characters.", pattern: "[a-zA-Z0-9 \-]+", value: ""]
        input [id: "tag_form_data_icons_text", required: "", name: "tag_form_data[tag_icons_text]", maxlength: max_tag_icons_text_size, title: "Enter your tag's icon(s) text up to #{max_tag_icons_text_size} characters. Markdown is supported. We recommend a max of three icons.", type: "text", value: ":bookmark:"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-tag ib-green"]
          # span [class: "ib-tooltiptext"], do: gettext("Submit tag")
          end
        end
      end
    end

  end

end
