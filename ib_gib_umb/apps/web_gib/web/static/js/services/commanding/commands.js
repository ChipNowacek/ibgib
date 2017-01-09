import * as d3 from 'd3';
var md = require('markdown-it')();
var emoji = require('markdown-it-emoji');
md.use(emoji);

import * as ibHelper from '../ibgib-helper';
import { d3MenuCommands, d3RootUnicodeChar } from '../../d3params';
import { huhText_IbGib } from './huh-texts/ibgib';
import { huhText_Context } from './huh-texts/context';

// Most (_but not all_) commands are related to menu commands (in `d3params.js`)

// TIP: Code-fold this page to see a list of all of the available commands.

/**
 * Base class for all commands.
 * Has a name, relates to an ibScape and datum, and can exec.
 */
export class CommandBase {
  constructor(cmdName, ibScape, d) {
    let t = this;

    t.cmdName = cmdName;
    t.ibScape = ibScape;
    t.d = d;
  }

  exec() {
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
 */
export class DetailsCommandBase extends CommandBase {
  constructor(cmdName, ibScape, d) {
    super(cmdName, ibScape, d);
  }

  exec() {
    let t = this;
    super.exec();
    t.open();
    t.keyupEventName = `keyup.${t.cmdName}`;
    $(document).on(t.keyupEventName, e => {
      // let keyCode = e.keyCode || e.which;
      if (e.keyCode == 27) { // escape key maps to keycode `27`
        t.close();
      }
    });
  }

  getDetailsViewId() {
    return `ib-${this.cmdName}-details`;
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
      d3.select("#" + t.getDetailsViewId())
        .attr("class", "ib-details-on ib-height-100");

    t.repositionView();

    if (t.init) { t.init(); }

    t.repositionView();
  }

  close() {
    let t = this;

    $(document).unbind(t.keyupEventName);

    d3.select("#ib-scape-details")
      .attr("class", "ib-pos-abs ib-details-off");

    if (t.detailsView) {
      t.detailsView
        .attr("class", "ib-details-off");
      delete t.detailsView;
    }

    if (t.ibScape.currentCmd) { delete t.ibScape.currentCmd; }
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

      t.sanitizeFormFields();

      // Perform our own submit function
      t.submitFunc();
    });
  }

  /**
   * Additional cleanup: Unbinds from this command's details form.
   */
  close () {
    this.$form.unbind('submit');
    this.$form[0].reset();
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

    let form = document.getElementById(t.getFormId());
    if (form.checkValidity()) {
      console.log("form is valid");
      t.addVirtualNode(() => {
        t.ibScape.setBusy(t.virtualNode);

        let msg = t.getMessage();
        // can close only after we build the msg
        t.close();
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
          t.ibScape.zap(t.virtualNode, /*callback*/ null);
        });
      });
    } else {
      console.error("form is invalid (shouldn't get here ?)");
    }
  }

  /** Trim whitespace, do whatever else. By default does nothing. */
  sanitizeFormFields() { }

  addVirtualNode(callback) {
    let t = this;
    t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ t.d, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});

    if (callback) { callback(); }
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

/**
 * Base class containing behavior for details pages that add html tags to a
 * container htmlDiv, e.g. showing help with header and p tags.
 */
export class HtmlDetailsCommandBase extends DetailsCommandBase {
  constructor(cmdName, ibScape, d) {
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;
    console.log("initializing htmlDiv...");
    t.htmlDiv =
      t.detailsView
        .append("div")
        .style("height", "100%")
        .style("width", "100%")
        .style("overflow", "auto");
  }

  close() {
    let t = this;
    t.htmlDiv.remove();
    console.log("htmlDiv removed.")
    super.close();
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
      text = `This is the root ibGib. Click anywhere in empty space to bring it up.`;
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

export class HuhDetailsCommand extends HtmlDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "huh";
    super(cmdName, ibScape, d);
  }

