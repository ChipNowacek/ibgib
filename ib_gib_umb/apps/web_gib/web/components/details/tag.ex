defmodule WebGib.Web.Components.Details.Tag do
  @moduledoc """
  This contains the Tag details view, shown when the user clicks the Tag
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  use IbGib.Constants, :validation
  use WebGib.Constants, :tags
  
  # Need to expose via function, because in the Marker component macro, the `@`
  # attempts to pull from assigns (not a module attribute).
  defp max_tag_text_size, do: @max_tag_text_size
  defp max_tag_icons_text_size, do: @max_tag_icons_text_size
  defp ib_tag_presets, do: @ib_tag_presets

  component :tag_details do

    # Tag details
    # This is shown when the user presses the tag button on an ibGib.
    div [id: "ib-tag-details", class: "ib-details-off"] do
      form [id: "ib-tag-details-form", class: "ib-height-100 ib-overflow-y-auto ib-no-scroll-x", action: "/ibgib/tag", method: "post"] do
        input [id: "tag_form_data_src_ib_gib", name: "tag_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]

        # Tag details (text, icons, submit)
        fieldset [class: "ib-details-fieldset"] do
          legend [class: "ib-details-legend"], do: "tag"
          div class: "container ib-width-100" do
              
              div class: "row ib-details-tag-row" do
                div class: "col-xs-10 col-sm-2 col-md-2 col-lg-1" do
                  label [class: "ib-details-label", for: "tag_form_data_text"] do
                    "text"
                  end
                end
                div class: "col-xs-10 col-sm-7 col-md-10 col-lg-11" do
                  input [id: "tag_form_data_text", class: "ib-details-tag-input", required: "", name: "tag_form_data[tag_text]", maxlength: max_tag_text_size, title: "Enter your tags separated by spaces. Tags can only contains letters, numbers, and dashes. The max total length is #{max_tag_text_size} characters.", pattern: "[a-zA-Z0-9 \-]+", value: ""]
                end
              end
                
              div class: "row ib-details-tag-row" do
                div class: "col-xs-10 col-sm-2 col-md-2 col-lg-1" do
                  label [class: "ib-details-label", for: "tag_form_data_icons_text"] do
                    "icon(s)"
                  end
                end
                div class: "col-xs-10 col-sm-7 col-md-10 col-lg-11" do
                  input [id: "tag_form_data_icons_text", class: "ib-details-tag-input", required: "", name: "tag_form_data[tag_icons_text]", maxlength: max_tag_icons_text_size, title: "Enter your tag's icon(s) text up to #{max_tag_icons_text_size} characters. Markdown is supported. We recommend a max of three icons.", type: "text", value: ""]
                end
              end
              
              # Submit button
              div class: "row" do
                div [class: "col-xs-6 ib-tooltip ib-details-tag-submit-col"] do
                  button [type: "submit ib-details-tag-submit-btn"] do
                    span [class: "ib-center-glyph glyphicon glyphicon-tag ib-green"]
                  # span [class: "ib-tooltiptext"], do: gettext("Submit tag")
                  end
                end
                
              end
              
          end
        end
        
        # presets
        div do
          fieldset [class: "ib-details-fieldset"] do
            legend [class: "ib-details-legend"], do: "presets"
            div class: "container ib-width-100" do

              ib_tag_presets()
              |> Enum.map(fn(m) -> 
                 div class: "col-xs-6 col-sm-2 ib-details-tag-preset" do
                   button [id: "ib-details-tag-btn-preset-#{m.name}", class: "ib-details-tag-btn-preset", type: "button"] do
                     span [class: "ib-center-glyph glyphicon glyphicon-#{m.glyph} ib-green"]
                   end
                 end
               end)
               
            end
          end

        end


      end # form
      
      
    end # details

  end

end
