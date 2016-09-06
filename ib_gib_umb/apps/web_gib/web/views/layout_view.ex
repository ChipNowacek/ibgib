defmodule WebGib.LayoutView do
  use WebGib.Web, :view

  template :app do
    html lang: "en" do
      head [class: "ib-height-100"] do
      # head do
        meta charset: "utf-8"
        meta "http-equiv": "X-UA-Compatible", content: "IE=edge"
        meta name: "viewport", content: "width=device-width, initial-scale=1"
        meta name: "description", content: ""
        meta name: "author", content: ""

        title "ibGib"
        link rel: "stylesheet", href: static_path(@conn, "/css/app.css")
      end
      body [class: "ib-height-100"] do
        div class: "container-fluid ib-width-100 ib-height-100" do
          header class: "header" do
            a [href: "/"], do: span class: "logo"
          end

          p get_flash(@conn, :info), class: "alert alert-info", role: "alert"
          p get_flash(@conn, :error), class: "alert alert-danger", role: "alert"

          main [role: "main"] do
            render @view_module, @view_template, assigns
          end

        end
        script src: static_path(@conn, "/js/app.js")
      end
    end
  end

  def render(_template, assigns), do: app(assigns)
end
