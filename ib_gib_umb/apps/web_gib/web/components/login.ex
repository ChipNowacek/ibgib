defmodule WebGib.Web.Components.Login do
  @moduledoc """
  This component has a "login" button.
  """

  use Marker
  import WebGib.Gettext

  component :login do
    div do
      div do
        p do
          span [class: "ib-bold"], do: gettext("Instructions:  ")
          "Type in how you want to be identified here. It does not need to be unique. You can change this later, but remember it will be public."
        end
      end

      form [action: "/ibgib/login", method: "post"] do
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [id: "fork_form_data_dest_ib", name: "fork_form_data[dest_ib]", type: "text", value: "ib"]
        input [id: "fork_form_data_src_ib_gib", name: "fork_form_data[src_ib_gib]", type: "hidden", value: "ib^gib"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-flash ib-green"]
            span [class: "ib-tooltiptext"], do: "Fork it yo!"
          end
        end
      end

    end
  end

end
