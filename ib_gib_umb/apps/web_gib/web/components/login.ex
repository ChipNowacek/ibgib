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
          "This will be your public session name. It does not have to be unique."
        end
      end

      form [action: "/ibgib", method: "post"] do
        input [name: "_utf8", type: "hidden", value: "✓"]
        input [id: "login_form_data_ib_username", name: "login_form_data[ib_username]", type: "text", value: "ib"]
        # input [id: "fork_form_data_src_ib_gib", name: "fork_form_data[src_ib_gib]", type: "hidden", value: "ib^gib"]
        input [name: "_csrf_token", type: "hidden", value: Phoenix.Controller.get_csrf_token]
        div [class: "ib-tooltip"] do
          button [type: "submit"] do
            span [class: "ib-center-glyph glyphicon glyphicon-flash ib-green"]
          # span [class: "ib-tooltiptext"], do: gettext("Go 8-)")
          end
        end
      end

    end
  end

end
