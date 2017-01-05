import * as d3 from 'd3';

import * as commands from './commands';
import { CommandBus } from './command-bus';
// import * as ibHelper from '../services/ibgib-helper';

export class CommandManager {
  constructor(ibScape, ibGibSocketManager) {
    let t = this;

    t.ibScape = ibScape;
    t.ibGibSocketManager = ibGibSocketManager;
    t.bus = new CommandBus(ibGibSocketManager);
  }

  init() {
    this.bus.connect();
  }

  destroy() {
    let t = this;
    if (t.bus) { t.bus.disconnect(); delete t.bus; }
  }

  exec(dIbGib, dCommand) {
    let t = this;
    let cmdName = dCommand.name;

    if (t.ibScape.currentCmd) {
      if (t.ibScape.currentCmd.close) {
        t.ibScape.currentCmd.close();
      }
      delete t.ibScape.currentCmd;
    }

    switch (cmdName) {
      case "add":
        let blah = dIbGib;
        if (dIbGib.type === "rel8n") {
          // debugger;
          t.ibScape.currentCmd = t.getCommand_rel8nAdd(dIbGib);
        } else {
          console.error("unknown cmd add non-rel8n");
        }
        break;
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
        t.ibScape.currentCmd = t.getCommand_Huh(dIbGib);
        break;
      case "fork":
        t.ibScape.currentCmd = t.getCommand_Fork(dIbGib);
        break;
      case "comment":
        t.ibScape.currentCmd = t.getCommand_Comment(dIbGib);
        break;
      case "identemail":
        t.ibScape.currentCmd = t.getCommand_IdentEmail(dIbGib);
        break;
      case "pic":
        t.ibScape.currentCmd = t.getCommand_Pic(dIbGib);
        break;
      case "goto":
        t.ibScape.currentCmd = t.getCommand_Goto(dIbGib);
        break;
      case "refresh":
        t.ibScape.currentCmd = t.getCommand_Refresh(dIbGib);
        break;
      case "allow":
        t.ibScape.currentCmd = t.getCommand_Allow(dIbGib);
        break;
      default:
        console.error(`unknown cmdName: ${cmdName}`);
    }

    //
    // if ((cmdName === "view" || cmdName === "hide")) {
    //   t.execView(dIbGib)
    // } else if (cmdName === "goto") {
    //   t.execGoto(dIbGib);
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
  getCommand_rel8nAdd(dIbGib) {
    let t = this;
    switch (dIbGib.rel8nName) {
      case "comment":
        return t.getCommand_Comment(dIbGib.rel8nSrc);
        break;
      case "pic":
        return t.getCommand_Pic(dIbGib.rel8nSrc);
        break;
      default:
        throw new Error(`Unknown rel8n to add: ${dIbGib.rel8nName}`);
    }
  }
  // execView(dIbGib) {
  //   this.ibScape.toggleExpandNode(dIbGib);
  //   this.ibScape.destroyStuff();
  //   this.ibScape.update(null);
  // }
  // execFork(dIbGib) {
  //   let init = () => {
  //     d3.select("#fork_form_data_src_ib_gib")
  //       .attr("value", dIbGib.ibgib);
  //   };
  //   this.ibScape.showDetails("fork", init);
  //   $("#fork_form_data_dest_ib").focus();
  // }
  getCommand_Goto(dIbGib) {
    return new commands.GotoCommand(this.ibScape, dIbGib);
  }
  getCommand_Info(dIbGib) {
    return new commands.InfoDetailsCommand(this.ibScape, dIbGib);
  }
  // execPic(dIbGib) {
  //   let init = () => {
  //     d3.select("#pic_form_data_src_ib_gib")
  //       .attr("value", dIbGib.ibgib);
  //   };
  //   this.ibScape.showDetails("pic", init);
  //   $("#pic_form_data_file").focus();
  // }
  // execLink(dIbGib) {
  //   let init = () => {
  //     d3.select("#link_form_data_src_ib_gib")
  //       .attr("value", dIbGib.ibgib);
  //   };
  //   this.ibScape.showDetails("link", init);
  //   $("#link_form_data_text").focus();
  // }
  // execFullscreen(dIbGib) {
  //   if (dIbGib.ibgib === "ib^gib") {
  //     let id = this.ibScape.graphDiv.id;
  //     this.ibScape.toggleFullScreen(`#${id}`);
  //   } else {
  //     this.ibScape.openImage(dIbGib.ibgib);
  //   }
  // }
  // execExternalLink(dIbGib) {
  //   let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
  //   let url = ibHelper.getDataText(ibGibJson);
  //   if (url) {
  //     window.open(url,'_blank');
  //   } else {
  //     alert("Error opening external link... :-/");
  //   }
  // }
  // execIdentEmail(dIbGib) {
  //   let init = () => {
  //     d3.select("#ident_form_data_src_ib_gib")
  //       .attr("value", dIbGib.ibgib);
  //   };
  //   this.ibScape.showDetails("ident", init);
  //   $("#ident_form_data_text").focus();
  // }

  getCommand_Help(dIbGib) {
    return new commands.HelpDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Huh(dIbGib) {
    return new commands.HuhDetailsCommand(this.ibScape, dIbGib);
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
  getCommand_IdentEmail(dIbGib) {
    return new commands.IdentEmailDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Pic(dIbGib) {
    return new commands.PicDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Refresh(dIbGib) {
    return new commands.RefreshCommand(this.ibScape, dIbGib);
  }
  getCommand_Allow(dIbGib) {
    return new commands.AllowCommand(this.ibScape, dIbGib);
  }
  // execRefresh(dIbGib) {
  //   location.href = `/ibgib/${dIbGib.ibgib}?latest=true`
  // }
  // execDownload(dIbGib) {
  //   let t = this;
  //   let imageUrl =
  //     t.ibScape.ibGibImageProvider.getFullImageUrl(dIbGib.ibgib);
  //
  //   let init = () => {
  //     let btn = d3.select("#download_form_submit_btn");
  //     btn
  //       .attr("href", imageUrl)
  //       .attr("download", "");
  //
  //     if (!btn.node().onclick) {
  //       btn.node().onclick = () => {
  //         t.ibScape.cancelDetails();
  //         t.ibScape.clearSelectedNode();
  //       }
  //     }
  //
  //     d3.select("#download_form_url")
  //       .text(imageUrl);
  //
  //     d3.select("#download_form_filetype")
  //       .text("not set");
  //
  //     d3.select("#download_form_filename")
  //       .text("not set");
  //
  //     t.ibScape.repositionDetails();
  //
  //     t.ibScape.getIbGibJson(dIbGib.ibgib, (ibGibJson) => {
  //       if (ibGibJson.data) {
  //         if (ibGibJson.data.content_type) {
  //           d3.select("#download_form_filetype")
  //             .text(ibGibJson.data.content_type);
  //         }
  //         if (ibGibJson.data.filename) {
  //           d3.select("#download_form_filename")
  //             .text(ibGibJson.data.filename);
  //           btn
  //             .attr("download", ibGibJson.data.filename);
  //         }
  //       }
  //     });
  //   };
  //
  //   t.ibScape.showDetails("download", init);
  //
  //   $("#download_form_submit_btn").focus();
  // }
}
