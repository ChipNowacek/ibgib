import * as d3 from 'd3';
import * as d3text from 'd3-textwrap';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3BoringRel8ns, d3RequireExpandLevel2, d3MenuCommands } from '../d3params';
import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';

import * as commands from '../services/commanding/commands';
import { CommandManager } from '../services/commanding/command-manager';
import * as ibHelper from '../services/ibgib-helper';
import * as ibAuthz from '../services/ibgib-authz';

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
        linkDistance: 1,
      },
      node: {
        cursorType: "pointer",
        baseRadiusSize: 20,
        defShapeFill: "pink",
        defBorderStroke: "darkgreen",
        defBorderStrokeWidth: "2px",
        label: {
          fontFamily: "FontAwesome",
          fontStroke: "darkgreen",
          fontFill: "darkgreen",
          fontSize: "38px",
          fontOffset: 14
        },
        image: {
          backgroundFill: "yellow"
        }
      },
      menu: {
        radius: 120,
        diam: menuDiam,
        size: menuDivSize,
        buttonRadius: 28,
        position: position,
        d: d // why in the world did I do this?
      }
    }
    t.config = $.extend({}, defaults, config || {});

    t.ibScape = ibScape;
    t.d = d;
    t.commandMgr = t.ibScape.commandMgr;
  }

  init() {
    super.init();
    let t = this;

    console.log("t.config.menu.size: " + t.config.menu.size);
    d3.select(t.graphDiv)
      .style("top", 200 + "px")
      .style("left", 200 + "px")
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
        cmd: cmd,
        virtualId: ibHelper.getRandomString(),
        type: "cmd"
      };

      t.add([newNode], [], /*updateParentOrChild*/ true);
    }
  }

  handleNodeNormalClicked(d) {
    let t = this;
    console.log(`menu node clicked. d: ${JSON.stringify(d)}`);

    t.animateNodeBorder(d, /*node*/ null);

    t.commandMgr.exec(t.d, d.cmd);
    // t.execMenuCommand(t.ibScape.selectedDatum, d);
  }
  handleNodeLongClicked(d) {
    let t = this;
    console.log(`menu node longclicked. d: ${JSON.stringify(d)}`);

    t.animateNodeBorder(d, /*node*/ null);
    t.ibScape.commandMgr.exec(d, d3MenuCommands.filter(c => c.name === "huh")[0]);

  }
  handleNodeRawTouchstartOrMouseDown(d) {
    let t = this;

    t.animateNodeBorder(d, /*node*/ null);

    super.handleNodeRawTouchstartOrMouseDown(d);
  }

  close() {
    let t = this;

    if (t.currentDetails) { t.currentDetails.close(); delete t.currentDetails; }

    if (t.ibScape) { delete t.ibScape; }

    d3.select("#ib-d3-graph-menu-div")
      .style("visibility", "hidden");
  }

  show() {
    let t = this;
    d3.select(t.graphDiv).classed("ib-hidden", false);
  }

  hide() {
    let t = this;
    d3.select(t.graphDiv).classed("ib-hidden", true);
  }

  /**
   * Builds the json that d3 requires for showing the menu to the user.
   * This menu is what shows the commands for the user to do, e.g. "fork",
   * "merge", etc.
   */
  getMenuCommandsJson(d) {
    let t = this;

    // TODO: ib-scape.js getMenuCommandsJson: When we have client-side dynamicism (prefs, whatever), then we need to change this to take that into account when building the popup menu.
    let commands;

    if (d.virtualId) {
      // Virtual ibGib
      commands = ["zap"];
    } else {
      // Concrete ibGib
      if (d.ibGib && d.ibGib === "ib^gib") {
        commands = [/*"help", */"fork", "goto", "identemail", "query"];
      } else {
        commands = [/*"help", *//*"view",*/ "fork", "goto", "comment", "pic", "link", "info", "refresh"];
      }

      if (ibHelper.isImage(d.ibGibJson) || d.render === "image") {
        commands.push("view");
        commands.push("download");
      }

      if (ibHelper.isLink(d.ibGibJson) || d.render === "link") {
        commands.push("externallink");
      }

      if (ibHelper.isComment(d.ibGibJson)) {
        commands.push("view");

        if (ibAuthz.isAuthorizedForMut8OrRel8(d.ibGibJson, t.ibScape.currentIdentityIbGibs)) {
          commands.push("mut8comment");
        }
      }
    }


    let nodes = commands.map(cmdName => d3MenuCommands.filter(cmd => cmd.name === cmdName)[0]);
    return {
      "nodes": nodes
    };
  }

  moveTo(position) {

    let t = this;

    let transition =
      d3.transition()
        .duration(150)
        .ease(d3.easeLinear);
    d3.select(t.graphDiv)
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

  // updateNodeLabels() {
  //   let t = this;
  //
  //   t.graphNodeLabels =
  //     t.graphNodesEnter
  //       .append("text")
  //       .attr("id", d => t.getNodeLabelId(d))
  //       .attr("font-size", `10px`)
  //       .attr("text-anchor", "middle")
  //       .text(d => t.getNodeLabelText(d));
  //   t.graphNodeLabels
  //     .append("title")
  //     .text(d => t.getNodeTitle(d));
  // }

  getNodeTitle(d) { return d.cmd.description || d.title || d.id || ""; }
  getNodeLabelText(d) { return d.cmd.icon || d.label || d.title || d.id; }
  getNodeShapeFill(d) { return d.cmd.color || this.config.node.defShapeFill; }
}
