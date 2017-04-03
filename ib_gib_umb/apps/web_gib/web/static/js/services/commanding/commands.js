import * as d3 from 'd3';

var md = require('markdown-it')({
  html: true,
  linkify: true,
  typographer: true,
});
var emoji = require('markdown-it-emoji');
md.use(emoji);
var twemoji = require('twemoji')
md.renderer.rules.emoji = function(token, idx) {
  return twemoji.parse(token[idx].content);
};

import * as ibHelper from '../ibgib-helper';
import * as ibAuthz from '../ibgib-authz';
import { d3MenuCommands, d3RootUnicodeChar } from '../../d3params';
import { huhText_IbGib } from '../../huh-texts/ibgib';
import { huhText_Context } from '../../huh-texts/context';
import { huhText_Root } from '../../huh-texts/root';
import { huhText_Source } from '../../huh-texts/source';
import { huhText_Huh } from '../../huh-texts/huh';
import { huhText_Command } from '../../huh-texts/command';
import { huhText_Cmd_IdentEmail } from "../../huh-texts/commands/ident-email";
import { huhText_Cmd_Pic } from "../../huh-texts/commands/pic";

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

    if (t.closedEarly) {
      return;
    }

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
      t.submitted = true;
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
        .attr("class", "ib-details-html-div")
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