  init() {
    super.init();
    let t = this;

    if (t.d.virtualId) {
      switch (t.d.type) {
        case "cmd":
          t.addCmdHtml();
          break;
        case "ibGib":
          t.addVirtualIbGibHtml();
          break;
        case "rel8n":
          t.addRel8nHtml();
        default:
          console.error(`Unknown node type: ${JSON.stringify(t.d)}`);
      }
    }

    if (t.d.isContext) {
      t.addContextHtml();
    }

    if (t.d.isRoot) {
      t.addRootHtml();
    } else {
      t.addIbGibHtml();
    }
  }

  addCmdHtml() {
    let t = this;
    let cmd = t.d.cmd;
    let iconWidth = cmd.icon.length === 1 ? "70px" : "90px";

    t.htmlDiv
      .append("h2")
      .text(`Command: ${cmd.text}  `)
      .append("span")
        .style("padding", "5px")
        .style("width", iconWidth)
        .style("font-family", "FontAwesome")
        .style("background-color", cmd.color)
        .style("border-radius", "15px")
        .text(cmd.icon)

    t.htmlDiv
      .append("p")
      .text(cmd.description)

    if (cmd.huh && cmd.huh.length > 0) {
      t.htmlDiv
        .append("h3")
        .text(`Command Details`);
      cmd.huh.forEach(h => {
        t.htmlDiv
          .append("div")
          .html(md.render(h));
          // .text(h);
      });
    }

    t.htmlDiv
      .append("h3")
      .text(`What are Commands?`);
    t.htmlDiv
      .append("p")
      .text(`All of these circles and squares (and lines)...they're all ibGib. And the one you've just chosen is a Command. These are basically buttons that tell ibGib to do something.`)
    t.htmlDiv
      .append("p")
      .text(`You can find common commands for a given ibGib by clicking on it, and a full set of commands in the ibGib's pop-up menu (long-press the ibGib).`);

  }

  addVirtualIbGibHtml() {
    let t = this;
    t.htmlDiv
      .append("h2")
      .text("Virtual ibGib")
    t.htmlDiv
      .append("p")
      .text("yo this is some virtual help text")
  }
  addRel8nHtml() {
    let t = this;
    t.htmlDiv
      .append("h2")
      .text("Rel8n")
    t.htmlDiv
      .append("p")
      .text("yo this is some rel8n help text")
  }
  addRootHtml() {
    let t = this;
    t.htmlDiv
      .append("h2")
      .text("Root")
    t.htmlDiv
      .append("p")
      .text("yo this is some root help text")
  }
  addContextHtml() {
    let t = this;
    t.htmlDiv.append("div").html(md.render(huhText_Context));
  }
  addIbGibHtml() {
    let t = this;
    t.htmlDiv.append("div").html(md.render(huhText_IbGib));
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

    // Slight hack to remove the fork cmd button that seems to be sticking
    // around when forking. Probably happens with other commands, but I'm
    // noticing it with this. :nose:
    t.ibScape.removeVirtualCmdNodes();
  }

