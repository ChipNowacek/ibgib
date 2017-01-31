defmodule WebGib.PageView do
  use WebGib.Web, :view

  require WebGib.Web.Components.Login

  # component :simple_list do
  #   items = for c <- @__content__, do: li c
  #   ul items
  # end

  template :index do
    div do
      div [class: "diy-slideshow"] do
        figure [class: "show"] do
          span do
            img [class: "diy-slideshow-image", src: "images/coffee/coffee1.png"]
          end
          figcaption do
            "Coffee"
          end
        end

        figure [class: "show"] do
          span do
            img [class: "diy-slideshow-image", src: "images/coffee/coffee2.png"]
          end
          figcaption do
            "Coffee"
          end
        end
        
        figure [class: "show"] do
          span do
            img [class: "diy-slideshow-image", src: "images/coffee/coffee3.png"]
          end
          figcaption do
            "Coffee"
          end
        end
        
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
          "** If privacy is a primary concern for you, then we ask that you please DO NOT use ibGib in any way, shape, or form. It's cool! We totally understand! No Big! **"
        end

        p [class: "ib-italic"] do
          "The ibGib app on this site uses cookies and tracks information, almost all of which is and/or will be publicly available. This includes (but not exclusively):"
          ul do
            li "Any email address(es) by which you identify yourself (required to upload pics)"
            li "All comments, links, or pics that you generate."
            li "All queries and query results generated within ibGib."
            li "All intermediate generated content, including ibGib DNA, rel8ns, and data."
          end  
        end
        
        p do
          "This is largely because all data created in ibGib is stored within ibGib itself. For example, when you do a query (search) within the ibGib app, it creates a query ibGib and then persists just like every other ibGib. It also stores the ibGib DNA used to create the query, relating everything generated to the current identity. This then creates an query result ibGib that also has DNA, identities, and other related ibGib."
        end
        
        p [class: "ib-bold"] do
          "** Everything in ibGib is ibGib itself, and all ibGib are fundamentally interconnected. It is all open, all visible, all in the Light: The Book is Open. **"
        end 
        
        h3 "LITL Data"
        p [
          "Just as our ",
          a([href: "https://github.com/ibgib/ibgib", target: "_blank"], "source code"),
          " to run this site is ",
          a([href: "https://en.wikipedia.org/wiki/Open-source_software", target: "_blank"], "Open-Source Software"),
          ", all of our Big Data is a variety of ",
          a([href: "https://en.wikipedia.org/wiki/Open_data", target: "_blank"], "Open Data"),
          " that we call LITL Data: Live In The Light Data. Big Data is already out there, and it's being tracked and recorded by just about any web entity nowadays. ibGib is bringing this Big Data into the Light so that we all have the same access to the same data. Who watches the Watchers? ",
          span([class: "ib-bold"], "We all do.")
        ]
        p do
          "And so users of ibGib are children of the Light. As such, we do NOT protect ourselves from the shadows by investing in and encouraging more shadows. If the shadows attack us from the shadows, then we expose them to the Light. In so doing, we protect ourselves with Light and Truth. IbGib is not that Truth, but it is built on principles of the Way to the Truth. But choosing this path is a hard choice and it carries with it real consequences, some examples of which include the following:"
        end
        ul do
          li [
            gettext("Since almost all data is public, there isn't the usual 'delete' functionality: 'delete post', 'delete pic', 'delete note', etc.  Content will be able to be flagged as inappropriate ("),
            a([href: "https://github.com/ibgib/ibgib/issues/17", target: "_blank"], gettext("under construction")),
            gettext("), but we retain full rights over what content to \"truly\" remove from our data stores. This helps us ensure data integrity and data persistence in the face of adversity, such as an adversary gaining access to your identification.")
          ]
          li [gettext("There is NO delete functionality! (Notice we've said it twice so it must be important.) ibGib is built upon data that only grows which sometimes is called monotonically-increasing or append-only data. This is intrinsic to the nature of ibGib.")]
          li [
            gettext("All content is available for sharing, and it will be licensed under the "),
            a([href: "https://en.wikipedia.org/wiki/MIT_License", target: "_blank"], "MIT license"),
            gettext(" (just as our "),
            a([href: "https://github.com/ibgib/ibgib/blob/master/LICENSE", target: "_blank"], gettext("source code license is")),
            gettext("). Please do not post copyrighted material if you do not have the rights, or if you do not want to enable this open licensing. If you are a copyright owner and you wish to have material removed, then flag the material as inappropriate and provide your reason. Currently the flagging is under construction, so for now "),
            a([href: "https://github.com/ibgib/ibgib/issues", target: "_blank"], "please create an issue on our GitHub repo"),
            gettext(". Note that we will endeavor to make public any correpondence with us via email.")
          ]
          li [gettext("LITL Data is still very experimental. For example, since we are choosing to avoid deletions, we are working on a mechanism to allow dynamic choice over what content to present to users.")]
          li [gettext "We shall do our best to maintain the _Integrity_ of our data, but as in all walks of life there will be stumbling blocks. We do not and shall not attempt to make any guarantees as to the lifetime of the data stored in ibGib."]
        end
        
        br
        
        p [class: "ib-bold"] do
          "The work of God is this: To believe in the One He has sent."
        end

        p [class: "ib-ibgib-sig"] do
          "---William Raiford"
        end
        p [class: "ib-ibgib-sig"] do
          "---ibGib"
        end
      end

      div [class: "ib-info-border"] do
        WebGib.Web.Components.Login.login([conn: @conn])
      end
    end
  end

  def render("index.html", assigns), do: index(assigns)
end
