defmodule WebGib.PageView do
  use WebGib.Web, :view

  component :simple_list do
    items = for c <- @__content__, do: li c
    ul items
  end

  component :login do
    form [action: "/login"] do
      input [name: "_csrf_token", type: "hidden", value: @csrf_token]
      input [name: "_utf8" type: "hidden" value: "✓"]
      input [id: "fork_form_data_dest_ib", name: "fork_form_data[dest_ib]", type: "text"]
      input [id: "fork_form_data_src_ib_gib", name: "fork_form_data[src_ib_gib]", type: "hidden", value: "ib^gib"]
      div [class: "ib-tooltip"] do
        button [type: "submit"] do
          span [class: "ib-center-glyph glyphicon glyphicon-flash ib-green"]
          span [class: "ib-tooltiptext"], do: "Fork it yo!"
        end
      end
    end
  end

  template :index do
    [
      div class: "jumbotron ib-green-background" do
        h2 gettext("Welcome to %{name} 8~/", name: "ibGib")
        div do
          p [
            "ib. Gib. ",
            span do: a "ibGib.", href: ib_gib_path(@conn, :index)
          ], class: "lead"
        end
      end

      div class: "ib-info-border" do
        login [csrf_token: @_csrf_token]
      end
    ]
  end

  def render("index.html", assigns), do: index(assigns)
end