  addVirtualNode(callback) {
    let t = this;
    t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ null, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});
    if (callback) { callback(); }
  }

  getMessageData() {
    let t = this;

    let contextIbGib =
      t.ibScape.contextNode ? t.ibScape.contextNode.ibGib : "ib^gib";

    return {
      virtual_id: t.virtualNode.virtualId,
      src_ib_gib: t.d.ibGib,
      context_ib_gib: contextIbGib,
      dest_ib: $("#fork_form_data_dest_ib").val()
    };
  }

  handleSubmitResponse(msg) {
    let t = this;

    if (msg && msg.data && msg.data.forked_ib_gib) {
      let forkedIbGib = msg.data.forked_ib_gib;
      if (t.ibScape.contextIbGib === "ib^gib") {
        // If we've just forked on an ibScape that has no context (the
        // contextIbGib is the root), then we will actually navigate to the
        // new fork
        location.href = `/ibgib/${msg.data.forked_ib_gib}`;
      } else {
        // Our ibScape already has a context, so just zap the virtual node.
        t.virtualNode.ibGib = forkedIbGib;
        t.ibScape.zap(t.virtualNode);
      }
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

  /** Currently just trims whitespace of comment. */
  sanitizeFormFields() {
    let commentText = $("#comment_form_data_text").val();
    commentText = commentText.trim();
    $("#comment_form_data_text").val(commentText);
  }

  addVirtualNode(callback) {
    let t = this;
    if (t.d.type === "ibGib") {
      let rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "comment");

      let commentRel8nNode = null;
      if (rel8nNodes.length === 0) {
        t.ibScape.addSpiffyRel8ns(t.d);
        rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "comment");
      }
      commentRel8nNode = rel8nNodes[0];

      if (commentRel8nNode) {
        t.ibScape.zap(commentRel8nNode, () => {
          t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ commentRel8nNode, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});
          if (callback) { callback(); }
        });
      }

    } else if (t.d.type === "rel8n") {
      t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ t.d, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});
      if (callback) { callback(); }
    } else {
      console.error("Unknown t.d.type:", t.d.type);
      if (callback) { callback(); }
    }
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

    if (msg && msg.data && msg.data.comment_ib_gib) {
      if (msg.data.new_src_ib_gib) {
        // The src was directly commented on, so this user had authz to
        // do it (it's the ibGib's owner). So set the comment ibGib and
        // zap it.
        let commentIbGib = msg.data.comment_ib_gib;
        t.virtualNode.ibGib = commentIbGib;
        t.ibScape.zap(t.virtualNode, /*callback*/ null);
      } else {
        // The src was not updated, so this is a user commenting on
        // someone else's ibGib. So a comment was created and was rel8d
        // to the src, but the src has not been inversely rel8d to the
        // comment. So we'll remove the placeholder node and the
        // :new_adjunct event will create a new node.

        t.ibScape.remove(t.virtualNode);
      }
    } else {
      console.error(`${typeof(t)}: Unknown msg response from channel.`);
    }
  }
}

export class Mut8CommentDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "mut8comment";
    super(cmdName, ibScape, d);
  }

  /**
   * Overriding this because we will reuse the comment details form.
   */
  getFormId() { return `ib-comment-details-form`; }

  getDetailsViewId() { return `ib-comment-details`; }

  close() {
    let t = this;
    if (!t.submitted && t.srcNode) {
      t.ibScape.clearBusy(t.srcNode);
    }
    super.close();
  }

  init() {
    let t = this;

    t.srcNode = t.d.type === "rel8n" ? t.d.rel8nSrc : t.d;

    t.ibScape.setBusy(t.srcNode);

    d3.select("#comment_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    $("#comment_form_data_text")
      .val("Loading comment...")
      .attr("disabled", true);

    t.ibScape.ibGibProvider.getIbGibJson(t.d.ibGib, ibGibJson => {
      t.initialCommentText = ibHelper.getDataText(ibGibJson);
      $("#comment_form_data_text")
        .val(t.initialCommentText)
        .attr("disabled", false)
        .focus();
    });
  }

  /**
   * Default implementation is for a command that will produce a single virtual
   * node that will be busy while the message is sent to the server via the
   * channel.
   */
  submitFunc() {
    let t = this;
    console.log(`${t.cmdName} cmd submitFunc`);

    let commentText = $("#comment_form_data_text").val();
    if (t.initialCommentText !== commentText) {
      let form = document.getElementById(t.getFormId());
      if (form.checkValidity()) {
        // console.log("form is valid");
        t.submitted = true;
        let msg = t.getMessage();
        // can close only after we build the msg
        t.close();
        t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
          t.ibScape.clearBusy(t.srcNode);
          if (t.handleSubmitResponse) {
            t.handleSubmitResponse(successMsg);
          }
        }, (errorMsg) => {
          console.error(`Command errored. Msg: ${JSON.stringify(errorMsg)}`);
          // Delay clear busy to let the user see the error message and easily see which node we're talking about.
          t.ibScape.clearBusy(t.srcNode);
          let emsg = `There was an error when editing: ${JSON.stringify(errorMsg)}`;
          t.ibScape.setErrored(t.srcNode, /*clearAfterMsg*/ true, emsg);
        });
      } else {
        t.ibScape.clearBusy(t.srcNode);
        let emsg = "form is invalid (shouldn't get here ?)";
        console.error(emsg);
        t.ibScape.setErrored(t.srcNode, /*clearAfterMsg*/ true, emsg);
      }
    } else {
      alert("Comment text has not changed, so we ain't mut8ing");
      t.ibScape.clearBusy(t.srcNode);
      t.ibScape.highlightNode(t.srcNode, "rainbow", 6000);
    }
  }

  /** Currently just trims whitespace of comment. */
  sanitizeFormFields() {
    let commentText = $("#comment_form_data_text").val();
    commentText = commentText.trim();
    $("#comment_form_data_text").val(commentText);
  }

  addVirtualNode(callback) {
    // We do not add a virtual node when mut8ing a comment.
    if (callback) { callback(); }
  }

  getMessageData() {
    let t = this;

    return {
      src_ib_gib: t.d.type === "rel8n" ? t.d.rel8nSrc.ibGib : t.d.ibGib,
      comment_text: $("#comment_form_data_text").val()
    };
  }

  handleSubmitResponse(msg) {
    // Don't have to do anything, because the command will publish
    // an update msg on the event bus which will update the node.
  }
}