export class HuhDetailsCommand extends HtmlDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "huh";
    super(cmdName, ibScape, d);
  }

  init() {
    super.init();
    let t = this;

    t.htmlDiv
      .style("font-family", "Impact")
      .style("font-size", "25px");

    if (t.d.type === "cmd") { t.addCmdHtml(); }

    t.addHuhHtml();

    if (t.d.isRoot) { t.addRootHtml(); } 
    
    if (t.d.isContext) {
      t.addContextHtml();
    } else if (t.d.isSource) {
      t.addSourceHtml();
    }

    t.addIbGibHtml();
  }

  addCmdHtml() {
    let t = this;
    let cmd = t.d.cmd;
    
    t.addSection(t.d.cmd.name, `${t.d.cmd.text}?`, t.d.cmd.huh);
    t.addSection("commands", `Commands?`, huhText_Command);
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
  addHuhHtml() {
    let t = this;
    t.addSection("huh", "Huh?!?", huhText_Huh);
  }
  addRootHtml() {
    let t = this;
    t.addSection("root", "The Root?", huhText_Root);
  }
  addContextHtml() {
    let t = this;
    t.addSection("context", "Context?", huhText_Context);
  }
  addSourceHtml() {
    let t = this;
    t.addSection("source", "Sources?", huhText_Source);
  }
  addIbGibHtml() {
    let t = this;
    t.addSection("ibgib", "ibGib?", huhText_IbGib);
  }
  
  addSection(sectionName, title, contentText) {
    let t = this;
    let sectionId = `ib-details-huh-${sectionName}`;
    t.htmlDiv
      .append("button")
        .attr("class", "accordion")
        .on("click", function() {
          this.classList.toggle("active");
          let panel = this.nextElementSibling;
      	  if (panel.style.maxHeight){
        	  panel.style.maxHeight = null;
          } else {
        	  panel.style.maxHeight = panel.scrollHeight + 'px';
          } 
        })
      .append("h1")
      .text(title)
    t.htmlDiv
      .append("div")
      .attr("id", sectionId)
      .attr("class", "ib-details-html-div panel")
      .html(md.render(contentText));
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

    if (!ibHelper.isMobile()) {
      $("#query_form_data_search_text").focus();
    }
    
    t.initButtons();
  }
  
  initButtons() {
    const presets = [
      { name: "home", text: "home", icons: ":house:" },
      { name: "bookmark", text: "bookmark", icons: ":bookmark:" },
      { name: "star", text: "star", icons: ":star:" },
      { name: "thumbsup", text: "thumbsup", icons: ":+1:" },
      { name: "question", text: "question", icons: ":question:" },
      { name: "answered", text: "answered", icons: ":white_check_mark:" },
      { name: "heart", text: "heart", icons: ":heart:" },
      { name: "inbox", text: "inbox", icons: ":inbox_tray:" },
      { name: "x", text: "x", icons: ":x:" },
      { name: "important", text: "important", icons: ":exclamation:" },
    ]
    presets.forEach(preset => {
      $(`#ib-details-query-btn-preset-${preset.name}`)
        .unbind("click")
        .on("click", () => {
          console.log(`clicked`)
          $('#query_form_data_search_text').val(preset.text);
        })
    })
    
    $(`#query_form_data_tag_is`)
      .unbind("change")
      .on("change", e => {
        $(`#ib-details-query-btn-presets-div`).toggleClass("ib-hidden");
      });
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

    // let contextIbGibJson = t.ibScape.contextNode.ibGibJson;
    // if (ibAuthz.isAuthorizedForMut8OrRel8(contextIbGibJson)) {
      if (msg && msg.data && msg.data.forked_ib_gib) {
        
        if (msg.data.new_context_ib_gib_or_nil) {
          // User was authzd to rel8 to non-Root Context.
          // So just zap the virtual node.
          t.virtualNode.ibGib = msg.data.forked_ib_gib;
          t.ibScape.zap(t.virtualNode);
        } else {
          if (t.ibScape.contextIbGib === "ib^gib") {
            // Context was the root
            location.href = `/ibgib/${msg.data.forked_ib_gib}`;
          } else {
            // User was NOT authzd to rel8 to non-Root Context
            // Maybe do this in a new tab (in case the user didn't
            // know what was going to happen).
            // t.ibScape.remove(t.virtualNode);
            // window.open(`/ibgib/${msg.data.forked_ib_gib}`, "_blank");

            // I'm changing to this because it does popup blocking and that's
            // annoying. So just redirecting to new fork.
            location.href = `/ibgib/${msg.data.forked_ib_gib}`;
          }
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

    if (!t.detailsView.commentAutocompleteInitialized) {
      ibHelper.initAutocomplete("comment_form_data_text");
      t.detailsView.commentAutocompleteInitialized = true;
    }
    
    $("#comment_form_data_text").val("").focus();
  }

  close() {
    let t = this;

    let commentText = $("#comment_form_data_text").val();
    if (!t.submitted && commentText) {
      let confirmMsg = `Lose unsaved changes?\n\nPress OK to close and lose unsaved changes.\nPress Cancel to return to editing your text.`;
      if (!confirm(confirmMsg)) { return; }
    }

    super.close();
  }
  
  /** Currently just trims whitespace of comment. */
  sanitizeFormFields() {
    let commentText = $("#comment_form_data_text").val();
    commentText = commentText.trim();
    $("#comment_form_data_text").val(commentText);
  }

  addVirtualNode(callback) {
    let t = this, lc = `Comment addVirtualNode`;
    console.log(`${lc} start. t.d.type: ${t.d.type}`)
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
          t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ commentRel8nNode, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: commentRel8nNode.x, y: commentRel8nNode.y});
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
    console.log("new comment handle submit response");
    if (msg && msg.data && msg.data.comment_ib_gib) {
      if (msg.data.new_src_ib_gib) {
        // Update the cache with the new src_ib_gib
        console.log(`new comment. src tempJuncIbGib: ${t.d.tempJuncIbGib}. new: ${msg.data.new_src_ib_gib}`)
        
        // The src was directly commented on, so this user had authz to
        // do it (it's the ibGib's owner). So set the comment ibGib and
        // zap it.
        // debugger;
        let commentIbGib = msg.data.comment_ib_gib;
        t.virtualNode.ibGib = commentIbGib;
        t.ibScape.zap(t.virtualNode, () => {
          t.ibScape.ibGibEventBus.broadcastIbGibUpdate_LocallyOnly(t.d.tempJuncIbGib, msg.data.new_src_ib_gib);
        });
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

    if (!t.submitted) {
      let commentText = $("#comment_form_data_text").val();
      
      if (commentText !== t.initialCommentText) {
        let confirmMsg = `Lose unsaved changes?\n\nPress OK to close and lose unsaved changes.\nPress Cancel to return to editing your text.`;
        if (!confirm(confirmMsg)) { return; }
      }
    } 
    
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
      
      if (!t.detailsView.commentAutocompleteInitialized) {
        ibHelper.initAutocomplete("comment_form_data_text");
        t.detailsView.commentAutocompleteInitialized = true;
      }

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
        t.ibScape.zap(t.virtualNode, () => {
          t.ibScape.ibGibEventBus.broadcastIbGibUpdate_LocallyOnly(t.d.tempJuncIbGib, msg.data.new_src_ib_gib);
        });
        // t.ibScape.zap(t.virtualNode, /*callback*/ null);
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

export class TagDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "tag";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#tag_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    if (!t.detailsView.commentAutocompleteInitialized) {
      ibHelper.initAutocomplete("tag_form_data_icons_text");
      t.detailsView.commentAutocompleteInitialized = true;
    }

    if (!ibHelper.isMobile()) {
      $("#tag_form_data_text").val("").focus();
    }
    
    t.initButtons();
  }

  initButtons() {
    const presets = [
      { name: "home", text: "home", icons: ":house:" },
      { name: "bookmark", text: "bookmark", icons: ":bookmark:" },
      { name: "star", text: "star", icons: ":star:" },
      { name: "thumbsup", text: "thumbsup", icons: ":+1:" },
      { name: "question", text: "question", icons: ":question:" },
      { name: "answered", text: "answered", icons: ":white_check_mark:" },
      { name: "heart", text: "heart", icons: ":heart:" },
      { name: "inbox", text: "inbox", icons: ":inbox_tray:" },
      { name: "x", text: "x", icons: ":x:" },
      { name: "important", text: "important", icons: ":exclamation:" },
    ]
    presets.forEach(preset => {
      $(`#ib-details-tag-btn-preset-${preset.name}`)
        .unbind("click")
        .on("click", () => {
          console.log(`clicked`)
          $('#tag_form_data_text').val(preset.text);
          $('#tag_form_data_icons_text').val(preset.icons);
        })
    })
  }
  
  /** Currently just trims whitespace of tag. */
  sanitizeFormFields() {
    let tagText = $("#tag_form_data_text").val();
    tagText = tagText.trim();
    $("#tag_form_data_text").val(tagText);
    
    let tagIconsText = $("#tag_form_data_icons_text").val();
    tagIconsText = tagIconsText.trim();
    $("#tag_form_data_icons_text").val(tagIconsText);
  }

  addVirtualNode(callback) {
    let t = this, lc = `Comment addVirtualNode`;
    console.log(`${lc} start. t.d.type: ${t.d.type}`)

    if (t.d.type === "ibGib") {
      let rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "tag");

      let tagRel8nNode = null;
      if (rel8nNodes.length === 0) {
        t.ibScape.addSpiffyRel8ns(t.d);
        rel8nNodes = t.ibScape.getChildren_Rel8ns(t.d).filter(rel8nNode => rel8nNode.rel8nName === "tag");
        if (rel8nNodes.length === 0) {
          // still zero, so no pre-existing tag rel8ns. So add it anew.
          tagRel8nNode = t.ibScape.addRel8nVirtualNode(t.d, "tag", /*fadeTimeoutMs*/ 0);
          rel8nNodes = [tagRel8nNode];
        }
      }
      
      tagRel8nNode = rel8nNodes[0];

      if (tagRel8nNode) {
        t.ibScape.zap(tagRel8nNode, () => {
          t.virtualNode = t.ibScape.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ t.cmdName + "_virtualnode", /*srcNode*/ tagRel8nNode, /*shape*/ "circle", /*autoZap*/ false, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ d3RootUnicodeChar, /*startPos*/ {x: tagRel8nNode.x, y: tagRel8nNode.y});
          if (callback) { callback(); }
        });
      } else {
        console.error(`Tried to tag, but no tagRel8nNode?`);
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
      tag_text: $("#tag_form_data_text").val(),
      tag_icons_text: $("#tag_form_data_icons_text").val()
    };
  }

  handleSubmitResponse(msg) {
    let t = this;
    console.log("new tag handle submit response");
    if (msg && msg.data && msg.data.tag_ib_gib) {
      if (msg.data.new_src_ib_gib) {
        // Update the cache with the new src_ib_gib
        console.log(`new tag. src tempJuncIbGib: ${t.d.tempJuncIbGib}. new: ${msg.data.new_src_ib_gib}`)
        
        // The src was directly taged on, so this user had authz to
        // do it (it's the ibGib's owner). So set the tag ibGib and
        // zap it.
        // debugger;
        let tagIbGib = msg.data.tag_ib_gib;
        t.virtualNode.ibGib = tagIbGib;
        t.ibScape.zap(t.virtualNode, () => {
          t.ibScape.ibGibEventBus.broadcastIbGibUpdate_LocallyOnly(t.d.tempJuncIbGib, msg.data.new_src_ib_gib);
        });
      } else {
        // The src was not updated, so this is a user taging on
        // someone else's ibGib. So a tag was created and was rel8d
        // to the src, but the src has not been inversely rel8d to the
        // tag. So we'll remove the placeholder node and the
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
}

export class UnIdentEmailDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "unidentemail";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    d3.select("#unidentemail_form_data_src_ib_gib")
      .attr("value", t.d.ibGib);

    d3.select("#unidentemail_form_data_email_addr")
      .text(t.d.ibGibJson.data.email_addr);

    $("#ib-unidentemail-details-submit-btn").focus();
  }

  submitFunc() {
    let t = this;
    console.log(`${t.cmdName} cmd submitFunc`);
    
    let form = document.querySelector("#" + t.getFormId());
    let formData = new FormData(form);

    for (let [key, value] of formData.entries()) {
      console.log(key, value);
    }

    let xhr = new XMLHttpRequest();
    xhr.addEventListener("load", (evt) => t.xhrComplete(evt, t.d.ibGibJson.data.email_addr), false);
    xhr.addEventListener("error", t.xhrFailed, false);
    xhr.addEventListener("abort", t.xhrCanceled, false);
    xhr.open("POST", "/ibgib/unident");
    xhr.send(formData);

    t.close();
  }

  /* 
   * This event is raised when the server send back a response (even if it's an
   * error response 500, 400, etc.)
   */
  xhrComplete(evt, emailAddress) {
    let t = this;
    console.log(`xhrComplete. response status: ${evt.target.status}`)
    if (evt.target.status === 200) {
      alert(`${emailAddress} has been removed from your current identity. The page must now reload.`);
      
      // Do we even get here?
      
      // // Thanks SO! http://stackoverflow.com/a/28171425/4275029
      // setTimeout(() => window.location.reload());
    } else {
      alert(`Logging out ${emailAddress} had an error: ${evt.target.responseText}}`);
    }
  }

  xhrFailed(evt) {
    console.log(`xhrFailed. evt: ${JSON.stringify(evt)}`);
  }

  xhrCanceled(evt) {
    console.log(`xhrCanceled. evt: ${JSON.stringify(evt)}`);
  }
}

export class PicDetailsCommand extends FormDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "pic";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

      
    if (ibAuthz.isIdentifiedByEmail(t.ibScape.currentIdentityIbGibs)) {
      d3.select("#pic_form_data_src_ib_gib")
        .attr("value", t.d.ibGib);

      d3.select("#ib-pic-details-unauthorized")
        .attr("class", "ib-hidden");
      d3.select("#ib-pic-details-authorized")
        .attr("class", "ib-height-100");

      $("#pic_form_data_file").focus();
    } else {
      // If user is not authorized to upload pic
      d3.select("#ib-pic-details-unauthorized")
        .attr("class", "ib-height-100");
      d3.select("#ib-pic-details-authorized")
        .attr("class", "ib-hidden");
        
      t.addUnauthorizedHelpHtml();
    }
  }

  addUnauthorizedHelpHtml() {
    let t = this;
    t.htmlDiv = d3.select("#ib-pic-details-unauthorized-help")
      .append("div")
      .attr("class", "ib-height-100 ib-overflow-y-auto");
    
    let noEntry = `<span style="color: red">:no_entry:</span>`;
    let errorText = `---\n\n${noEntry} To upload a pic, you must first identify yourself with an email address :-) ${noEntry}\n\n---`;
    t.htmlDiv
      .append("h2")
      .html(md.render(errorText))
      
    // t.htmlDiv
    //   .append("br");

    t.addSection("Identify", "Identify?", huhText_Cmd_IdentEmail);
    t.addSection("Pic", "Pic?", huhText_Cmd_Pic);

    // t.htmlDiv
    //   .append("div")
    //   .html(md.render("---\n" + huhText_Cmd_Pic))
  }

  addSection(sectionName, title, contentText) {
    let t = this;
    let sectionId = `ib-details-huh-${sectionName}`;
    t.htmlDiv
      .append("button")
        .attr("class", "accordion")
        .on("click", function() {
          this.classList.toggle("active");
          let panel = this.nextElementSibling;
      	  if (panel.style.maxHeight){
        	  panel.style.maxHeight = null;
          } else {
        	  panel.style.maxHeight = panel.scrollHeight + 'px';
          } 
        })
      .append("h1")
      .text(title)
    t.htmlDiv
      .append("div")
      .attr("id", sectionId)
      .attr("class", "ib-details-html-div panel")
      .html(md.render(contentText));
  }

  close() {
    let t = this;
    if (t.htmlDiv) { t.htmlDiv.remove(); }
    super.close();
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
    let t = this, lc = `RefreshCommand.handleSubmitResponse`;

    if (msg && msg.data && msg.metadata && msg.metadata.refresh_kind) {
      switch (msg.metadata.refresh_kind) {
        case "latest":
          t.ibScape.clearBusy(t.d);
          if (msg.data.latest_is_different) {
            t.ibScape.updateIbGib(t.d, msg.data.latest_ib_gib, /*skipUpdateUrl*/ false, /*callback*/ () => {
              console.log(`${lc} updated latest with new ib^gib.`)
            });
          }
          break;
        case "query_result":
          t.ibScape.clearBusy(t.d);
          if (msg.data.latest_is_different) {
            t.ibScape.removeChildren(t.d, /*durationMs*/ 0);

            t.ibScape.updateIbGib(t.d, msg.data.latest_ib_gib, /*skipUpdateUrl*/ false, /*callback*/ () => {
              console.log(`${lc} updated query result with new results.`)
            });
          }
          break;
        case "query":
            location.href = `/ibgib/${msg.data.query_result_ib_gib}`
          break;
        default:
          console.error(`${lc} Unknown or missing refresh_kind. msg: ${JSON.stringify(msg)}`)
      }
    } else {
      console.error(`${lc} Invalid refresh response? msg: ${JSON.stringify(msg)}`);
    }
  }
}

