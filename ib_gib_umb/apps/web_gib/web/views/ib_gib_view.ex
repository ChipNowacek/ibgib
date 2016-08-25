defmodule WebGib.IbGibView do
  use WebGib.Web, :view

  # import WebGib.Web.Components.Login

  template :index do
    div do
      p do
        "Yo this is the ibgib index template."
      end
    end
  end

  def render("index.html", assigns), do: index(assigns)
end
