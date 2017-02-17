defmodule WebGib.Web.Components.Details.Query do
  @moduledoc """
  This contains the query details view, shown when the user clicks the query
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :validation
  use WebGib.Constants, :tags
  # Need to expose via function, because in the Marker component macro, the `@`
  # attempts to pull from assigns (not a module attribute).
  defp max_id_length, do: @max_id_length
  defp min_query_data_text_size, do: @min_query_data_text_size
  defp max_query_data_text_size, do: @max_query_data_text_size
  defp ib_tag_presets, do: @ib_tag_presets

  # What to search for.
  # e.g. ib, keywords, tags, data segment (like comment text or date), etc.
  component :search_what do
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"] do
        "🔍"
        span [class: "ib-tooltip"] do
          span [class: "ib-center-glyph glyphicon glyphicon-question-sign ib-green"]
          span [class: "ib-tooltiptext"], do: gettext("Type in what you want to search for. You can type in partial/whole text for an ib, comment text, a date like '2017' or '%2017%02%14%'.")
        end
      end
      div class: "container" do
        
        # text row
        div class: "row" do
          div class: "col-xs-10" do
            input [id: "query_form_data_search_text",
                   name: "query_form_data[search_text]",
                   type: "text",
                   maxlength: max_query_data_text_size(),
                   required: true,
                   value: ""]
          end
          div class: "col-xs-2" do
          end
        end
        
      end
    end
  end
  
  # How to query for those terms
  # e.g. ib is/has, data, tag is/has
  component :search_how do
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"], do: "how"
      div class: "container" do
        div class: "row" do

          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # ib is
            input [id: "query_form_data_ib_is",
                   name: "query_form_data[ib_is]",
                   type: "checkbox",
                   value: "ib_is"]
            label [class: "ib-details-label", for: "query_form_data_ib_is"] do
              "ib is"
            end
          end

          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # ib has
            input [id: "query_form_data_ib_has",
                   name: "query_form_data[ib_has]",
                   type: "checkbox",
                   value: "ib_has",
                   checked: ""]
            label [class: "ib-details-label", for: "query_form_data_ib_has"] do
              "ib has"
            end
          end

          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # data has
            input [id: "query_form_data_data_has",
                   name: "query_form_data[data_has]",
                   type: "checkbox",
                   value: "data_has",
                   checked: ""]
            label [class: "ib-details-label", for: "query_form_data_data_has"] do
              "data has"
            end
          end

          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # tag is
            input [id: "query_form_data_tag_is",
                   name: "query_form_data[tag_is]",
                   type: "checkbox",
                   value: "tag_is"]
            label [class: "ib-details-label", for: "query_form_data_tag_is"] do
              "tag is"
            end
          end
          
            # # tag has
            # input [id: "query_form_data_tag_has",
            #        name: "query_form_data[tag_has]",
            #        type: "checkbox",
            #        value: "tag_has",
            #        checked: ""]
            # label [class: "ib-details-label", for: "query_form_data_tag_has"] do
            #   "tag has"
            # end

        end
        
        div [id: "ib-details-query-btn-presets-div", class: "row container ib-width-100 ib-hidden"] do
          ib_tag_presets()
          |> Enum.map(fn(m) -> 
             div class: "col-xs-6 col-sm-2 ib-details-tag-preset" do
               button [id: "ib-details-query-btn-preset-#{m.name}", class: "ib-details-tag-btn-preset", type: "button"] do
                 span [class: "ib-center-glyph glyphicon glyphicon-#{m.glyph} ib-green"]
               end
             end
           end)
        end
        
      end
    end
  end

  # "types" of ibGib to include
  # e.g. include pic, comment, dna, query, tag, etc.
  component :include_options do
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"], do: "include"

      div class: "container" do
        div class: "row" do
          
          
          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # pic
            input [id: "query_form_data_include_pic",
                   name: "query_form_data[include_pic]",
                   type: "checkbox",
                   value: "include_pic",
                   checked: ""]
            label [class: "ib-details-label", for: "query_form_data_include_pic"] do
              "pic"
            end
          end
          
          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # comment
            input [id: "query_form_data_include_comment",
                   name: "query_form_data[include_comment]",
                   type: "checkbox",
                   value: "include_comment",
                   checked: ""]
            label [class: "ib-details-label", for: "query_form_data_include_comment"] do
              "comment"
            end
          end

          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # dna
            input [id: "query_form_data_include_dna",
                   name: "query_form_data[include_dna]",
                   type: "checkbox",
                   value: "include_dna"]
            label [class: "ib-details-label", for: "query_form_data_include_dna"] do
              "dna"
            end
          end
          
          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # query
            input [id: "query_form_data_include_query",
                   name: "query_form_data[include_query]",
                   type: "checkbox",
                   value: "include_query"]
            label [class: "ib-details-label", for: "query_form_data_include_query"] do
              "query"
            end
          end
            
          div class: "col-xs-10 col-sm-2 col-md-2 col-lg-2" do
            # tag
            input [id: "query_form_data_include_tag",
                   name: "query_form_data[include_tag]",
                   type: "checkbox",
                   value: "include_tag"]
            label [class: "ib-details-label", for: "query_form_data_include_tag"] do
              "tag"
            end
          end

        end
      end
    end
  end

  component :global_options do
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"], do: "other options"

      div class: "container" do
        div class: "row" do
          div class: "col-sm-12" do
            # Latest
            input [id: "query_form_data_latest",
                   name: "query_form_data[latest]",
                   type: "checkbox",
                   value: "latest"]
            label [class: "ib-details-label", for: "query_form_data_latest"] do
              "latest only"
            end
          end
        end
      end

    end
  end

  component :query_details do

    div [id: "ib-query-details", class: "ib-details-off"] do
      form [action: "/ibgib/query", method: "post", class: "ib-overflow-y-auto ib-height-100"] do
        input [id: "query_form_data_src_ib_gib", name: "query_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]

        search_what
        search_how
        include_options
        global_options

        div [class: "ib-tooltip download_form_submit_btn_div"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-search ib-green"]
          # span [class: "ib-tooltiptext"], do: gettext("Go Spurs Go!")
          end
        end
      end
    end
  end

end