export class LinkDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "link";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#link_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    $("#link_form_data_text").val("").focus();
  }

  /** Currently just trims whitespace of link. */
  sanitizeFormFields() {
    let text = $("#link_form_data_text").val();
    text = text.trim();
    $("#link_form_data_text").val(text);
  }

  addVirtualNode(callback) {
    let t = this;
    if (t.d.type === "ibGib") {
      let rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "link");

      let linkRel8nNode = null;
      if (rel8nNodes.length === 0) {
        t.ibScape.addSpiffyRel8ns(t.d);
        rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "link");
      }
      linkRel8nNode = rel8nNodes[0];

      if (linkRel8nNode) {
        t.ibScape.zap(linkRel8nNode, () => {
          t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ linkRel8nNode, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});
          if (callback) { callback(); }
        });
      }
    } else if (t.d.type === "rel8n") {
      t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ t.d, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});
      if (callback) { callback(); }
    } else {
      console.error("Unknown t.d.type:", t.d.type);
      if (callback) { callback(); }
    }
  }

  getMessageData() {
    let t = this;

    return {
      virtual_id: t.virtualNode.virtualId,
      src_ib_gib: t.d.type === "rel8n" ? t.d.rel8nSrc.ibGib : t.d.ibGib,
      link_text: $("#link_form_data_text").val()
    };
  }

  handleSubmitResponse(msg) {
    let t = this;

    if (msg && msg.data && msg.data.link_ib_gib) {
      if (msg.data.new_src_ib_gib) {
        // The src was directly linked on, so this user had authz to
        // do it (it's the ibGib's owner). So set the link ibGib and
        // zap it.
        let linkIbGib = msg.data.link_ib_gib;
        t.virtualNode.ibGib = linkIbGib;
        t.ibScape.zap(t.virtualNode, /*callback*/ null);
      } else {
        // The src was not updated, so this is a user linking on
        // someone else's ibGib. So a link was created and was rel8d
        // to the src, but the src has not been inversely rel8d to the
        // link. So we'll remove the placeholder node and the
        // :new_adjunct event will create a new node.

        t.ibScape.remove(t.virtualNode);
      }
    } else {
      console.error(`${typeof(t)}: Unknown msg response from channel.`);
    }
  }
}

