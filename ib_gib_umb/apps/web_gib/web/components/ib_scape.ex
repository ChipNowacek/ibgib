defmodule WebGib.Web.Components.IbScape do
  @moduledoc """
  This is an ib landscape, stage, canvas, whatever. It's an area that basically
  will have a canvas to start with.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext
  import WebGib.Web.Components.Details.{Fork, Help, Comment, UploadPic, Link, IdentEmail, UnIdentEmail, Info, Query, Download, Huh, Tag}

  component :ib_scape do

    div [name: @canvas_div_name,
         id: "ib-d3-graph-div",
         class: "ib-height-100"] do

      # These are hidden divs that I show when I need them.
      # The positioning, showing/hiding is all done in the js.
      div [id: "ib-scape-details", class: "ib-details-off ib-pos-abs"] do
        button [name: "ib-scape-details-close-btn"] do
          span [class: "close ib-center-glyph glyphicon glyphicon-remove ib-red"]
        end

        fork_details
        help_details
        comment_details
        upload_pic_details
        link_details
        ident_email_details
        un_ident_email_details
        info_details
        query_details
        download_details
        # add_ib_gib_details
        huh_details
        tag_details
      end

    end

  end

end
