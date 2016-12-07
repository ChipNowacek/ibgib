import * as d3 from 'd3';
import * as ibHelper from '../ibgib-helper';


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
    if (this.ibScape.menu) { this.ibScape.menu.hide(); }
  }
}

/**
 * Command that has a details view.
 *
 * By convention, the details view is located in `web/components/details/cmdname.ex` (capitalization may differ). The details
 * view must have a div with `ib-${cmdName}-details` with exact capitalization
 * and spelling. So for the fork command, there is a
 * `web/components/details/fork.ex` file with a div with id of
 * `ib-fork-details`.
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

    t.repositionView();

    if (t.init) { t.init(); }

    t.repositionView();
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
  repositionView() {
    let t = this;

    // Position the details based on its size.
    let ibScapeDetailsDiv = t.ibScapeDetails.node();
    let detailsRect = ibScapeDetailsDiv.getBoundingClientRect();

    let marginX = 5;
    let marginY = 15;

    // bah, this whole thing is a hack.

    let posTop = marginY;
    let posLeft = marginX;
    let height = t.ibScape.height - (2 * marginY);
    let width = t.ibScape.width - (2 * marginX) - 15;
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

    // position close button
    d3.select(ibScapeDetailsDiv)
      .selectAll("[name=ib-scape-details-close-btn]")
      .style("top", (posTop + 10) + "px")
      .style("left", (posLeft + width - 50) + "px");
  }
}

/**
 * For commands that have a details page that is a <form>.
 */
export class FormDetailsCommandBase extends DetailsCommandBase {
  constructor(cmdName, ibScape, d) {
    super(cmdName, ibScape, d);

    let t = this;

    t.initForm();
  }

  /** By default, this looks for id ib-cmdName-details-form. */
  getFormId() { return `ib-${this.cmdName}-details-form`; }

  /**
   * By default, this sets this command's details form to NOT submit when
   * submit input is pressed. Rather, it executes the `submitFunc` function.
   * Sub-classes should override `submitFunc`.
   *
   * If for some reason we want to keep the original submit functionality,
   * then override this function to do nothing. (ATOW 2016/12/02)
   */
  initForm() {
    let t = this;

    t.$form = $("#" + t.getFormId());
    t.$form.submit((event) => {
      // Does not submit via POST
      event.preventDefault();

      // Perform our own submit function
      t.submitFunc();
    });
  }

  /**
   * Additional cleanup: Unbinds from this command's details form.
   */
  close () {
    this.$form.unbind('submit');

    super.close();
  }

