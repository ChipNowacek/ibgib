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
  # Need to expose via function, because in the Marker component macro, the `@`
  # attempts to pull from assigns (not a module attribute).
  defp max_id_length, do: @max_id_length
  defp min_query_data_text_size, do: @min_query_data_text_size
  defp max_query_data_text_size, do: @max_query_data_text_size

  # What to search for.
  # e.g. ib, keywords, tags, data segment (like comment text or date), etc.
  component :search_what do
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"], do: "&#1F50D; What"
      div class: "container" do
        
        # text row
        div class: "row" do
          div class: "col-sm-12" do
            input [id: "query_form_data_search_text",
                   name: "query_form_data[search_text]",
                   type: "text",
                   maxlength: max_query_data_text_size(),
                   value: ""]
            span [class: "ib-tooltip"] do
              span [class: "ib-center-glyph glyphicon glyphicon-question-sign ib-green"]
              span [class: "ib-tooltiptext-smallfont"], do: gettext("Type in what you want to search for. You can type in partial/whole text for an ib, comment text, a date like '2017' or '%2017%02%14%'.")
            end
          end
        end
        
      end
    end
  end
  
  # How to query for those terms
  # e.g. ib is/has, data, tag is/has
  component :search_how do
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"], do: "&#1F50D; What"
      div class: "container" do
        div class: "row" do
          div class: "col-sm-12" do
            
            # ib is
            input [id: "query_form_data_ib_is",
                   name: "query_form_data[ib_is]",
                   type: "checkbox",
                   value: "ib_is"]
            label [class: "ib-details-label", for: "query_form_data_ib_is"] do
              "ib is"
            end
            # ib has
            input [id: "query_form_data_ib_has",
                   name: "query_form_data[ib_has]",
                   type: "checkbox",
                   value: "ib_has"]
            label [class: "ib-details-label", for: "query_form_data_ib_has"] do
              "ib has"
            end

            # data has
            input [id: "query_form_data_data_has",
                   name: "query_form_data[data_has]",
                   type: "checkbox",
                   value: "data_has"]
            label [class: "ib-details-label", for: "query_form_data_data_has"] do
              "data has"
            end

            # tag is
            input [id: "query_form_data_tag_is",
                   name: "query_form_data[tag_is]",
                   type: "checkbox",
                   value: "tag_is"]
            label [class: "ib-details-label", for: "query_form_data_ib_is"] do
              "tag is"
            end
            # tag has
            input [id: "query_form_data_tag_has",
                   name: "query_form_data[tag_has]",
                   type: "checkbox",
                   value: "tag_has"]
            label [class: "ib-details-label", for: "query_form_data_tag_has"] do
              "tag has"
            end

          end
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
          div class: "col-sm-12" do
            # pic
            input [id: "query_form_data_include_pic",
                   name: "query_form_data[include_pic]",
                   type: "checkbox",
                   value: "include_pic",
                   checked: ""]
            label [class: "ib-details-label", for: "query_form_data_include_pic"] do
              "pic"
            end

            # comment
            input [id: "query_form_data_include_comment",
                   name: "query_form_data[include_comment]",
                   type: "checkbox",
                   value: "include_comment",
                   checked: ""]
            label [class: "ib-details-label", for: "query_form_data_include_comment"] do
              "comment"
            end

            # dna
            input [id: "query_form_data_include_dna",
                   name: "query_form_data[include_dna]",
                   type: "checkbox",
                   value: "include_dna"]
            label [class: "ib-details-label", for: "query_form_data_include_dna"] do
              "dna"
            end

            # query
            input [id: "query_form_data_include_query",
                   name: "query_form_data[include_query]",
                   type: "checkbox",
                   value: "include_query"]
            label [class: "ib-details-label", for: "query_form_data_include_query"] do
              "query"
            end
            
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
                   value: "latest",
                   checked: ""]
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


# component :ib_options do
#   # ib options
#   fieldset [class: "ib-details-fieldset"] do
#     legend [class: "ib-details-legend"], do: "ib"
#     div class: "container" do
#       # is/has row
#       div class: "row" do
#         div class: "col-sm-2" do
#           span do
#             input [id: "query_form_data_ib_query_type_is",
#                    name: "query_form_data[ib_query_type]",
#                    type: "radio",
#                    value: "is"]
#             label "is", for: "query_form_data_ib_query_type_is"
#           end
#         end
#         div class: "col-sm-2" do
#           span do
#             input [id: "query_form_data_ib_query_type_has",
#                    name: "query_form_data[ib_query_type]",
#                    type: "radio",
#                    value: "has",
#                    checked: ""]
#             label "has", for: "query_form_data_ib_query_type_has"
#           end
#         end
#       end
#       # search_ib text row
#       div class: "row" do
#         div class: "col-sm-12" do
#           input [id: "query_form_data_search_ib",
#                  name: "query_form_data[search_ib]",
#                  type: "text",
#                  maxlength: max_id_length,
#                  value: ""]
#         end
#       end
#     end
#   end
# end
# 
# component :data_options do
#   fieldset [class: "ib-details-fieldset"] do
#     legend [class: "ib-details-legend"], do: "data"
#     div class: "container" do
#       # is/has row
#       div class: "row" do
#         div class: "col-sm-12" do
#           label [class: "ib-details-label", for: "query_form_data_search_data"] do
#             "has"
#           end
#           input [id: "query_form_data_search_data",
#                  name: "query_form_data[search_data]",
#                  type: "text",
#                  pattern: ".{#{min_query_data_text_size},#{max_query_data_text_size}}",
#                  title: "Please enter query data text with a maximum of #{max_query_data_text_size} characters.",
#                  value: ""]
#         end
#       end
#     end
#   end
# end