export class IdentEmailDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "identemail";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#identemail_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    $("#identemail_form_data_text").focus();
  }

  getMessageData() {
    // MessageData is not used in ident email. Uses xhr.

    // let t = this;
    //
    // document.getElementById('pic_form_data_file').files[0]
    //
    // var formData = new FormData();
    // formData.append("fileToUpload", document.getElementById('fileToUpload').files[0]);
    //
    // return {
    //   virtual_id: t.virtualNode.virtualId,
    //   src_ib_gib: t.d.type === "rel8n" ? t.d.rel8nSrc.ibGib : t.d.ibGib,
    //   comment_text: $("#comment_form_data_text").val()
    // };
  }

  /**
   * Default implementation is for a command that will produce a single virtual
   * node that will be busy while the message is sent to the server via the
   * channel.
   */
  submitFunc() {
    let t = this;
    console.log(`${t.cmdName} cmd submitFunc`);

    // let form = document.getElementById(t.getFormId());
    let form = document.querySelector("#" + t.getFormId());
    let formData = new FormData(form);

    // for (let [key, value] of formData.entries()) {
    //   console.log(key, value);
    // }

    let xhr = new XMLHttpRequest();
    xhr.addEventListener("load", t.xhrComplete, false);
    xhr.addEventListener("error", t.xhrFailed, false);
    xhr.addEventListener("abort", t.xhrCanceled, false);
    xhr.open("POST", "/ibgib/ident");
    xhr.send(formData);

    // if (form.checkValidity()) {
    //   console.log("form is valid");
    //   t.addVirtualNode();
    //   t.ibScape.setBusy(t.virtualNode);
    //
    //   let msg = t.getMessage();
    //   t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
    //     t.ibScape.clearBusy(t.virtualNode);
    //     if (t.handleSubmitResponse) {
    //       t.handleSubmitResponse(successMsg);
    //     }
    //   }, (errorMsg) => {
    //     console.error(`Command errored. Msg: ${JSON.stringify(errorMsg)}`);
    //     t.ibScape.clearBusy(t.virtualNode);
    //     t.virtualNode.type = "error";
    //     t.virtualNode.errorMsg = JSON.stringify(errorMsg);
    //     t.ibScape.zap(t.virtualNode, /*callback*/ null);
    //   });
    // } else {
    //   console.log("form is invalid");
    // }

    t.close();
  }

  /* This event is raised when the server send back a response */
  xhrComplete(evt) {
    console.log(`xhrComplete. responseText: ${evt.target.responseText}`)
  }

  xhrFailed(evt) {
    console.log(`xhrFailed. evt: ${JSON.stringify(evt)}`);
  }

  xhrCanceled(evt) {
    console.log(`xhrCanceled. The upload has been canceled by the user or the browser dropped the connection.`);
  }

  // handleSubmitResponse(msg) {
  //   let t = this;
  //
  //   if (msg && msg.data && msg.data.comment_ib_gib) {
  //     if (msg.data.new_src_ib_gib) {
  //       // The src was directly commented on, so this user had authz to
  //       // do it (it's the ibGib's owner). So set the comment ibGib and
  //       // zap it.
  //       let commentIbGib = msg.data.comment_ib_gib;
  //       t.virtualNode.ibGib = commentIbGib;
  //       t.ibScape.zap(t.virtualNode, /*callback*/ null);
  //     } else {
  //       // The src was not updated, so this is a user commenting on
  //       // someone else's ibGib. So a comment was created and was rel8d
  //       // to the src, but the src has not been inversely rel8d to the
  //       // comment. So we'll remove the placeholder node and the
  //       // :new_adjunct event will create a new node.
  //
  //       t.ibScape.remove(t.virtualNode);
  //     }
  //   } else {
  //     console.error(`${typeof(t)}: Unknown msg response from channel.`);
  //   }
  // }

}

