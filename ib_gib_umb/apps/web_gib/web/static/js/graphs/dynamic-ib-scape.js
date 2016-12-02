import * as d3 from 'd3';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands, d3Rel8nIcons } from '../d3params';

import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import { DynamicIbScapeMenu } from './dynamic-ib-scape-menu';
import * as ibHelper from '../services/ibgib-helper';
import { IbGibCommandMgr } from '../services/commanding/ibgib-command-mgr';

export class DynamicIbScape extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, baseJsonPath, ibGibCache, ibGibImageProvider, sourceIbGib, ibGibSocketAndChannels) {
    super(graphDiv, svgId, {});
    let t = this;

    t.baseJsonPath = baseJsonPath;
    t.ibGibCache = ibGibCache;
    t.ibGibImageProvider = ibGibImageProvider;
    t.commandMgr = new IbGibCommandMgr(t);
    t.ibGibSocketAndChannels = ibGibSocketAndChannels;

    let defaults = {
      background: {
        fill: "green",
        opacity: 1,
        shape: "rect"
      },
      mouse: {
        dblClickMs: 300,
        longPressMs: 750
      },
      simulation: {
        velocityDecay: 0.85,
        chargeStrength: -35,
        chargeDistanceMin: 10,
        chargeDistanceMax: 10000,
        linkDistance: 75,
      },
      node: {
        cursorType: "crosshair",
        baseRadiusSize: 85,
        defShapeFill: "lightblue",
        defBorderStroke: "darkgreen",
        defBorderStrokeWidth: "2px",
        label: {
          fontFamily: "Times New Roman",
          fontStroke: "blue",
          fontFill: "darkgreen",
          fontSize: "25px",
          fontOffset: 8
        },
        image: {
          backgroundFill: "purple"
        }
      }
    }
    t.config = $.extend({}, defaults, config || {});

