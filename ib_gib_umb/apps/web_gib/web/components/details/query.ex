defmodule WebGib.Web.Components.Details.Query do
  @moduledoc """
  This contains the query details view, shown when the user clicks the query
  menu command.
  """

  use Marker

  use WebGib.MarkerElements
  import WebGib.Gettext


  component :query_details do

    div [id: "ib-query-details", class: "ib-details-off"] do
      form [action: "/ibgib/query", method: "post"] do
        input [id: "query_form_data_src_ib_gib", name: "query_form_data[src_ib_gib]",type: "hidden", value: ""]
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div do
          # ib options
          fieldset [class: "ib-details-fieldset"] do
            legend [class: "ib-details-legend"], do: "ib"
            div class: "container" do
              # is/has row
              div class: "row" do
                div class: "col-sm-8" do
                  span do
                    input [id: "query_form_data_ib_query_type_is",
                           name: "query_form_data[ib_query_type]",
                           type: "radio",
                           value: "is"]
                    label "is", for: "query_form_data_ib_query_type_is"
                    # span " is "
                  end
                end
                div class: "col-sm-8" do
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
              # ib search text row
              div class: "row" do
                input [id: "query_form_data_search_ib",
                       name: "query_form_data[search_ib]",
                       type: "text",
                       value: ""]
              end
            end
          end
        end

        fieldset [class: "ib-details-fieldset"] do
          legend [class: "ib-details-legend"], do: "options"
          input [id: "query_form_data_latest",
                 name: "query_form_data[latest]",
                 type: "checkbox",
                 value: "latest",
                 checked: ""]
          label "Latest only", for: "query_form_data_latest"
        end

        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-search ib-green"]
            span [class: "ib-tooltiptext"], do: gettext("Go Query Go! Go Spurs Go! err...Go Query Go! :-?")
          end
        end
      end
    end

  end

end