export class PicDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "pic";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#pic_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    $("#pic_form_data_file").focus();
  }

  addVirtualNode(callback) {
    let t = this;
    // Adding rigamarole because user can either click the add + cmd
    // on the pic rel8n or right-click on the ibGib itself. So t.d will
    // be one of two nodes. If it's the rel8n, then we have to handle
    // in case it's already expanded
    if (t.d.type === "ibGib") {
      let rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "pic");

      let picRel8nNode = null;
      if (rel8nNodes.length === 0) {
        t.ibScape.addSpiffyRel8ns(t.d);
        rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "pic");
      }
      picRel8nNode = rel8nNodes[0];

      if (picRel8nNode) {
        t.ibScape.zap(picRel8nNode, () => {
          t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ picRel8nNode, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});
          if (callback) { callback(); }
        });
      }

    } else if (t.d.type === "rel8n") {
      t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ t.d, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: t.d.x, y: t.d.y});
      if (callback) { callback(); }
    } else {
      console.error("Unknown t.d.type:", t.d.type);
      if (callback) { callback(); }
    }
  }

  /**
   * Default implementation is for a command that will produce a single virtual
   * node that will be busy while the message is sent to the server via the
   * channel.
   */
  submitFunc() {
    let t = this;
    console.log(`${t.cmdName} cmd submitFunc`);

    let file = document.getElementById('pic_form_data_file').files[0];
    let form = document.querySelector("#" + t.getFormId());
    if (form.checkValidity()) {
      let formData = new FormData(form);

      t.addVirtualNode(() => {
        t.ibScape.setBusy(t.virtualNode);

        for (let [key, value] of formData.entries()) {
          console.log(key, value);
        }

        let xhr = new XMLHttpRequest();
        xhr.upload.addEventListener("progress", (e) => t.xhrUploadProgress(e), false);
        xhr.addEventListener("load", (e) => t.xhrComplete(e), false);
        xhr.addEventListener("error", (e) => t.xhrFailed(e), false);
        xhr.addEventListener("abort", (e) => t.xhrCanceled(e), false);
        xhr.open("POST", "/ibgib/pic");
        xhr.send(formData);
      });
    } else {
      alert("Please select a valid image file!");
    }

    t.close();
  }

  /* This event is raised when the server send back a response */
  xhrComplete(evt) {
    let t = this, lc = `xhrComplete`;

    let { status } = evt.target;
    if (status === 200) {
      let picIbGib = evt.target.responseText;
      console.log(`${lc} Upload status 200. Removing temp virtualNode. pic_ib_gib: ${picIbGib}`);
      t.ibScape.clearBusy(t.virtualNode);
      t.ibScape.updateIbGib(t.virtualNode, picIbGib, /*skipUpdateUrl*/ false, /*callback*/ null)
      // t.ibScape.remove(t.virtualNode);
    } else {
      console.log(`${lc} Upload status ${status}. evt: ${JSON.stringify(evt)}`);

      t.ibScape.clearBusy(t.virtualNode);
      t.virtualNode.type = "error";
      t.virtualNode.errorMsg = evt.target.responseText;
      t.ibScape.zap(t.virtualNode, /*callback*/ null);

      // hack. need to change this to show a details information popup
      // so the user can just click on the links.
      // alert(evt.target.responseText);
    }
  }

  xhrFailed(evt) {
    let t = this, lc = `xhrFailed`;
    console.log(`${lc} evt: ${JSON.stringify(evt)}`);
    t.ibScape.clearBusy(t.virtualNode);
    t.virtualNode.type = "error";
    t.virtualNode.errorMsg = JSON.stringify(evt);
    t.ibScape.zap(t.virtualNode, /*callback*/ null);
  }

  xhrCanceled(evt) {
    let t = this, lc = `xhrCanceled`;

    console.log(`${lc} The upload has been canceled by the user or the browser dropped the connection.`);
    console.log(`${lc} evt: ${JSON.stringify(evt)}`);
    t.ibScape.clearBusy(t.virtualNode);
    t.virtualNode.type = "error";
    t.virtualNode.errorMsg = "Cancelled by user.";
    t.ibScape.zap(t.virtualNode, /*callback*/ null);
  }

  xhrUploadProgress(evt) {
    let t = this, lc = `xhrUploadProgress`;

    if (evt.lengthComputable) {
      var percentComplete = Math.round(evt.loaded * 100 / evt.total);
      t.virtualNode.label = `{percentComplete}%`
      console.log(`${lc} pct complete... ${percentComplete}%`)
    }
    else {
      console.log(`${lc} error upload progress`)
    }
  }

  getMessageData() {
    throw new Error("Not implemented in this class");
  }

  handleSubmitResponse(msg) {
    throw new Error("Not implemented in this class");
  }

  // handleSubmitResponse(msg) {
  //   let t = this;
  //
  //   if (msg && msg.data && msg.data.comment_ib_gib) {
  //     if (msg.data.new_src_ib_gib) {
  //       // The src was directly commented on, so this user had authz to
  //       // do it (it's the ibGib's owner). So set the comment ibGib and
  //       // zap it.
  //       let commentIbGib = msg.data.comment_ib_gib;
  //       t.virtualNode.ibGib = commentIbGib;
  //       t.ibScape.zap(t.virtualNode, /*callback*/ null);
  //     } else {
  //       // The src was not updated, so this is a user commenting on
  //       // someone else's ibGib. So a comment was created and was rel8d
  //       // to the src, but the src has not been inversely rel8d to the
  //       // comment. So we'll remove the placeholder node and the
  //       // :new_adjunct event will create a new node.
  //
  //       t.ibScape.remove(t.virtualNode);
  //     }
  //   } else {
  //     console.error(`${typeof(t)}: Unknown msg response from channel.`);
  //   }
  // }
}

