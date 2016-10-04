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

      # Because I can't figure out how to do this (or any of the UI) nicely,
      # I've created these hidden divs that I show when I need them.
      # The positioning, showing/hiding is all done of course in the js.
      div [id: "ib-scape-details", class: "ib-details-off ib-pos-abs"] do

        # Fork details
        # This is shown when the user presses the fork button on an ibGib.
        div [id: "ib-fork-details", class: "ib-details-off"] do
          form [action: "/ibgib/fork", method: "post"] do
            input [id: "fork_form_data_src_ib_gib", name: "fork_form_data[src_ib_gib]",type: "hidden", value: ""]
            input [name: "_utf8", type: "hidden", value: "✓"]
            p "Give it an ib (usually a name):   "
            input [id: "fork_form_data_dest_ib", name: "fork_form_data[dest_ib]",  type: "text", value: "ib"]
            input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
            div [class: "ib-tooltip"] do
              button [type: "submit"] do
                span [class: "ib-center-glyph glyphicon glyphicon-flash ib-green"]
                span [class: "ib-tooltiptext"], do: gettext("Go 8-)")
              end
            end
          end
        end

        div [id: "ib-help-details", class: "ib-details-off"] do
          p [id: "ib-help-details-text"], do: "Help goes here."
        end

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

        # Upload pic details
        # This is shown when the user presses the image button on an ibGib.
        div [id: "ib-pic-details", class: "ib-details-off"] do
          form [action: "/ibgib/pic", method: "post", enctype: "multipart/form-data"] do
            div [class: "form-group"] do
              input [name: "_utf8", type: "hidden", value: "✓"]
              input [id: "pic_form_data_src_ib_gib", name: "pic_form_data[src_ib_gib]",type: "hidden", value: ""]
              input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
              label "Select an image to upload: "
              input [id: "pic_form_data_file", name: "pic_form_data[pic_data]", class: "form-control", type: "file"]
            end
            div [class: "form-group"] do
              div [class: "ib-tooltip"] do
                button [type: "submit"] do
                  span [class: "ib-center-glyph glyphicon glyphicon-cloud-upload ib-green"]
                  span [class: "ib-tooltiptext"], do: gettext("Upload picture")
                end
              end
            end
          end
        end

        # Link details
        # This is shown when the user presses the link button on an ibGib.
        div [id: "ib-link-details", class: "ib-details-off"] do
          form [action: "/ibgib/link", method: "post"] do
            input [id: "link_form_data_src_ib_gib", name: "link_form_data[src_ib_gib]",type: "hidden", value: ""]
            input [name: "_utf8", type: "hidden", value: "✓"]
            p "Enter hyperlink URL: "
            input [id: "link_form_data_text", name: "link_form_data[link_text]", value: ""]
            input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
            div [class: "ib-tooltip"] do
              button [type: "submit"] do
                span [class: "ib-center-glyph glyphicon glyphicon-link ib-green"]
                span [class: "ib-tooltiptext"], do: gettext("Add Link")
              end
            end
          end
        end

      end
    end
  end

end
