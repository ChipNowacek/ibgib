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

  component :ib_options do
    # ib options
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"], do: "ib"
      div class: "container" do
        # is/has row
        div class: "row" do
          div class: "col-sm-2" do
            span do
              input [id: "query_form_data_ib_query_type_is",
                     name: "query_form_data[ib_query_type]",
                     type: "radio",
                     value: "is"]
              label "is", for: "query_form_data_ib_query_type_is"
            end
          end
          div class: "col-sm-2" do
            span do
              input [id: "query_form_data_ib_query_type_has",
                     name: "query_form_data[ib_query_type]",
                     type: "radio",
                     value: "has",
                     checked: ""]
              label "has", for: "query_form_data_ib_query_type_has"
            end
          end
        end
        # search_ib text row
        div class: "row" do
          div class: "col-sm-12" do
            input [id: "query_form_data_search_ib",
                   name: "query_form_data[search_ib]",
                   type: "text",
                   maxlength: max_id_length,
                   value: ""]
          end
        end
      end
    end
  end

  component :data_options do
    fieldset [class: "ib-details-fieldset"] do
      legend [class: "ib-details-legend"], do: "data"
      div class: "container" do
        # is/has row
        div class: "row" do
          div class: "col-sm-12" do
            label [class: "ib-details-label", for: "query_form_data_search_data"] do
              "has"
            end
            input [id: "query_form_data_search_data",
                   name: "query_form_data[search_data]",
                   type: "text",
                   pattern: ".{#{min_query_data_text_size},#{max_query_data_text_size}}",
                   title: "Please enter query data text with a maximum of #{max_query_data_text_size} characters.",
                   value: ""]
          end
        end
      end
    end
  end


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
                   value: "include_pic"]
            label [class: "ib-details-label", for: "query_form_data_include_pic"] do
              "pic"
            end

            # comment
            input [id: "query_form_data_include_comment",
                   name: "query_form_data[include_comment]",
                   type: "checkbox",
                   value: "include_comment"]
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
      form [action: "/ibgib/query", method: "post"] do
        input [id: "query_form_data_src_ib_gib", name: "query_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]

        ib_options
        data_options
        include_options
        global_options

        div [class: "ib-tooltip download_form_submit_btn_div"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-search ib-green"]
            span [class: "ib-tooltiptext"], do: gettext("Go Query Go! Go Spurs Go! err...Go Query Go! :-?")
          end
        end
      end
    end

  end

end
