import * as d3 from 'd3';

import * as commands from './commands';
import { CommandBus } from './command-bus';

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
      case "huh":
        t.ibScape.currentCmd = t.getCommand_Huh(dIbGib);
        break;
      case "fork":
        t.ibScape.currentCmd = t.getCommand_Fork(dIbGib);
        break;
      case "comment":
        t.ibScape.currentCmd = t.getCommand_Comment(dIbGib);
        break;
      case "mut8comment":
        t.ibScape.currentCmd = t.getCommand_Mut8Comment(dIbGib);
        break;
      case "link":
        t.ibScape.currentCmd = t.getCommand_Link(dIbGib);
        break;
      case "identemail":
        t.ibScape.currentCmd = t.getCommand_IdentEmail(dIbGib);
        break;
      case "unidentemail":
        t.ibScape.currentCmd = t.getCommand_UnIdentEmail(dIbGib);
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
      case "ack":
        t.ibScape.currentCmd = t.getCommand_Ack(dIbGib);
        break;
      case "view":
        t.ibScape.currentCmd = t.getCommand_View(dIbGib);
        break;
      case "download":
        t.ibScape.currentCmd = t.getCommand_Download(dIbGib);
        break;
      case "externallink":
        t.ibScape.currentCmd = t.getCommand_ExternalLink(dIbGib);
        break;
      case "zap":
        t.ibScape.currentCmd = t.getCommand_Zap(dIbGib);
        break;
      case "tag":
        t.ibScape.currentCmd = t.getCommand_Tag(dIbGib);
        break;
      default:
        console.error(`unknown cmdName: ${cmdName}`);
    }

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
      case "mut8comment":
        return t.getCommand_Mut8Comment(dIbGib.rel8nSrc);
        break;
      case "pic":
        return t.getCommand_Pic(dIbGib.rel8nSrc);
        break;
      case "link":
        return t.getCommand_Link(dIbGib.rel8nSrc);
        break;
      default:
        throw new Error(`Unknown rel8n to add: ${dIbGib.rel8nName}`);
    }
  }

  getCommand_Goto(dIbGib) {
    return new commands.GotoCommand(this.ibScape, dIbGib);
  }
  getCommand_Info(dIbGib) {
    return new commands.InfoDetailsCommand(this.ibScape, dIbGib);
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
  getCommand_Mut8Comment(dIbGib) {
    return new commands.Mut8CommentDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Link(dIbGib) {
    return new commands.LinkDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_IdentEmail(dIbGib) {
    return new commands.IdentEmailDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_UnIdentEmail(dIbGib) {
    return new commands.UnIdentEmailDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Pic(dIbGib) {
    return new commands.PicDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Refresh(dIbGib) {
    return new commands.RefreshCommand(this.ibScape, dIbGib);
  }
  getCommand_Ack(dIbGib) {
    return new commands.AckCommand(this.ibScape, dIbGib);
  }
  getCommand_View(dIbGib) {
    return new commands.ViewDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_Download(dIbGib) {
    return new commands.DownloadDetailsCommand(this.ibScape, dIbGib);
  }
  getCommand_ExternalLink(dIbGib) {
    return new commands.ExternalLinkCommand(this.ibScape, dIbGib);
  }
  getCommand_Zap(dIbGib) {
    return new commands.ZapCommand(this.ibScape, dIbGib);
  }
  getCommand_Tag(dIbGib) {
    return new commands.TagDetailsCommand(this.ibScape, dIbGib);
  }
}
