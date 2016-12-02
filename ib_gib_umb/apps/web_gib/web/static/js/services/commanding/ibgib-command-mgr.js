import * as d3 from 'd3';

import * as commands from './commands';
// import * as ibHelper from '../services/ibgib-helper';

export class IbGibCommandMgr {
  constructor(ibScape) {
    this.ibScape = ibScape;
  }

  exec(dIbGib, dCommand) {
    let t = this;
    let cmdName = dCommand.name;

    if (t.ibScape.currentCmd) {
      t.ibScape.currentCmd.close();
    }

    // if (cmdName !== "help") {
    //   this.cancelHelpDetails(/*force*/ true);
    // }
    switch (cmdName) {
      case "info":
        t.ibScape.currentCmd = t.getCommand_Info(dIbGib);
        break;
      case "query":
        t.ibScape.currentCmd = t.getCommand_Query(dIbGib);
        break;
      case "help":
        t.ibScape.currentCmd = t.getCommand_Help(dIbGib);
        break;
      case "huh":
        t.ibScape.currentCmd = t.getCommand_Help(dIbGib);
        break;
      case "fork":
        t.ibScape.currentCmd = t.getCommand_Fork(dIbGib);
        break;
      case "comment":
        t.ibScape.currentCmd = t.getCommand_Comment(dIbGib);
        break;
      default:
        console.error(`unknown cmdName: ${cmdName}`);
    }
    //
    // if ((cmdName === "view" || cmdName === "hide")) {
    //   t.execView(dIbGib)
    // } else if (cmdName === "fork") {
    //   t.execFork(dIbGib)
    // } else if (cmdName === "goto") {
    //   t.execGoto(dIbGib);
    // } else if (cmdName === "help") {
    //   t.ibScape.currentCmd = t.getCommand_Help(dIbGib);
    //   // t.execHelp(dIbGib);
    // } else if (cmdName === "comment") {
    //   t.execComment(dIbGib);
    // } else if (cmdName === "pic") {
    //   t.execPic(dIbGib);
    // } else if (cmdName === "fullscreen") {
    //   t.execFullscreen(dIbGib);
    // } else if (cmdName === "link") {
    //   t.execLink(dIbGib);
    // } else if (cmdName === "externallink") {
    //   t.execExternalLink(dIbGib);
    // } else if (cmdName === "identemail") {
    //   t.execIdentEmail(dIbGib);
    // } else if (cmdName === "info") {
    //   t.ibScape.currentCmd = t.getCommand_Info(dIbGib);
    // } else if (cmdName === "query") {
    //   t.ibScape.currentCmd = t.getCommand_Query(dIbGib);
    //   // t.execQuery(dIbGib);
    // } else if (cmdName === "refresh") {
    //   t.execRefresh(dIbGib);
    // } else if (cmdName === "download") {
    //   t.execDownload(dIbGib);
    // }

    if (t.ibScape.currentCmd) {
      t.ibScape.currentCmd.exec();
      t.ibScape.clearSelectedNode();
    }
  }
  execView(dIbGib) {
    this.ibScape.toggleExpandNode(dIbGib);
    this.ibScape.destroyStuff();
    this.ibScape.update(null);
  }
  execFork(dIbGib) {
    let init = () => {
      d3.select("#fork_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("fork", init);
    $("#fork_form_data_dest_ib").focus();
  }
  execGoto(dIbGib) {
    location.href = `/ibgib/${dIbGib.ibgib}`
  }
  getCommand_Info(dIbGib) {
    return new commands.InfoDetailsCommand(this.ibScape, dIbGib);

    // let init = () => {
    //   console.log("initializing help...");
    //   let text = "Hrmmm...you shouldn't be seeing this! This means that I " +
    //     "haven't included help for this yet. Let me know please :-O";
    //
    //   if (dIbGib.ibgib === "ib^gib") {
    //     text = `These circles of ibGib - they will increase your smartnesses, fun-having, people-likening, and more, all while solving all of your problems and creating world peace and understanding. You can add pictures, links, comments, and more to them. Click one to bring up its menu which has a bunch of commands you can give. Long-click a command to see its description. Click the Spock Hand to get started. If you're a confused dummE or a nerd looking for more information, check out www.ibgib.com/huh. (Some statements here may be inaccurate or take an infinite amount of time to complete and/or explain.) God Bless.`;
    //   } else if (dIbGib.cat === "ib") {
    //     text = `This is your current ibGib. Right now, it's the center of your ibverse. Click the information (i) button to get more details about it. Spock hand to fork it, or add comments, pictures, links, and more.`;
    //   } else if (dIbGib.cat === "ancestor") {
    //     text = `This is an "ancestor" ibGib, like a parent or grandparent. Each time you "fork" a new ibGib, the src ibGib becomes its ancestor. For example, if you fork a RecipeGib -> WaffleGib, then the WaffleGib becomes a child of the RecipeGib.`
    //   } else if (dIbGib.cat === "past") {
    //     text = `This is a "past" version of your current ibGib. A past ibGib kinda like previous versions of a text document, whither you can 'undo'. Each time you mut8 an ibGib, either by adding/removing a comment or image, changing a comment, etc., you create a "new" version in time. ibGib retains all histories of all changes of all ibGib!`
    //   } else if (dIbGib.cat === "dna") {
    //     text = `Each ibGib is produced by an internal "dna" code, precisely as living organisms are. Each building block is itself an ibGib that you can navigate to, fork, etc. We can't dynamically build dna yet though (in the future of ibGib!)`;
    //   } else if (dIbGib.cat === "identity") {
    //     text = `This is an identity ibGib. It gives you information about who produced what ibGib. You can add layers of identities to "provide more identification", like showing someone your driver's license, your voter's card, club membership, etc. Each identity's ib should start with either "session" or "email". Session is an anonymous id and should be attached to each and every ibGib. Email ids show the email that was used to "log in" (but you can log in with multiple emails!). All authenticated identities should be "stamped" (the "gib" starts and ends with "ibGib", e.g. "ibGib_LETTERSandNUMBERS_ibGib").`;
    //   } else if (dIbGib.cat === "rel8n") {
    //     text = `This is a '${dIbGib.name}' rel8n node. All of its children are rel8ed to the current ibGib by this rel8n. One ibGib can have multiple rel8ns to any other ibGib. You can expand / collapse the rel8n to show / hide its children by either double-clicking or clicking and selecting the "view" button. Click help on the children to learn more about that rel8n.`;
    //   } else if (dIbGib.cat === "pic") {
    //     text = `This is a picture that you have uploaded! Viewing it in fullscreen will open the image in a new window or tab, depending on your browser preferences. Navigating to it will take you to the pic's ibGib itself. (We're working on an improved experience with adding comments, pictures, etc.)`;
    //   } else if (dIbGib.cat === "comment") {
    //     let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
    //     let commentText = ibHelper.getDataText(ibGibJson);
    //     text = `This is a comment. It contains text...umm...you can comment on just about anything. (We're working on an improved experience with adding comments, pictures, etc.) This particular comment's text is: "${commentText}"`;
    //   } else if (dIbGib.cat === "link") {
    //     let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
    //     let linkText = ibHelper.getDataText(ibGibJson);
    //     text = `This is a hyperlink to somewhere outside of ibGib. If you want to navigate to the external link, then choose the open external link command. If you want to goto the link's ibGib, then click the goto navigation. (We're working on an improved experience with adding comments, pictures, etc.) \n\nLink: "${linkText}"`;
    //   } else {
    //     text = `This ibGib is rel8d to the current ibGib via ${dIbGib.cat}. Click the information button to get more details about it. You can also navigate to it, expand / collapse any children, fork it, add comments, pictures, links, and more.`;
    //   }
    //
    //   $("#ib-help-details-text").text(text);
    // };
    //
    // this.ibScape.showDetails("help", init);
  }
  execComment(dIbGib) {
    let init = () => {
      d3.select("#comment_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("comment", init);
    $("#comment_form_data_text").focus();
  }
  execPic(dIbGib) {
    let init = () => {
      d3.select("#pic_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("pic", init);
    $("#pic_form_data_file").focus();
  }
  execLink(dIbGib) {
    let init = () => {
      d3.select("#link_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("link", init);
    $("#link_form_data_text").focus();
  }
  execFullscreen(dIbGib) {
    if (dIbGib.ibgib === "ib^gib") {
      let id = this.ibScape.graphDiv.id;
      this.ibScape.toggleFullScreen(`#${id}`);
    } else {
      this.ibScape.openImage(dIbGib.ibgib);
    }
  }
  execExternalLink(dIbGib) {
    let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
    let url = ibHelper.getDataText(ibGibJson);
    if (url) {
      window.open(url,'_blank');
    } else {
      alert("Error opening external link... :-/");
    }
  }
  execIdentEmail(dIbGib) {
    let init = () => {
      d3.select("#ident_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("ident", init);
    $("#ident_form_data_text").focus();
  }
  getCommand_Help(dIbGib) {
    return new commands.HelpDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Query(dIbGib) {
    return new commands.QueryDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Fork(dIbGib) {
    return new commands.ForkDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Comment(dIbGib) {
    return new commands.CommentDetailsCommand(this.ibScape, dIbGib);
  }
  execRefresh(dIbGib) {
    location.href = `/ibgib/${dIbGib.ibgib}?latest=true`
  }
  execDownload(dIbGib) {
    let t = this;
    let imageUrl =
      t.ibScape.ibGibImageProvider.getFullImageUrl(dIbGib.ibgib);

    let init = () => {
      let btn = d3.select("#download_form_submit_btn");
      btn
        .attr("href", imageUrl)
        .attr("download", "");

      if (!btn.node().onclick) {
        btn.node().onclick = () => {
          t.ibScape.cancelDetails();
          t.ibScape.clearSelectedNode();
        }
      }

      d3.select("#download_form_url")
        .text(imageUrl);

      d3.select("#download_form_filetype")
        .text("not set");

      d3.select("#download_form_filename")
        .text("not set");

      t.ibScape.repositionDetails();

      t.ibScape.getIbGibJson(dIbGib.ibgib, (ibGibJson) => {
        if (ibGibJson.data) {
          if (ibGibJson.data.content_type) {
            d3.select("#download_form_filetype")
              .text(ibGibJson.data.content_type);
          }
          if (ibGibJson.data.filename) {
            d3.select("#download_form_filename")
              .text(ibGibJson.data.filename);
            btn
              .attr("download", ibGibJson.data.filename);
          }
        }
      });
    };

    t.ibScape.showDetails("download", init);

    $("#download_form_submit_btn").focus();
  }


}
