defmodule WebGib.PageView do
  use WebGib.Web, :view

  # component :simple_list do
  #   items = for c <- @__content__, do: li c
  #   ul items
  # end

  template :index do
    div do
      div [class: "diy-slideshow"] do
        figure [class: "show"] do
          span do
            img [class: "diy-slideshow-image", src: "images/ibgib_yellow.png"]
          end
          figcaption do
            "For Whoever lives by the Truth comes into the Light, so that it may be seen plainly that what They have done, has been done in the sight of God."
          end
        end

        figure [class: "show"] do
          img [class: "diy-slideshow-image", src: "images/ibgib_blue.png"]
          figcaption do
            "In the beginning was the Word, and the Word was with God, and the Word was God."
          end
        end

        figure [class: "show"] do
          img [class: "diy-slideshow-image", src: "images/ibgib.png"]
          figcaption do
            "For We are God's Handiwork, created in Christ Jesus to do Good Works, which God prepared in advance for Us to do."
          end
        end

        span [class: "prev"] do
          "<"
        end
        span [class: "next"] do
          ">"
        end
      end

      # div [class: "jumbotron ib-green-background"] do
        # h2 gettext "Live In The Light"
        # div do
        #   p [class: "ib-passage"] do
        #     "In the beginning was the Word, and the Word was with God, and the Word was God. (John 1:1)"
        #     # span do: a "ibGib.", href: ib_gib_path(@conn, :index)
        #   end
        # end
      # end

      div [class: "ib-litl-data-notice"] do
        h2 "ibGib Vision and Privacy Caution"
        h3 "Please (Actually!) Read"

        p [class: "ib-bold"] do
          "***** If privacy and security are primary concerns for you, then we ask that you please DO NOT use ibGib in any way, shape, or form. It's cool! We totally understand! No Big! *****"
        end

        p [class: "ib-italic"] do
          "The ibGib app on this site uses cookies and tracks information, almost all of which is and/or will be publicly available. This includes your IP, email address(es) (if you log in), and all generated content."
        end

        h3 "Live In The Light Data"
        p do
          "Just as our source code to run this site is Open-Source Software, all of our data is LITL Data: Live In The Light Data. Data is out there, and it's being tracked. We are bringing this to the foreground so that we all have the same access to the same data. Who watches the Watchers? We *ALL* do. We are *ALL* Watchers. We are Children of the Light."
        end
        p do
          "As such, we want to Live In The Light. We do NOT protect ourselves from the shadows with more shadows. If the shadows attack us from the shadows, then we expose them to the Light with the Swords of Our Mouths. In so doing, we protect ourselves with Light and Truth. IbGib is NOT that Truth, but it is built on principles of walking the Way to the Truth. But choosing this path is a hard choice and it carries with it consequences such as the following:"
        end
        ul do
          li [gettext("Most data is or will be publicly available and shared.")]
          li [gettext(
            "Because most data is shared, there isn't the usual 'delete' functionality: 'delete post', 'delete pic', 'delete note', etc.  Content can be flagged as inappropriate, but we retain full rights over what content to \"truly\" remove from our data stores.")]
          li [gettext("There is NO delete functionality! (Notice we've said it twice so it must be important!! :-O ) ")]
          li [gettext("All content is available for sharing, and it will be licensed under the MIT license (just as our source code is). Please do not post copyrighted material if you do not have the rights, or if you do not want to enable this open licensing. If you are a copyright owner and you wish to have material removed, then flag the material as inappropriate and provide your reason. We will endeavor to make any correpondence with us via email public.")]
          li [gettext("LITL Data is still very experimental. For example, since we are choosing to avoid deletions, we are working on a mechanism to allow dynamic choice over what content to present to users, as well as incorporating separating the Left Hand from what the Right Hand is doing.")]
          li [gettext "We shall do our best to maintain the _Integrity_ of our data, but as in all walks of life there will be stumbling blocks."]
        end

        p do
          "May the Light of the World Bless You."
        end

        p [class: "ib-ibgib-sig"] do
          "---William Raiford"
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
