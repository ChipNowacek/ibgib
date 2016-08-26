defmodule WebGib.PageView do
  use WebGib.Web, :view

  import WebGib.Web.Components.Login

  component :simple_list do
    items = for c <- @__content__, do: li c
    ul items
  end

  template :index do
    div do
      div [class: "jumbotron ib-green-background"] do
        h2 gettext "Live In The Light"
        div do
          p [class: "ib-passage"] do
            "In the beginning was the Word, and the Word was with God, and the Word was God. (John 1:1)"
            # span do: a "ibGib.", href: ib_gib_path(@conn, :index)
          end
        end
      end

      div [class: "ib-litl-data-notice"] do
        h3 "ibGib Vision: Please (Actually) Read!"

        p [class: "ib-bold"] do
          "This site uses cookies and tracks information, almost all of which is and/or will be publicly available. ***** If privacy and security are primary concerns for you, then we ask that you please do not use our site. *****"
        end

        p do
          "Just as our source code to run the site is Open-Source Software, all of our data is LITL Data: Live In The Light Data. We want to Live In The Light as children of the light, and not be afraid of things like data breaches, just as we should not worry when we step out of our front door if someone is watching us from the shadows. But we do NOT protect ourselves from the shadows with more shadows. We protect ourselves with Light. But choosing this path is a hard choice and it carries with it consequences such as the following:"
        end
        ul do
          li [gettext("Most data is or will be publicly available and shared.")]
          li [gettext(
            "Because most data is shared, there isn't the usual 'delete' functionality: 'delete post', 'delete pic', 'delete note', etc.  Content can be flagged as inappropriate, but we retain full rights over what content to truly remove.")]
          li [gettext("There is NO delete functionality! (Notice we've said it twice so it must be important!!) ")]
          li [gettext("All content is available for sharing, and it will be licensed under the MIT license (just as our source code is). Please do not post copyrighted material if you do not have the rights, or if you do not want to enable this open licensing. If you are a copyright owner and you wish to have material removed, then flag the material as inappropriate and provide your reason. We will endeavor to make any correpondence with us via email public.")]
          li [gettext("LITL Data is still very experimental. For example, since we are choosing to avoid deletions, we are working on a mechanism to allow dynamic choice over what content to present to users.")]
          li [gettext "We shall do our best to maintain the _Integrity_ of our data, but as in all walks of life there will be stumbling blocks. "]
        end

        p do
          "Thank You, and May the Good Lord bless you."
        end

        p [class: "ib-ibgib-sig"] do
          "---ⓘⓑⓖⓘⓑ"
        end
      end

      div [class: "ib-info-border"] do
        WebGib.Web.Components.Login.login([conn: @conn])
      end
    end
  end

  def render("index.html", assigns), do: index(assigns)
end