  /**
   * Default implementation is for a command that will produce a single virtual
   * node that will be busy while the message is sent to the server via the
   * channel.
   */
  submitFunc() {
    let t = this;
    console.log(`${t.cmdName} cmd submitFunc`);

    let formId = t.getFormId();
    let form = document.getElementById(t.getFormId());
    if (form.checkValidity()) {
      console.log("form is valid");
      t.addVirtualNode();
      t.ibScape.setBusy(t.virtualNode);

      let msg = t.getMessage();
      t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
        t.ibScape.clearBusy(t.virtualNode);
        if (t.handleSubmitResponse) {
          t.handleSubmitResponse(successMsg);
        }
      }, (errorMsg) => {
        console.error(`Command errored. Msg: ${JSON.stringify(errorMsg)}`);
        t.ibScape.clearBusy(t.virtualNode);
        t.virtualNode.type = "error";
        t.virtualNode.errorMsg = JSON.stringify(errorMsg);
        t.ibScape.zapVirtualNode(t.virtualNode);
      });
    } else {
      console.log("form is invalid");
    }

    t.close();
  }

  addVirtualNode() {
    let t = this;
    t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ t.d, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "\uf10c", /*startPos*/ {x: t.d.x, y: t.d.y});
  }

  getMessage() {
    let t = this;

    return {
      data: t.getMessageData(),
      metadata: t.getMessageMetadata()
    };
  }

  getMessageData() {
    throw Error("getMessageData must be implemented.");
  }

  getMessageMetadata() {
    let t = this;

    return {
      name: t.cmdName,
      type: "cmd",
      local_time: new Date()
    };
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
      .attr("value", t.d.ibGib);

    let container = d3.select("#ib-info-details-container");
    container.each(function() {
      while (this.firstChild) {
        this.removeChild(this.firstChild);
      }
    });

    t.ibScape.getIbGibJson(t.d.ibGib, ibGibJson => {

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

    if (t.d.virtualId) {
      text = `This is a virtual ibGib. You can zap this ibGib by clicking on it.`;
      switch (t.d.type) {
        case "cmd":
          text += ` In this case, zapping will execute its command.`;
          break;
        case "ibGib":
          text += ` In this case, zapping will load the full ibGib.`;
          break;
        case "rel8n":
          text += ` In this case, zapping will show all of the ${t.d.name} ibGib.`
        default:
          // do nothing
      }
    } else if (t.d.ibGib === "ib^gib") {
      text = `This is the root ibGib.`;
    } else {
      let ib = t.d.ibGibJson.ib;
      switch (ib) {
        case "query_result":
          text = `This is a query result. It contains results from a search query.`
          break;

        case "identity":
          text = `This is an identity ibGib. It gives you information about who produced what ibGib. You can add layers of identities to "provide more identification", like showing someone your driver's license, your voter's card, club membership, etc. Each identity's ib should start with either "session" or "email". Session is an anonymous id and should be attached to each and every ibGib. Email ids show the  email that was used to "log in" (but you can log in with multiple emails!). All authenticated identities should be "stamped" (the "gib" starts and ends with "ibGib", e.g. "ibGib_LETTERSandNUMBERS_ibGib").`;
          break;

        case "link":
          let linkText = ibHelper.getDataText(t.d.ibGibJson);
          text = `This is a hyperlink to somewhere outside of ibGib. You can open it in a new tab by clicking the external link button. If you want to goto the link's ibGib, then click the goto navigation. (We're working on an improved experience with adding comments, pictures, etc.) \n\nLink: "${linkText}"`;
          break;

        default:
          text = `These are ibGib. Some are pictures, others are comments or links. Just try clicking, long-clicking, and double-clicking stuff. Don't worry, you won't break anything! ʘ‿ʘ`;

      }
    }

    switch (t.d.render) {
      case "image":
        text += ` This ibGib should be shown as an image. You can download the full image, view it fullscreen, and more.`
        break;
      case "text":
        text += ` This ibGib contains text.`
      default:
        // do nothing
    }

    $("#ib-help-details-text").text(text);
  }
}

export class QueryDetailsCommand extends DetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "query";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#query_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    $("#query_form_data_search_ib").focus();
  }

  exec() {
    super.exec();
  }
}

export class ForkDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "fork";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#fork_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    $("#fork_form_data_dest_ib").val(t.d.ibGibJson.ib).focus();
  }

  addVirtualNode() {
    let t = this;
    t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ null, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "\uf10c", /*startPos*/ {x: t.d.x, y: t.d.y});
  }

  getMessageData() {
    let t = this;

    return {
      virtual_id: t.virtualNode.virtualId,
      src_ib_gib: t.d.ibGib,
      dest_ib: $("#fork_form_data_dest_ib").val()
    };
  }

  handleSubmitResponse(msg) {
    let t = this;

    if (msg && msg.data && msg.data.forked_ib_gib) {
      let forkedIbGib = msg.data.forked_ib_gib;
      t.virtualNode.ibGib = forkedIbGib;
      t.virtualNode.isSource = true;
      t.ibScape.zapVirtualNode(t.virtualNode);
    } else {
      console.error("ForkDetailsCommand: Unknown msg response from channel.");
    }
  }
}

export class CommentDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "comment";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#comment_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    $("#comment_form_data_text").val("").focus();
  }

  getMessageData() {
    let t = this;


    return {
      virtual_id: t.virtualNode.virtualId,
      src_ib_gib: t.d.type === "rel8n" ? t.d.rel8nSrc.ibGib : t.d.ibGib,
      comment_text: $("#comment_form_data_text").val()
    };
  }

  handleSubmitResponse(msg) {
    let t = this;
    console.warn(`yoooooooooooo ${typeof(t)}`);

    if (msg && msg.data && msg.data.comment_ib_gib) {
      let commentIbGib = msg.data.comment_ib_gib;
      t.virtualNode.ibGib = commentIbGib;
      t.ibScape.zapVirtualNode(t.virtualNode);
    } else {
      console.error(`${typeof(t)}: Unknown msg response from channel.`);
    }
  }
}

export class GotoCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "goto";
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();

    let t = this;

    t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.d.ibGib, /*srcNode*/ null, /*shape*/ t.d.shape, /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "\uf10c", /*startPos*/ {x: t.d.x, y: t.d.y});
  }
}
