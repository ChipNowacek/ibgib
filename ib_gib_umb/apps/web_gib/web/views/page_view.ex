defmodule WebGib.PageView do
  use WebGib.Web, :view

  component :simple_list do
    items = for c <- @__content__, do: li c
    ul items
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
    ]
  end

  def render("index.html", assigns), do: index(assigns)
end