export class GotoCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "goto";
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();
    let t = this;

    location.href = `/ibgib/${t.d.ibGib}`
  }
}

export class RefreshCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "refresh";
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();

    let t = this;
    console.log(`${t.cmdName} cmd exec`);

    t.ibScape.setBusy(t.d);

    let msg = t.getMessage();
    t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
      t.handleSubmitResponse(successMsg);
    }, (errorMsg) => {
      console.error(`${t.cmdName} command errored. Msg: ${JSON.stringify(errorMsg)}`);
      t.ibScape.clearBusy(t.d);
      t.virtualNode.type = "error";
      t.virtualNode.errorMsg = JSON.stringify(errorMsg);
      t.ibScape.zap(t.virtualNode, /*callback*/ null);
    });
  }

  getMessage() {
    let t = this;

    return {
      data: t.getMessageData(),
      metadata: t.getMessageMetadata()
    };
  }

  getMessageData() {
    let t = this;

    return {
      src_ib_gib: t.d.ibGib
    };
  }

  getMessageMetadata() {
    let t = this;

    return {
      name: t.cmdName,
      type: "cmd",
      local_time: new Date()
    };
  }

  handleSubmitResponse(msg) {
    let t = this;

    if (msg && msg.data) {
      if (msg.data.latest_is_different) {
        t.ibScape.clearBusy(t.d);

        t.ibScape.updateIbGib(t.d, msg.data.latest_ib_gib, /*skipUpdateUrl*/ false, /*callback*/ () => {
        });
      } else {
        // already up-to-date
        t.ibScape.clearBusy(t.d);
      }
    } else {
      console.error("RefreshCommand.handleSubmitResponse: No msg data(?)");
    }
  }
}

/** Allow an adjunct ibGib to be rel8d directly to its target ibGib. */
export class AllowCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "allow";
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();

    let t = this;
    console.log(`${t.cmdName} cmd exec`);

    t.ibScape.removeVirtualCmdNodes();
    t.ibScape.setBusy(t.d);

    let msg = t.getMessage();
    t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
      console.log(`AllowCommand successMsg: ${JSON.stringify(successMsg)}`)
      t.handleSubmitResponse(successMsg);
    }, (errorMsg) => {
      console.error(`${t.cmdName} command errored. Msg: ${JSON.stringify(errorMsg)}`);
      t.ibScape.clearBusy(t.d);
      t.virtualNode.type = "error";
      t.virtualNode.errorMsg = JSON.stringify(errorMsg);
      t.ibScape.zap(t.virtualNode, /*callback*/ null);
    });
  }

  getMessage() {
    let t = this;

    return {
      data: t.getMessageData(),
      metadata: t.getMessageMetadata()
    };
  }

  getMessageData() {
    let t = this;

    return {
      adjunct_ib_gib: t.d.ibGib
    };
  }

  getMessageMetadata() {
    let t = this;

    return {
      name: t.cmdName,
      type: "cmd",
      local_time: new Date()
    };
  }

  handleSubmitResponse(msg) {
    let t = this;

    t.ibScape.clearBusy(t.d);

    // if (msg && msg.data) {
    //   if (msg.data.latest_is_different) {
    //     console.warn(`${typeof(t)}: There's a new version available...should come down event bus...(if hasn't already done so)`);
    //     // new one available, don't clear busy.
    //   } else {
    //     // already up-to-date
    //     t.ibScape.clearBusy(t.d);
    //   }
    // } else {
    //   console.error("RefreshCommand.handleSubmitResponse: No msg data(?)");
    // }
  }
}