    t.sourceIbGib = sourceIbGib || "ib^gib";
  }

  init() {
    super.init();
    let t = this;

    console.log("init");

    t.initNoScrollHtmlAndBody();
    t.initCloseDetails();
    t.initResize();
    let root = t.addRoot();
    t.addSourceIbGib(root);
  }

  initNoScrollHtmlAndBody() {
    d3.select("html")
      .style("overflow-x", "hidden")
      .style("overflow-y", "hidden");

    d3.select("body")
      .style("overflow-x", "hidden")
      .style("overflow-y", "hidden")
      .style("position", "relative");
  }

  initCloseDetails() {
    let t = this;
    d3.select(t.graphDiv)
      .selectAll("[name=ib-scape-details-close-btn]")
      .on("click", () => {
        if (t.currentCmd) { t.currentCmd.close(); }
      });
  }

  initResize() {
    let t = this;

    if (!window.onresize) {
      window.onresize = () => {
        const debounceMs = 250;

        if (t.resizeTimer) { clearTimeout(t.resizeTimer); }

        t.resizeTimer = setTimeout(() => {
          t.handleResize();
        }, debounceMs);
      };

    }
  }

  getRoot() {
    let t = this;

    if (t.graphData && t.graphData.nodes && t.graphData.nodes.length > 0) {
      let rootId = t.getUniqueId("root");
      let rootArray = t.graphData.nodes.filter(n => n.id === rootId);
      return rootArray.length === 1 ? rootArray[0] : null;
    } else {
      return null;
    }
  }

  /** Adds the root */
  addRoot() {
    let t = this;
    let rootNode = t.getRoot();

    // Only add the root if doesn't already exist.
    if (!rootNode) {
      let rootId = t.getUniqueId("root"),
          rootType = "ibGib",
          rootIbGib = "ib^gib",
          rootShape = "circle",
          autoZap = false,
          fadeTimeoutMs = 3000,
          rootPulseMs = 2000;

      if (t.sourceIbGib && t.sourceIbGib !== "ib^gib") {
        fadeTimeoutMs = 0;
        autoZap = true;

        // we have a source ibGib, so don't blink the root
        rootNode = t.addVirtualNode(rootId, rootType, rootIbGib, /*srcNode*/ null, rootShape, autoZap, fadeTimeoutMs, /*cmd*/ null, /*title*/ null, /*label*/ null, /*startPos*/ null);
      } else {
        // we have NO source ibGib, so blink the root for new users.
        rootNode = t.addVirtualNode(rootId, rootType, rootIbGib, /*srcNode*/ null, rootShape, autoZap, fadeTimeoutMs, /*cmd*/ null, /*title*/ null, /*label*/ null, /*startPos*/ null);

        // Call recursively. If it was succesfully added and subsequently
        // zapped by the user, then we won't be at this point.
        setTimeout(() => t.addRoot(), fadeTimeoutMs + rootPulseMs);
      }
    }

    return rootNode;
  }

  addSourceIbGib(root) {
    let t = this;

    if (t.sourceIbGib && t.sourceIbGib !== "ib^gib") {
      let { ib } = ibHelper.getIbAndGib(t.sourceIbGib),
          srcId = t.getUniqueId("src"),
          srcType = "ibGib",
          srcShape = t.getNodeShapeFromIb(ib),
          autoZap = true,
          fadeTimeoutMs = 0;

      // I'm overloading the term "source" here. the "sourceIbGib"
      // is the current ibGib that is the source for the whole graph.
      // The "srcNode" is with regards to the link added to the graphData,
      // and since we're linking the sourceIbGib to the root, it is the root
      // in this case.
      t.addVirtualNode(srcId, srcType, t.sourceIbGib, /*srcNode*/ root, srcShape, autoZap, fadeTimeoutMs, /*cmd*/ null, /*title*/ null, /*label*/ null, /*startPos*/ {x: root.x, y: root.y});
    } else {
      console.warn(`no source ibGib. (t.sourceIbGib is ${t.sourceIbGib})`);
    }
  }

  getNodeShapeFromIb(ib) {
    return ib === "comment" ? "rect" : "circle";
  }

  createVirtualNode(id, type, nameOrIbGib, shape, cmd, title, label) {
    let virtualNode = {
      id: id || ibHelper.getRandomString(),
      title: title || "", // shows as the label - disgusting I know, but the woman is especially teed today.
      label: label || "...", // shows as the tooltip
      fontFamily: "FontAwesome",
      fontOffset: "9px",
      type: type,
      name: nameOrIbGib,
      shape: shape || "circle",
      virtualId: ibHelper.getRandomString()
    };

    if (type === "ibGib") {
      virtualNode.ibGib = nameOrIbGib;
    } else if (type === "cmd" && cmd) {
      virtualNode.cmd = cmd;
    } else if (type === "rel8n") {
      virtualNode.rel8nName = label // out of hand, but can't refactor right now
    }

    return virtualNode;
  }

  /**
   * Creates a virtual node with the d.id of `id` for the given `nameOrIbGib`.
   * It then creates a link from the `srcNode` to this virtual node and adds
   * it to the graph.
   *
   * The virtualNode added will have a `virtualId`. This is how we can
   * later find the virtual node when we want to concretize/remove the node.
   * This is also how we determine if a node is virtual, i.e. if it has a
   * `virtualId`, then it is virtual.
   *
   * @param `id` if not given, will create a new one. NB that this is NOT the `virtualId`.
   * @param `type` can be `cmd`, `ibGib`, or `rel8n`.
   *
   * If `autozap` is true, then will automatically zap the virtual node, thus
   * either concretizing it if it's an ibGib or `rel8n` node. If it's a `cmd`
   * node, then `autozap` is ignored.
   *
   * `fadeTimeoutMs` controls how long the virtual node will live without any
   * user interaction. If `!fadeTimeoutMs || fadeTimeoutMs< 0`, then the virtual
   * node will not automatically time out and will stay virtual until zap
   * completes. If `autoZap` is true, then this is ignored.
   *
   * @returns The virtual node added.
   * @see `DynamicIbScape.zapVirtualNode`
   */
  addVirtualNode(id, type, nameOrIbGib, srcNode, shape, autoZap, fadeTimeoutMs, cmd, title, label, startPos) {
    let t = this;

    let virtualNode = t.createVirtualNode(id, type, nameOrIbGib, shape, cmd, title, label);
    if (startPos) {
      virtualNode.x = startPos.x;
      virtualNode.y = startPos.y;
    }

    let links = srcNode ? [{ source: srcNode, target: virtualNode }] : [];
    t.add([virtualNode], links, /*updateParentOrChild*/ true);

    if (srcNode) { t.animateNodeBorder(/*d*/ srcNode, /*nodeShape*/ null); }
    t.animateNodeBorder(/*d*/ virtualNode, /*nodeShape*/ null);

    if (type !== "cmd" && autoZap) {
      t.zapVirtualNode(virtualNode);
    } else if (fadeTimeoutMs) {
      let nodeShape = d3.select("#" + virtualNode.id);

      var transition =
        d3.transition()
          .duration(fadeTimeoutMs)
          .ease(d3.easeLinear);

      console.log("fading out...");

      let o = nodeShape.attr("opacity");

      nodeShape
        .attr("opacity", 1)
        .transition(transition)
        .attr("opacity", 0.1);

      virtualNode.fadeTimer = setTimeout(() => {
        t.remove(virtualNode, /*updateParentOrChild*/ true);
      }, fadeTimeoutMs);
    }

    return virtualNode;
  }

  zapVirtualNode(virtualNode, nestedLevelsToZap) {
    let t = this;

    if (!virtualNode.virtualId || virtualNode.busy) {
      return;
    }

    t.setBusy(virtualNode);

    t.animateNodeBorder(/*d*/ virtualNode, /*nodeShape*/ null);

    switch (virtualNode.type) {
      case "cmd":
        // execute the command
        t.commandMgr.exec(virtualNode.cmdTarget, virtualNode.cmd);
        t.clearBusy(virtualNode);
        break;

      case "ibGib":
        t.clearFadeTimeout(virtualNode);

        // let ibGibAlreadyLoaded = !!virtualNode.ibGibJson;

        t.getIbGibJson(virtualNode.ibGib, ibGibJson => {
          console.log(`got json: ${JSON.stringify(ibGibJson)}`);
          virtualNode.ibGibJson = ibGibJson;

          t.updateRender(virtualNode);

          delete virtualNode.virtualId;

          let links = t.graphData.links.filter(l => l.source.id === virtualNode.id || l.target.id === virtualNode.id);

          t.remove(virtualNode);
          t.add([virtualNode], links, /*updateParentOrChild*/ true);

          t.addDefaultVirtualNodes(virtualNode);
          t.addSpecializedVirtualNodes(virtualNode);
          t.clearBusy(virtualNode);
        });
        break;

      case "rel8n":
        // expand the rel8n for the associated ibGib
        t.clearBusy(virtualNode);
        break;

      default:
        console.warn(`zapVirtualNode: Unknown node type: ${virtualNode.type}`);
    }
  }

  updateRender(node) {
    if (node.ibGibJson) {
      if (node.ibGibJson.ib === "pic") {
        node.render = "image";
      } else if (node.ibGibJson.ib === "comment") {
        node.render = "text";
      }
    } else {
      delete node.render;
    }
  }

  clearFadeTimeout(virtualNode) {
    let t = this;

    let nodeShape = d3.select("#" + t.getNodeShapeId(virtualNode.id));
    nodeShape
      .attr("opacity", d => t.getNodeShapeOpacity(d))
      .transition(); // resets/"removes" the fade transition

    if (virtualNode.fadeTimer) {
      clearTimeout(virtualNode.fadeTimer);
      delete virtualNode.fadeTimer;
    }
  }

  getIbGibJson(ibgib, callback) {
    let ibGibJson = this.ibGibCache.get(ibgib);
    if (ibGibJson) {
      if (callback) { callback(ibGibJson); }
    } else {
      // We don't yet have the json for this particular data.
      // So we need to load the json, and when it returns we will exec callback.
      d3.json(this.baseJsonPath + ibgib, ibGibJson => {
        this.ibGibCache.add(ibGibJson);

        if (callback) { callback(ibGibJson); }
      });
    }
  }

  getNodeShapeRadius(d) {
    let multiplier = d3Scales[d.cat] || d3Scales["default"];
    let result = d3CircleRadius * multiplier;
    return result;
  }
  getNodeShapeFill(d) {
    let color;

    switch (d.type) {
      case "ibGib":
        let index;

        if (d.ibGib === "ib^gib") {
          index = "ibGib";
        } else if (d.render && d.render === "text") {
          index = "text";
        } else if (d.render && d.render === "image") {
          index = "image";
        } else if (d.type === "cmd" && d.cmd) {

        } else if (d.type === "rel8n") {
          index = d.name;
        } else {
          index = d.id;
        }

        color = d3Colors[index] || d3Colors["default"];
        break;

      case "cmd":
        color = d.cmd.color;
        break;

      case "rel8n":
        // todo: d.type === rel8n
        // color = d3Colors[d.name];
        color = d3Colors["default"];
        break;

      default:
        color = d3Colors["default"];
    }

    return color;
  }
  getNodeBorderStrokeDashArray(d) {
    return d.virtualId ? "16,8,16" : null;
  }
  getNodeShapeOpacity(d) {
    return 1;
    // return d.virtualId ? 0.9 : 1;
  }
  getNodeShapeRadius(d) {
    let t = this;
    let multiplier = d3Scales["default"];

    if (d.ibGib === t.sourceIbGib) {
      multiplier = d3Scales["source"];
    } else if (d.ibGib === "ib^gib") {
      multiplier = d3Scales["ib^gib"]
    } else {
      let { ib } = ibHelper.getIbAndGib(t.sourceIbGib);
      multiplier = d3Scales[ib] || multiplier;
    }

    let result = d3CircleRadius * multiplier;
    if (isNaN(result)) { debugger; }

    return result;
  }
  getNodeLabelText(d) {
    // debugger;
    if (d.type === "ibGib" && d.ibGibJson) {
      if (d.ibGibJson.data && d.ibGibJson.data.label) {
        return d.ibGibJson.data.label;
      } else if (d.ibGib === "ib^gib") {
        return "\u29c2";
      } else {
        return d.ibGibJson.ib;
      }
    } else if (d.virtualId && d.type === "ibGib") {
      return "\u26a1";
    } else if (d.type === "cmd" && d.cmd) {
      return d.cmd.icon;
    } else {
      return d.id;
    }
  }
  getNodeTitle(d) {
    if (d.type === "ibGib" && d.ibGibJson) {
      if (d.ibGibJson.data && d.ibGibJson.data.title) {
        return d.ibGibJson.data.title;
      } else {
        return ibHelper.getFull_ibGib(d.ibGibJson);
      }
    } else if (d.virtualId && d.type === "ibGib") {
      return "Virtual ibGib. Click to zap with some juice \u26a1!";
    } else if (d.type === "cmd" && d.cmd) {
      return d.cmd.description;
    } else {
      return d.id;
    }
  }

  selectNode(d) {
    let t = this;

    t.setShapesOpacity("circle", 0.3);
    t.setShapesOpacity("rect", 0.3);

    t.selectedDatum = d;
    t.selectedNode = d3.select("#" + t.getNodeShapeId(d));
    t.selectedNode
        .style("opacity", 1)
        .attr("stroke", "yellow")
        .attr("stroke-width", "7px");

    t.animateNodeBorder(/*d*/ null, t.selectedNode);

    t.openMenu(d);
  }
  clearSelectedNode() {
    let t = this;

    if (t.selectedNode) {

      t.setShapesOpacity("circle", null);
      t.setShapesOpacity("rect", null);

      t.selectedNode
          .style("opacity", d => t.getNodeShapeOpacity(d))
          .attr("stroke", d => t.getNodeBorderStroke(d))
          .attr("stroke-width", d => t.getNodeBorderStrokeWidth(d));

      if (t.menu) { t.closeMenu(); }

      delete t.selectedNode;
      delete t.selectedDatum;
    }
  }

  handleBackgroundClicked() {
    let t = this;
    t.clearSelectedNode();

    if (t.currentCmd) {
      t.currentCmd.close();
      delete t.currentCmd;
    }

    d3.event.preventDefault();
  }
  handleNodeNormalClicked(d) {
    let t = this;
    console.log(`node clicked: ${JSON.stringify(d)}`);

    t.clearSelectedNode();

    t.animateNodeBorder(d, /*nodeShape*/ null);

    if (d.virtualId) {
      t.zapVirtualNode(d);
    } else {
      t.showDefaultVirtualNodes(d);
    }
  }
  handleNodeLongClicked(d) {
    this.clearSelectedNode();
    this.selectNode(d);
  }
  handleResize() {
    let t = this;

    super.handleResize();

    if (t.menu) {
      const size = 240;
      const halfSize = Math.trunc(size / 2);
      const pos = {x: t.center.x - halfSize, y: t.center.y - halfSize};

      t.menu.moveTo(pos);
    }

    if (t.currentCmd) {
      t.currentCmd.repositionView();
    }
  }
  handleNodeRawMouseDown(d) {
    let t = this;
    if (t.menu) {
      t.closeMenu();
    } else {
      super.handleNodeRawMouseDown(d);
    }
  }

  showDefaultVirtualNodes(d) {
    let t = this;
    t.addDefaultVirtualNodes(d);
    // if (d.defaultVirtualNodes && d.defaultVirtualNodes) {
    //   d.defaultVirtualNodes.forEach(virtualNode => {
    //     t.remove(virtualNode, /*updateParentOrChild*/ true)
    //   });
    //   delete d.defaultVirtualNodes;
    // } else {
      // d.defaultVirtualNodes = t.addDefaultVirtualNodes(d);
    // }
  }

  addSpecializedVirtualNodes(d) {
    let t = this;

    const existingVirtualNodes = t.getVirtualNodes(d);
    const fadeTimeoutMs = 10000;

    if (d.ibGibJson) {
      if (existingVirtualNodes.filter(x => x.type === "cmd").length === 0) {
        return [
          t.addCmdVirtualNode(d, "huh", fadeTimeoutMs),
          t.addCmdVirtualNode(d, "help", fadeTimeoutMs),
        ];
      } else {
        return [];
      }
    } else {
      // not a loaded ibGibJson, so no virtual nodes to add.
      // So we are assuming this is a virtual node itself.
      if (!d.virtualId) { console.warn("addDefaultVirtualNodes on non-virtual node without ibGibJson"); }
      return [];
    }
  }

  addDefaultVirtualNodes(d) {
    let t = this;

    const existingVirtualNodes = t.getVirtualNodes(d);
    const fadeTimeoutMs = 4000;

    if (d.ibGib === "ib^gib" && existingVirtualNodes.length === 0) {

      return [
        t.addCmdVirtualNode(d, "huh", fadeTimeoutMs),
        t.addCmdVirtualNode(d, "query", fadeTimeoutMs),
        t.addCmdVirtualNode(d, "fork", fadeTimeoutMs),
        // t.addCmdVirtualNode(d, "identemail", fadeTimeoutMs),
      ];
    } else {
      if (d.ibGibJson) {
        if (existingVirtualNodes.filter(x => x.type === "cmd").length === 0) {
          return [
            t.addCmdVirtualNode(d, "huh", fadeTimeoutMs),
            t.addCmdVirtualNode(d, "help", fadeTimeoutMs),
            t.addCmdVirtualNode(d, "fork", fadeTimeoutMs),
          ];
        } else {
          return [];
        }
      } else {
        // not a loaded ibGibJson, so no virtual nodes to add.
        // So we are assuming this is a virtual node itself.
        if (!d.virtualId) { console.warn("addDefaultVirtualNodes on non-virtual node without ibGibJson"); }
        return [];
      }
    }
  }

  getVirtualNodes(d) {
    return this.graphData
      .links
      .filter(l => l.source.id === d.id && l.target.virtualId)
      .map(l => l.target);
  }

  addCmdVirtualNode(dSrc, cmdName, fadeTimeoutMs) {
    let t = this;
    let cmd = d3MenuCommands.filter(c => c.name === cmdName)[0];

    let node = t.addVirtualNode(t.getUniqueId(`${dSrc.id}_${cmdName}`), /*type*/ "cmd", `${cmdName}^gib`, /*srcNode*/ dSrc, "circle", /*autoZap*/ false, fadeTimeoutMs, cmd, /*title*/ null, /*label*/ null, /*startPos*/ {x: dSrc.x, y: dSrc.y});
    node.cmdTarget = dSrc;
  }

  addRel8nVirtualNode(dSrc, rel8nName, fadeTimeoutMs) {
    let t = this;

    let title = rel8nName in d3Rel8nIcons ? d3Rel8nIcons[rel8nName] : "";
    let node = t.addVirtualNode(t.getUniqueId(`${dSrc.id}_${rel8nName}`), /*type*/ "rel8n", `rel8n^gib`, /*srcNode*/ dSrc, "circle", /*autoZap*/ false, fadeTimeoutMs, /*cmd*/ null, title, /*label*/ rel8nName, /*startPos*/ {x: dSrc.x, y: dSrc.y});
  }

  openMenu(d) {
    let t = this;

    const size = 240;
    const halfSize = Math.trunc(size / 2);
    const pos = {x: t.center.x - halfSize, y: t.center.y - halfSize};

    let menuDiv =
      d3.select(t.graphDiv)
        .append('div')
        .attr("id", t.getUniqueId("menu"))
        .style('width', `${size}px`)
        .style('height', `${size}px`)
        .attr("class", "ib-pos-abs")
        .node();
    //
    t.menu = new DynamicIbScapeMenu(menuDiv, /*svgId*/ t.svgId + "_menu", /*config*/ null, /*ibScape*/ t, d, pos);
    t.menu.init();
  }
  closeMenu() {
    let t = this;

    if (t.menu) {
      t.menu.close();
      delete t.menu;
      d3.select("#" + t.getUniqueId("menu")).remove();
    }
  }

  setShapesOpacity(shape, opacity) {
    let t = this;
    let selection = d3.select(`#${this.getGraphNodesGroupId()}`)
      .selectAll(shape);

    if (opacity || opacity === 0) {
      selection
        .style("opacity", opacity);
    } else {
      selection
        .style("opacity", d => t.getNodeShapeOpacity(d));
    }
  }

}
