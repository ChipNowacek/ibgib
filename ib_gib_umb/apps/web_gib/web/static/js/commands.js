import * as d3 from 'd3';


export class CommandBase {
  constructor(cmdName, ibScape, d) {
    let t = this;

    t.cmdName = cmdName;
    t.ibScape = ibScape;
    t.d = d;
  }

  exec() {
    // do nothing by default
    // this.ibScape.closeMenu();
    this.ibScape.menu.hide();
  }
}


/**
 * Command that has a details view.
 *
 * Details views are shown when a user executes a command on an ibGib.
 *
 * TIP: Code-fold this page to see a list of all of the available details.
 */
export class DetailsCommandBase extends CommandBase {
  constructor(cmdName, ibScape, d) {
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();
    this.open();
  }

  /**
   * This uses a convention that each details div is named
   * `#ib-${cmdName}-details`. It shows the details div, initializes the
   * specifics to the given cmdName and pops it up. This also takes care of
   * cancelling, which is effected when the user just clicks somewhere else.
   */
  open() {
    let t = this;

    t.ibScapeDetails =
      d3.select("#ib-scape-details")
        .attr("class", "ib-pos-abs ib-info-border");

    t.detailsView =
      d3.select(`#ib-${t.cmdName}-details`)
        .attr("class", "ib-details-on ib-height-100");

    t.reposition();

    if (t.init) { t.init(); }

    t.reposition();
  }

  close() {
    let t = this;

    d3.select("#ib-scape-details")
      .attr("class", "ib-pos-abs ib-details-off");

    if (t.detailsView) {
      t.detailsView
        .attr("class", "ib-details-off");
      delete t.detailsView;
    }
  }

  init() {
    // do nothing be default
  }

  /** Positions the details modal view, e.g. comment text, info details, etc. */
  reposition() {
    let t = this;

    // Position the details based on its size.
    let ibScapeDetailsDiv = t.ibScapeDetails.node();
    let detailsRect = ibScapeDetailsDiv.getBoundingClientRect();

    let marginX = 5;
    let marginY = 55;

    // bah, this whole thing is a hack.

    let posTop = marginY;
    let posLeft = marginX;
    let height = t.ibScape.height - (2 * marginY);
    let width = t.ibScape.width - (2 * marginX);
    ibScapeDetailsDiv.style.position = "absolute";
    ibScapeDetailsDiv.style.top = posTop + "px";
    ibScapeDetailsDiv.style.bottom = posTop + height + "px";
    ibScapeDetailsDiv.style.height = height + "px";
    ibScapeDetailsDiv.style.width = width + "px";
    // ibScapeDetailsDiv.style.marginTop = marginY + "px";
    // ibScapeDetailsDiv.style.marginBottom = marginY + "px";
    // ibScapeDetailsDiv.style.marginLeft = marginX + "px";
    // ibScapeDetailsDiv.style.marginRight = "50px";
    // ibScapeDetailsDiv.style.padding = "20px";
  }
}

export class InfoDetailsCommand extends DetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "info";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#info_form_data_src_ib_gib")
      .attr("value", t.d.ibgib);

    let container = d3.select("#ib-info-details-container");
    container.each(function() {
      while (this.firstChild) {
        this.removeChild(this.firstChild);
      }
    });

    t.ibScape.getIbGibJson(t.d.ibgib, ibGibJson => {

      let text = JSON.stringify(ibGibJson, null, 2);
      // Formats new lines in json.data values. It's still a hack just
      // showing the JSON but it's an improvement.
      // Thanks SO (for the implementation sort of) http://stackoverflow.com/questions/42068/how-do-i-handle-newlines-in-json
      text = text.replace(/\\n/g, "\n").replace(/\\r/g, "").replace(/\\t/g, "\t");
      container
        .classed("ib-height-100", true)
        .append("pre")
          .classed("ib-height-100", true)
          .text(text);

      d3.select(container.node().parentNode)
        .classed("ib-height-100", true);

      t.ibScapeDetails
        .classed("ib-height-100", true);
    });
  }
}

