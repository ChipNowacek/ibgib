defmodule WebGib.Web.Components.Details.Comment do
  @moduledoc """
  This contains the Comment details view, shown when the user clicks the Comment
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  component :comment_details do

    # Comment details
    # This is shown when the user presses the comment button on an ibGib.
    div [id: "ib-comment-details", class: "ib-details-off"] do
      form [action: "/ibgib/comment", method: "post"] do
        input [id: "comment_form_data_src_ib_gib", name: "comment_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        p "Comment: "
        # input [id: "comment_form_data_text", name: "comment_form_data[comment_text]",  type: "text", value: "ib"]
        textarea [id: "comment_form_data_text", name: "comment_form_data[comment_text]", value: "ib"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-comment ib-green"]
            span [class: "ib-tooltiptext"], do: gettext("Submit comment")
          end
        end
      end
    end

  end

end
