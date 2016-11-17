import * as d3 from 'd3';
import * as d3text from 'd3-textwrap';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands } from '../d3params';
import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import * as ibHelper from '../services/ibgib-helper';


export class DynamicIbScapeMenu extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, ibScape, d, position) {
    super(graphDiv, svgId, config);
    let t = this;

    const menuRadius = 120;
    const menuDiam = 2 * menuRadius;
    const menuDivSize = menuDiam;

    let defaults = {
      background: {
        fill: "blue",
        opacity: 0.7,
        shape: "circle"
      },
      mouse: {
        dblClickMs: 50,
        longPressMs: 800
      },
      simulation: {
        velocityDecay: 0.07,
        chargeStrength: 0.02,
        chargeDistanceMin: 10,
        chargeDistanceMax: 10000,
        linkDistance: 22,
        collideDistance: 45,
      },
      node: {
        cursorType: "crosshair",
        baseRadiusSize: 11,
        defShapeFill: "pink",
        defBorderStroke: "darkgreen",
        defBorderStrokeWidth: "2px",
        image: {
          backgroundFill: "yellow"
        }
      },
      menu: {
        radius: 120,
        diam: menuDiam,
        size: menuDivSize,
        buttonRadius: 22,
        position: position,
        d: d
      }
    }
    t.config = $.extend({}, defaults, config || {});

