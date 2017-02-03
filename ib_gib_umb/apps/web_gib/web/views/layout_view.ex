defmodule WebGib.LayoutView do
  require Logger

  alias IbGib.Helper
  use WebGib.Web, :view
  use WebGib.Constants, :keys
  use WebGib.Constants, :config

  template :app do
    html lang: "en" do
      head [class: "ib-height-100"] do
      # head do
        meta charset: "utf-8"
        meta "http-equiv": "X-UA-Compatible", content: "IE=edge"
        meta name: "viewport", content: "width=device-width, initial-scale=1"
        meta name: "description", content: ""
        meta name: "author", content: ""
        meta name: "ib_identity_token", content: @ib_identity_token
        meta name: "ib_agg_identity_hash", content: @ib_agg_identity_hash

        title "ibGib"
        link rel: "stylesheet", href: static_path(@conn, "/css/app.css")
        link rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png"
        link rel: "icon", type: "image/png", href: "/favicon-32x32.png", sizes: "32x32"
        link rel: "icon", type: "image/png", href: "/favicon-16x16.png", sizes: "16x16"
        link rel: "manifest", href: "/manifest.json"
        link rel: "mask-icon", href: "/safari-pinned-tab.svg", color: "#6c8e2e"
        meta name: "theme-color", content: "#f0fcda"
        meta name: "viewport", content: "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"
      end
      
      body [class: "ib-layout-body ib-height-100"] do
        nav [class: "navbar navbar-default ib-nav"] do
          div [id: "ib-navbar-container", class: "container-fluid"] do
            
            div [class: "navbar-header"] do
              
              # div [id: "ib-navbar-icon-div"] do
              # end
              # a [class: "navbar-brand navbar-left", href: "/"] do
              #   # img [alt: "ibGib Logo", src: "/favicon-32x32.png"]
              # end
              
              # button [type: "button", class: "navbar-toggle collapsed navbar-right", "data-toggle": "collapse", "data-target": "#ib-navbar-collapse-div", "aria-expanded": "false"] do
              #   span [class: "icon-bar"]
              #   span [class: "icon-bar"]
              #   span [class: "icon-bar"]
              # end
              
              a [class: "navbar-brand", href: "/"] do 
                "ibGib"
                # img [alt: "ibGib Logo", src: "/favicon-32x32.png"]
                # "Brand" 
              end
            end

            button [type: "button", class: "btn btn-default navbar-btn"] do
              "Button1"
            end
            button [type: "button", class: "btn btn-default navbar-btn"] do
              "Button2"
            end
            button [type: "button", class: "btn btn-default navbar-btn"] do
              "Button3"
            end
            
          end
        end
        div [class: "container-fluid ib-width-100 ib-height-100"] do
          div [class: "ib-container-section"] do
            header [id: "ib-main-header", class: "ib-flex-centerable"] do
              a [class: "logo", href: "/"]
            end
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

  def render(_template, %{:conn => conn} = assigns) do
    assigns = add_identity_meta(conn, assigns)

    app(assigns)
  end

  defp add_identity_meta(conn, assigns) do
    identity_ib_gibs = conn |> Plug.Conn.get_session(@ib_identity_ib_gibs_key)
    identity_token =
      Phoenix.Token.sign(WebGib.Endpoint,
                         @ib_identity_token_salt,
                         identity_ib_gibs)

    {:ok, aggregate_id_hash} =
      if identity_ib_gibs do
        Helper.get_aggregate_id_hash(identity_ib_gibs)
      else
        # User has just navigated to the site and does not have an identity yet.
        {:ok, nil}
      end

    assigns
    |> Map.put(:ib_identity_token, identity_token)
    |> Map.put(:ib_agg_identity_hash, aggregate_id_hash)
  end
end