export class HelpDetailsCommand extends DetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "help";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    console.log("initializing help...");
    let text = "Hrmmm...you shouldn't be seeing this! This means that I " +
      "haven't included help for this yet. Let me know please :-O";

    if (t.d.ibgib === "ib^gib") {
      text = `These are ibGib. Some are pictures, comments, links, etc.`;
    } else if (t.d.cat === "ib") {
      text = `This is your current ibGib. Right now, it's the center of your ibverse. Click the information (i) button to get more details about it. Spock hand to fork it, or add comments, pictures, links, and more.`;
    } else if (t.d.cat === "ancestor") {
      text = `This is an "ancestor" ibGib, like a parent or grandparent. Each time you "fork" a new ibGib, the src ibGib becomes its ancestor. For example, if you fork a RecipeGib -> WaffleGib, then the WaffleGib becomes a child of the RecipeGib.`
    } else if (t.d.cat === "past") {
      text = `This is a "past" version of your current ibGib. A past ibGib kinda like previous versions of a text document, whither you can 'undo'. Each time you mut8 an ibGib, either by adding/removing a comment or image, changing a comment, etc., you create a "new" version in time. ibGib retains all histories of all changes of all ibGib!`
    } else if (t.d.cat === "dna") {
      text = `Each ibGib is produced by an internal "dna" code, precisely as living organisms are. Each building block is itself an ibGib that you can navigate to, fork, etc. We can't dynamically build dna yet though (in the future of ibGib!)`;
    } else if (t.d.cat === "identity") {
      text = `This is an identity ibGib. It gives you information about who produced what ibGib. You can add layers of identities to "provide more identification", like showing someone your driver's license, your voter's card, club membership, etc. Each identity's ib should start with either "session" or "email". Session is an anonymous id and should be attached to each and every ibGib. Email ids show the email that was used to "log in" (but you can log in with multiple emails!). All authenticated identities should be "stamped" (the "gib" starts and ends with "ibGib", e.g. "ibGib_LETTERSandNUMBERS_ibGib").`;
    } else if (t.d.cat === "rel8n") {
      text = `This is a '${t.d.name}' rel8n node. All of its children are rel8ed to the current ibGib by this rel8n. One ibGib can have multiple rel8ns to any other ibGib. You can expand / collapse the rel8n to show / hide its children by either double-clicking or clicking and selecting the "view" button. Click help on the children to learn more about that rel8n.`;
    } else if (t.d.cat === "pic") {
      text = `This is a picture that you have uploaded! Viewing it in fullscreen will open the image in a new window or tab, depending on your browser preferences. Navigating to it will take you to the pic's ibGib itself. (We're working on an improved experience with adding comments, pictures, etc.)`;
    } else if (t.d.cat === "comment") {
      let ibGibJson = this.ibGibCache.get(t.d.ibgib);
      let commentText = ibHelper.getDataText(ibGibJson);
      text = `This is a comment. It contains text...umm...you can comment on just about anything. (We're working on an improved experience with adding comments, pictures, etc.) This particular comment's text is: "${commentText}"`;
    } else if (t.d.cat === "link") {
      let ibGibJson = this.ibGibCache.get(t.d.ibgib);
      let linkText = ibHelper.getDataText(ibGibJson);
      text = `This is a hyperlink to somewhere outside of ibGib. If you want to navigate to the external link, then choose the open external link command. If you want to goto the link's ibGib, then click the goto navigation. (We're working on an improved experience with adding comments, pictures, etc.) \n\nLink: "${linkText}"`;
    } else {
      text = `This ibGib is rel8d to the current ibGib via ${t.d.cat}. Click the information button to get more details about it. You can also navigate to it, expand / collapse any children, fork it, add comments, pictures, links, and more.`;
    }

    $("#ib-help-details-text").text(text);
  }
}