/** Acknowledge an adjunct ibGib to be rel8d directly to its target ibGib. */
export class AckCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "ack";
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
      console.log(`AckCommand successMsg: ${JSON.stringify(successMsg)}`)
      t.handleSubmitResponse(successMsg);
      
      if (t.d.isMeta) {
        // when we're acking in meta menu, we need to do some things manually.
        t.ibScape.removeNodeAndChildren(t.d);
      }

    }, (errorMsg) => {
      let emsg = `${t.cmdName} command errored. Msg: ${JSON.stringify(errorMsg)}`;
      console.error(emsg);
      alert(emsg);
      t.ibScape.clearBusy(t.d);
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

/** Move a non-Context ibGib to the "trash" rel8n of its parent ibGib. */ 
export class TrashCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "trash";
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();
    
    let t = this, lc = `TrashCommand.exec`;
    console.log(`${t.cmdName} cmd exec`);

    t.ibScape.removeVirtualCmdNodes();
    if (t.d.isSource) {
      t.parent = t.ibScape.contextNode;
      t.parentRel8nName = "ib^gib";
    } else if (t.d.parentNode.rel8nName) {
      t.parent = t.d.parentNode.parentNode;
      t.parentRel8nName = t.d.parentNode.rel8nName;
      if (!t.parent || t.parentRel8n) {
        let emsg = `${lc} no parent/parentRel8n?`;
        console.error(emsg);
        alert(emsg)
        return;
      }
    } else if (t.d.parentNode.isMeta && t.d.parentNode.ibGib) {
      console.log("trashing in meta menu.")
      t.parent = t.d.parentNode;
      t.parentRel8nName = "ib^gib"; // meh, see if it works.
    } else {
      console.error("what up, trying to trash something without parent rel8n node and the parent is not a meta node either.")
    }

    t.ibScape.setBusy(t.d);
    t.ibScape.setBusy(t.parent);

    let msg = t.getMessage();
    t.ibScape.commandMgr.bus.send(msg, (successMsg) => {
      console.log(`TrashCommand successMsg: ${JSON.stringify(successMsg)}`)
      t.handleSubmitResponse(successMsg);
      if (t.parent.isMeta) {
        t.ibScape.removeNodeAndChildren(t.d);
      }
    }, (errorMsg) => {
      console.error(`${t.cmdName} command errored. Msg: ${JSON.stringify(errorMsg)}`);
      t.ibScape.clearBusy(t.d);
      t.ibScape.clearBusy(t.parent);
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
      parent_ib_gib: t.parent.ibGib,
      child_ib_gib:   t.d.ibGib,
      rel8n_name:    t.parentRel8nName,
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

    // t.ibScape.removeNodeAndChildren(t.d);
    // t.ibScape.clearBusy(t.d);
    // t.ibScape.clearBusy(t.parent);

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
      // console.log(`${t.cmdName} successMsg: ${JSON.stringify(successMsg)}`);
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
export class GetOysCommand extends CommandBase {
  constructor(ibScape, d, successCallback, errorCallback) {
    const cmdName = "getoys";
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
      oy_kind: t.d.oy_kind,
      oy_filter: t.d.oy_filter,
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
}

/** View comment or pic */
export class ViewDetailsCommand extends HtmlDetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "view";
    super(cmdName, ibScape, d);
  }

  getDetailsViewId() {
    return `ib-huh-details`;
  }

  init() {
    super.init();
    let t = this;

    t.ibScape.ibGibProvider.getIbGibJson(t.d.ibGib, ibGibJson => {
      if (!t.d.ibGibJson) { t.d.ibGibJson = ibGibJson; }

      if (ibHelper.isComment(ibGibJson)) {
        t.addCommentHtml();
      } else if (ibHelper.isImage(ibGibJson)) {
        // t.addImageHtml(ibGibJson)
        let imageUrl =
          t.ibScape.ibGibImageProvider.getFullImageUrl(t.d.ibGib);

        window.open(imageUrl,'_blank');
        t.close();
        t.closedEarly = true;
      } else {
        let emsg = `View command only implemented for images and comments. :-/`;
        console.error(emsg);
        alert(emsg);
      }
    });
  }

  addCommentHtml() {
    let t = this;

    let commentText = ibHelper.getDataText(t.d.ibGibJson);

    t.htmlDiv
      .append("div")
      .style("padding", "5px")
      // .style("font-family", "FontAwesome")
      // .style("font-size", "30px")
      .html(md.render(commentText));
    //   t.htmlDiv.append("div").html(md.render(huhText_IbGib));
  }
}

/** Download (pic only right now). */
export class DownloadDetailsCommand extends DetailsCommandBase {
  constructor(ibScape, d) {
    const cmdName = "download";
    super(cmdName, ibScape, d);
  }

  init() {
    let t = this;

    let initialText = "Loading... (slow connection maybe?)";
    d3.select("#download_form_filetype")
      .text(initialText);

    d3.select("#download_form_filename")
      .text(initialText);

    t.ibScape.getIbGibJson(t.d.ibGib, ibGibJson => {
      if (!t.d.ibGibJson) { t.d.ibGibJson = ibGibJson; }

      let imageUrl =
        t.ibScape.ibGibImageProvider.getFullImageUrl(t.d.ibGib, ibGibJson);
      let thumbnailUrl =
        t.ibScape.ibGibImageProvider.getThumbnailImageUrl(t.d.ibGib, ibGibJson);

      d3.select("#ib-download-thumbnail")
        .attr("src", thumbnailUrl);

      d3.select("#download_form_url")
        .text(imageUrl);

      let btn = d3.select("#download_form_submit_btn");
      btn
        .attr("href", imageUrl)
        .attr("download", "");

      if (!btn.node().onclick) {
        btn.node().onclick = () => {
          $("#download_form_filename")
            .unbind("input")
            .unbind("keypress");
          t.close();
        }
      }

      if (ibGibJson.data) {
        if (ibGibJson.data.content_type) {
          d3.select("#download_form_filetype")
            .text(ibGibJson.data.content_type);
        }
        if (ibGibJson.data.filename) {
          $("#download_form_filename")
            .val(ibGibJson.data.filename);
          btn
            .attr("download", ibGibJson.data.filename);
        }

        $("#download_form_filename")
          .on("input", () => {
            btn
              .attr("download", $("#download_form_filename").val() || ibGibJson.data.filename);
          })
          .on("keypress", e => {
            if (e.keyCode === 13) {
              btn.node().click();
            }
          });
      }

      $("#download_form_filename").focus().select();
    });
  }
}

/** Opens external link */
export class ExternalLinkCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "externallink";
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();
    let t = this;

    t.ibScape.ibGibProvider.getIbGibJson(t.d.ibGib, ibGibJson => {

      let url = ibHelper.getDataText(ibGibJson);
      if (url) {
        window.open(url,'_blank');
      } else {
        alert("Error opening external link... :-/");
      }
    });
  }
}

export class ZapCommand extends CommandBase {
  constructor(ibScape, d) {
    const cmdName = "zap";
    super(cmdName, ibScape, d);
  }

  exec() {
    super.exec();
    let t = this;
    t.ibScape.zap(t.d, /*callback*/ null);
  }
}