    t.ibScape = ibScape;
  }

  init() {
    super.init();
    let t = this;

    console.log("t.config.menu.size: " + t.config.menu.size);
    d3.select(t.graphDiv)
      .style("top", 200 + "px")
      .style("left", 200 + "px")
      .attr("z-index", d3.select(t.ibScape.graphDiv).attr("z-index") + 100)
      .style('width', `${t.config.menu.size}px`)
      .style('height', `${t.config.menu.size}px`)
      .style("border-radius", "50%");

    t.open(t.config.menu.d);
  }

  open(d) {
    let t = this;

    let graph = t.getMenuCommandsJson(d);

    t.moveTo(t.config.menu.position); // temp

    for (var i = 0; i < graph.nodes.length; i++) {
      let cmd = graph.nodes[i];
      let newNode = {
        id: i,
        cmd: cmd
      };

      t.add([newNode], [], /*updateParentOrChild*/ true);
    }
  }

  handleNodeNormalClicked(d) {
    let t = this;
    console.log(`menu node clicked. d: ${JSON.stringify(d)}`);

    t.animateNodeBorder(d, /*node*/ null);

    t.execMenuCommand(t.ibScape.selectedDatum, d);
  }
  handleNodeLongClicked(d) {
    let t = this;
    console.log(`menu node longclicked. d: ${JSON.stringify(d)}`);

    t.animateNodeBorder(d, /*node*/ null);

    // t.detailsRefCount = t.detailsRefCount || 0;

    // let init = () => {
    //   t.detailsRefCount += 1;
    //   d3.select("#ib-scape-details").attr("z-index", 10000);
    //   $("#ib-help-details-text").text(d.description).attr("z-index", 10000);
    //   setTimeout(() => {
    //     t.cancelHelpDetails(/*force*/ false);
    //   }, 4000)
    // };
    //
    // t.ibScape.showDetails("help", init, /*keepMenuOpen*/ true);
  }
  handleNodeRawTouchstartOrMouseDown(d) {
    let t = this;

    t.animateNodeBorder(d, /*node*/ null);

    super.handleNodeRawTouchstartOrMouseDown(d);
  }

  close() {
    if (this.menuArea) { d3.select("#ib-d3-graph-menu-area").remove();
      delete this.menuArea;
    }
    if (this.svgGroup) { d3.select("#d3menuvis").remove();
      delete this.svgGroup;
    }

    d3.select("#ib-d3-graph-menu-div")
      .style("visibility", "hidden");
  }

  destroyStuff() {
    delete(this.ibScape);
  }

  execMenuCommand(dIbGib, dCommand) {
    if (dCommand.name !== "help") {
      this.cancelHelpDetails(/*force*/ true);
    }

    if ((dCommand.name === "view" || dCommand.name === "hide")) {
      this.execView(dIbGib)
    } else if (dCommand.name === "fork") {
      this.execFork(dIbGib)
    } else if (dCommand.name === "goto") {
      this.execGoto(dIbGib);
    } else if (dCommand.name === "help") {
      this.execHelp(dIbGib);
    } else if (dCommand.name === "comment") {
      this.execComment(dIbGib);
    } else if (dCommand.name === "pic") {
      this.execPic(dIbGib);
    } else if (dCommand.name === "fullscreen") {
      this.execFullscreen(dIbGib);
    } else if (dCommand.name === "link") {
      this.execLink(dIbGib);
    } else if (dCommand.name === "externallink") {
      this.execExternalLink(dIbGib);
    } else if (dCommand.name === "identemail") {
      this.execIdentEmail(dIbGib);
    } else if (dCommand.name === "info") {
      this.execInfo(dIbGib);
    } else if (dCommand.name === "query") {
      this.execQuery(dIbGib);
    } else if (dCommand.name === "refresh") {
      this.execRefresh(dIbGib);
    } else if (dCommand.name === "download") {
      this.execDownload(dIbGib);
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

  execHelp(dIbGib) {
    let init = () => {
      console.log("initializing help...");
      let text = "Hrmmm...you shouldn't be seeing this! This means that I " +
        "haven't included help for this yet. Let me know please :-O";

      if (dIbGib.ibgib === "ib^gib") {
        text = `These circles of ibGib - they will increase your smartnesses, fun-having, people-likening, and more, all while solving all of your problems and creating world peace and understanding. You can add pictures, links, comments, and more to them. Click one to bring up its menu which has a bunch of commands you can give. Long-click a command to see its description. Click the Spock Hand to get started. If you're a confused dummE or a nerd looking for more information, check out www.ibgib.com/huh. (Some statements here may be inaccurate or take an infinite amount of time to complete and/or explain.) God Bless.`;
      } else if (dIbGib.cat === "ib") {
        text = `This is your current ibGib. Right now, it's the center of your ibverse. Click the information (i) button to get more details about it. Spock hand to fork it, or add comments, pictures, links, and more.`;
      } else if (dIbGib.cat === "ancestor") {
        text = `This is an "ancestor" ibGib, like a parent or grandparent. Each time you "fork" a new ibGib, the src ibGib becomes its ancestor. For example, if you fork a RecipeGib -> WaffleGib, then the WaffleGib becomes a child of the RecipeGib.`
      } else if (dIbGib.cat === "past") {
        text = `This is a "past" version of your current ibGib. A past ibGib kinda like previous versions of a text document, whither you can 'undo'. Each time you mut8 an ibGib, either by adding/removing a comment or image, changing a comment, etc., you create a "new" version in time. ibGib retains all histories of all changes of all ibGib!`
      } else if (dIbGib.cat === "dna") {
        text = `Each ibGib is produced by an internal "dna" code, precisely as living organisms are. Each building block is itself an ibGib that you can navigate to, fork, etc. We can't dynamically build dna yet though (in the future of ibGib!)`;
      } else if (dIbGib.cat === "identity") {
        text = `This is an identity ibGib. It gives you information about who produced what ibGib. You can add layers of identities to "provide more identification", like showing someone your driver's license, your voter's card, club membership, etc. Each identity's ib should start with either "session" or "email". Session is an anonymous id and should be attached to each and every ibGib. Email ids show the email that was used to "log in" (but you can log in with multiple emails!). All authenticated identities should be "stamped" (the "gib" starts and ends with "ibGib", e.g. "ibGib_LETTERSandNUMBERS_ibGib").`;
      } else if (dIbGib.cat === "rel8n") {
        text = `This is a '${dIbGib.name}' rel8n node. All of its children are rel8ed to the current ibGib by this rel8n. One ibGib can have multiple rel8ns to any other ibGib. You can expand / collapse the rel8n to show / hide its children by either double-clicking or clicking and selecting the "view" button. Click help on the children to learn more about that rel8n.`;
      } else if (dIbGib.cat === "pic") {
        text = `This is a picture that you have uploaded! Viewing it in fullscreen will open the image in a new window or tab, depending on your browser preferences. Navigating to it will take you to the pic's ibGib itself. (We're working on an improved experience with adding comments, pictures, etc.)`;
      } else if (dIbGib.cat === "comment") {
        let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
        let commentText = ibHelper.getDataText(ibGibJson);
        text = `This is a comment. It contains text...umm...you can comment on just about anything. (We're working on an improved experience with adding comments, pictures, etc.) This particular comment's text is: "${commentText}"`;
      } else if (dIbGib.cat === "link") {
        let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
        let linkText = ibHelper.getDataText(ibGibJson);
        text = `This is a hyperlink to somewhere outside of ibGib. If you want to navigate to the external link, then choose the open external link command. If you want to goto the link's ibGib, then click the goto navigation. (We're working on an improved experience with adding comments, pictures, etc.) \n\nLink: "${linkText}"`;
      } else {
        text = `This ibGib is rel8d to the current ibGib via ${dIbGib.cat}. Click the information button to get more details about it. You can also navigate to it, expand / collapse any children, fork it, add comments, pictures, links, and more.`;
      }

      $("#ib-help-details-text").text(text);
    };

    this.ibScape.showDetails("help", init);
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

  execInfo(dIbGib) {
    let t = this;
    let init = () => {
      d3.select("#info_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);

      let container = d3.select("#ib-info-details-container");
      container.each(function() {
        while (this.firstChild) {
          this.removeChild(this.firstChild);
        }
      });

      t.ibScape.getIbGibJson(dIbGib.ibgib, ibGibJson => {

        let text = JSON.stringify(ibGibJson, null, 2);
        // Formats new lines in json.data values. It's still a hack just
        // showing the JSON but it's an improvement.
        // Thanks SO (for the implementation sort of) http://stackoverflow.com/questions/42068/how-do-i-handle-newlines-in-json
        text = text.replace(/\\n/g, "\n").replace(/\\r/g, "").replace(/\\t/g, "\t");
        container
          .append("pre")
          .text(text);

        t.ibScape.repositionDetails();
      });
    };
    this.ibScape.showDetails("info", init);
  }

  execQuery(dIbGib) {
    let init = () => {
      d3.select("#query_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("query", init);
    $("#query_form_data_search_ib").focus();
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

  /**
   * Builds the json that d3 requires for showing the menu to the user.
   * This menu is what shows the commands for the user to do, e.g. "fork",
   * "merge", etc.
   */
  getMenuCommandsJson(d) {
    // TODO: ib-scape.js getMenuCommandsJson: When we have client-side dynamicism (prefs, whatever), then we need to change this to take that into account when building the popup menu.
    let commands = [];

    if (d.cat === "rel8n") {
      commands = ["help", "view"];
    } else if (d.ibgib && d.ibgib === "ib^gib") {
      commands = ["help", "fork", "goto", "identemail", "fullscreen", "query"];
    } else if (d.cat === "ib") {
      commands = ["help", "view", "fork", "comment", "pic", "link", "info", "refresh"];
    } else {
      commands = ["help", "view", "fork", "goto", "comment", "pic", "link", "info", "refresh"];
    }

    if (d.render && d.render === "image") {
      commands.push("fullscreen");
      commands.push("download");
    }
    if (d.cat === "link") {
      commands.push("externallink");
    }

    let nodes = commands.map(cmdName => d3MenuCommands.filter(cmd => cmd.name === cmdName)[0]);
    return {
      "nodes": nodes
    };
  }

  moveTo(position) {
    let transition =
      d3.transition()
        .duration(150)
        .ease(d3.easeLinear);
    d3.select("#ib-d3-graph-menu-div")
      .transition(transition)
        .style("left", position.x + "px")
        .style("top", position.y + "px")
        .style("visibility", null)
        .attr("z-index", 1000);
  }

  cancelHelpDetails(force) {
    this.detailsRefCount -= 1;

    if (force || this.detailsRefCount <= 0) {
      this.detailsRefCount = 0;
      this.ibScape.cancelDetails();
    }
  }

  getForceCenter() {
    let t = this;
    return d3.forceCenter(t.config.menu.radius, t.config.menu.radius);
  }


  initSimulation() {
    let t = this;

    // t.menuSimulation = d3.forceSimulation()
    //     .velocityDecay(0.07)
    //     .force("x", d3.forceX().strength(0.02))
    //     .force("y", d3.forceY().strength(0.02))
    //     .force("center", d3.forceCenter(t.menuRadius, t.menuRadius))
    //     .force("collide",
    //            d3.forceCollide().radius(t.menuButtonRadius).iterations(2));

    t.simulation =
        d3.forceSimulation()
          .velocityDecay(t.getVelocityDecay())
          .force("x", d3.forceX().strength(0.02))
          .force("y", d3.forceY().strength(0.02))
          .force("center", t.getForceCenter())
          .force("collide", d3.forceCollide().radius(t.config.menu.buttonRadius).iterations(2));
  }

  updateSimulation() {
    let t = this;

    // Attach the nodes and links to the simulation.
    t.simulation
      .nodes(t.graphData.nodes)
      .on("tick", () => t.handleTicked())
      .on("end", () => t.handleSimulationEnd());
    // t.simulation
    //   .force("link")
    //   .links(t.graphData.links);
  }

  getNodeShapeRadius(d) { return this.config.menu.buttonRadius; }
}