/**
 * I'm creating this not to use as a menu command, rather to call from the
 * IbGibIbScapeBackgroundRefresher. So this class breaks some conventions used
 * currently in other of the command classes: Doesn't hide the menu for one.
 * Probably others...
 */
export class BatchRefreshCommand extends CommandBase {
  constructor(ibScape, d, successCallback, errorCallback) {
    const cmdName = "batchrefresh";
    super(cmdName, ibScape, d);

    let t = this;
    t.successCallback = successCallback;
    t.errorCallback = errorCallback;
  }

  exec() {
    // Does NOT call super.exec() because this command is different. See class
    // documentation for details.
    // super.exec();

    let t = this;
    // console.log(`${t.cmdName} cmd exec`);

    let msg = t.getMessage();
    t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
      if (t.successCallback) {
         t.successCallback(successMsg);
       }
    }, (errorMsg) => {
      console.error(`${t.cmdName} command errored. Msg: ${JSON.stringify(errorMsg)}`);
      if (t.errorCallback) { t.errorCallback(errorMsg); }
    });
  }

  getMessage() {
    let t = this;

    return {
      data: t.getMessageData(),
      metadata: t.getMessageMetadata()
    };
  }

  getMessageData() {
    let t = this;

    return {
      ib_gibs: t.d.ibGibs
    };
  }

  getMessageMetadata() {
    let t = this;

    return {
      name: t.cmdName,
      type: "cmd",
      count: t.d.ibGibs.length,
      local_time: new Date()
    };
  }
}

/**
 * Gets the adjuncts for a given ibGib data `d` and returns the adjuncts
 * in the given `successCallback` when executed.
 *
 * The data `d` is not the "normal" d3 node `d` variable, but just data
 * that contains information for the command. IOW, it is not the data
 * associated to a d3 node, since this command is executed on its own.
 *
 * (Probably will need to revisit exact command architecture for these
 * non-menu command commands, i.e. refactor.)
 */
export class GetAdjunctsCommand extends CommandBase {
  constructor(ibScape, d, successCallback, errorCallback) {
    const cmdName = "getadjuncts";
    super(cmdName, ibScape, d);

    let t = this;
    t.successCallback = successCallback;
    t.errorCallback = errorCallback;
  }

  exec() {
    // Does NOT call super.exec() because this command is different. See class
    // documentation for details.
    // super.exec();

    let t = this;
    // console.log(`${t.cmdName} cmd exec`);

    let msg = t.getMessage();
    t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
      if (t.successCallback) {
         t.successCallback(successMsg);
       }
    }, (errorMsg) => {
      console.error(`${t.cmdName} command errored. Msg: ${JSON.stringify(errorMsg)}`);
      if (t.errorCallback) { t.errorCallback(errorMsg); }
    });
  }

  getMessage() {
    let t = this;

    return {
      data: t.getMessageData(),
      metadata: t.getMessageMetadata()
    };
  }

  getMessageData() {
    let t = this;

    return {
      ib_gibs: t.d.ibGibs
    };
  }

  getMessageMetadata() {
    let t = this;

    return {
      name: t.cmdName,
      type: "cmd",
      count: t.d.ibGibs.length,
      local_time: new Date()
    };
  }
}
