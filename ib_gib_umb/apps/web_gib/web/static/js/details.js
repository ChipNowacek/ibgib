import * as d3 from 'd3';

/**
 * Details views are shown when a user executes a command on an ibGib.
 *
 * TIP: Code-fold this page to see a list of all of the available details.
 */
export class BaseDetails {
  constructor(cmdName, ibScape, d) {
    let t = this;

    t.cmdName = cmdName;
    t.ibScape = ibScape;
    t.d = d;
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
        .attr("class", "ib-details-on");

    t.reposition();

    if (t.init) { t.init(); }

    t.reposition();
  }

  close() {
    let t = this;

    d3.select("#ib-scape-details")
      .attr("class", "ib-pos-abs ib-details-off");

    t.detailsView
      .attr("class", "ib-details-off");
    delete t.detailsView;
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

    let margin = 55;
    ibScapeDetailsDiv.style.position = "absolute";
    ibScapeDetailsDiv.style.margin = margin + "px";
    ibScapeDetailsDiv.style.top = "0px";
    ibScapeDetailsDiv.style.left = "0px";
    ibScapeDetailsDiv.style.height = (t.ibScape.height - (2 * margin)) + "px";
    ibScapeDetailsDiv.style.width = (t.ibScape.width - (2 * margin)) + "px";
    t.ibScapeDetails.attr("z-index", 1000000);

  }
}

export class InfoDetails extends BaseDetails {
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
        .append("pre")
        .text(text);
    });

  }
}
