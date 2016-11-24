import * as d3 from 'd3';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands } from '../d3params';

import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import { DynamicIbScapeMenu } from './dynamic-ib-scape-menu';
import * as ibHelper from '../services/ibgib-helper';
import { IbGibCommandMgr } from '../services/commanding/ibgib-command-mgr';

export class DynamicIbScape extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, baseJsonPath, ibGibCache, ibGibImageProvider, sourceIbGib) {
    super(graphDiv, svgId, {});

    let t = this;

    t.baseJsonPath = baseJsonPath;
    t.ibGibCache = ibGibCache;
    t.ibGibImageProvider = ibGibImageProvider;
    t.commandMgr = new IbGibCommandMgr(t);

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
        velocityDecay: 0.45,
        chargeStrength: -25,
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

    t.sourceIbGib = sourceIbGib;
  }

  init() {
    super.init();
    let t = this;

    console.log("init");

    t.initResize();
    t.addRoot();
    // t.addSourceIbGib();
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

  /** Adds the root, returns the id. */
  addRoot() {
    let t = this;

    // Only add the root if there are no existing nodes on the graph.
    if (!t.graphData || !t.graphData.nodes || t.graphData.nodes.length === 0) {
      let rootId = t.getUniqueId("root"),
          rootType = "ibGib",
          rootIbGib = "ib^gib",
          rootShape = "circle",
          autoZap = false,
          fadeTimeoutMs = 3000,
          rootPulseMs = 2000;

      t.addVirtualNode(rootId, rootType, rootIbGib, /*srcNode*/ null, rootShape, autoZap, fadeTimeoutMs);

      // Call recursively. If it was succesfully added and subsequently
      // zapped by the user, then we won't be at this point.
      setTimeout(() => t.addRoot(), fadeTimeoutMs + rootPulseMs);

      // t.getIbGibJson("ib^gib", ibGibJson => {
      //   let node = {
      //     id: t.getUniqueId("root"),
      //     title: "ib",
      //     name: "ib",
      //     cat: "ibGib",
      //     ibgib: "ib^gib",
      //     ibGibJson: ibGibJson,
      //     shape: "circle"
      //   };
      //
      //   t.add([node], [], /*updateParentOrChild*/ true);
      // })
    // } else {
      // console.log("root node already added.");
    }
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
  addVirtualNode(id, type, nameOrIbGib, srcNode, shape, autoZap, fadeTimeoutMs) {
    let t = this;

    let virtualNode = t.createVirtualNode(id, type, nameOrIbGib, shape);
    let links = srcNode ? [{ source: srcNode, target: virtualNode }] : [];
    t.add([virtualNode], links, /*updateParentOrChild*/ true);

    t.animateNodeBorder(/*d*/ srcNode, /*nodeShape*/ null);
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
      // debugger;
      let o = nodeShape.attr("opacity");
      // debugger;
      nodeShape
        .attr("opacity", 1)
        .transition(transition)
        .attr("opacity", 0.3);

      virtualNode.fadeTimer = setTimeout(() => {
        t.remove(virtualNode, /*updateParentOrChild*/ true);
      }, fadeTimeoutMs);
    }
  }

  zapVirtualNode(virtualNode) {
    let t = this;

    if (!virtualNode.virtualId) {
      return;
    }

    t.clearFadeTimeout(virtualNode);
    t.animateNodeBorder(/*d*/ virtualNode, /*nodeShape*/ null);

    switch (virtualNode.type) {
      case "cmd":
        break;

      case "ibGib":
        t.getIbGibJson(virtualNode.ibGib, ibGibJson => {
          console.log(`got json: ${JSON.stringify(ibGibJson)}`)
          virtualNode.ibGibJson = ibGibJson;
          if (ibGibJson.ib === "pic") {
            virtualNode.render = "image";
          } else if (ibGibJson.ib === "comment") {
            virtualNode.render = "text";
          }
          delete virtualNode.virtualId;

          let links = t.graphData.links.filter(l => l.source.id === virtualNode.id || l.target.id === virtualNode.id);

          t.remove(virtualNode);
          t.add([virtualNode], links, /*updateParentOrChild*/ true);
        });
        break;

      case "rel8n":
        break;

      default:
        console.warn(`zapVirtualNode: Unknown node type: ${virtualNode.type}`);
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
    let index = d.cat;
    if (d.ibGib === "ib^gib") {
      index = "ibGib";
    } else if (d.render && d.render === "text") {
      index = "text";
    } else if (d.render && d.render === "image") {
      index = "image";
    } else if (d.cat === "rel8n") {
      index = d.id;
    }
    return d3Colors[index] || d3Colors["default"];
  }
  getNodeBorderStrokeDashArray(d) {
    return (d.cat === "huh" || d.cat === "help" || d.cat === "query") ? "7,7,7" : null;
  }
  getNodeShapeOpacity(d) {
    return 1;
    // return d.virtualId ? 0.9 : 1;
  }
  getNodeShapeRadius(d) {
    let multiplier = d3Scales[d.cat] || d3Scales["default"];

    let result = d3CircleRadius * multiplier;

    return result;
  }
  getNodeLabelText(d) {
    if (d.virtualId) {
      return "...";
    } else if (d.type === "ibGib" && d.ibGibJson) {
      if (d.ibGibJson.data && d.ibGibJson.data.label) {
        return d.ibGibJson.data.label;
      } else {
        return d.ibGibJson.ib;
      }
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

    if (t.currentDetails) {
      t.currentDetails.close();
      delete t.currentDetails;
    }

    // d3.select("#ib-d3-graph-menu-div")
    //   .style("left", t.center.x + "px")
    //   .style("top", t.center.y + "px")
    //   .style("visibility", "hidden")
    //   .attr("z-index", -1);

    d3.event.preventDefault();
  }
  handleNodeNormalClicked(d) {
    let t = this;
    t.clearSelectedNode();

    t.animateNodeBorder(d, /*nodeShape*/ null);

    if (d.virtualId) {
      t.zapVirtualNode(d);
    } else {
      if (d.cat === "ibGib") {
        t.toggleDefaultVirtualNodes(d);
      } else if (d.cat === "huh") {
        t.clearSelectedNode();
        t.selectNode(d);

        let dIbGib = t.graphData.nodes.filter(x => x.cat === "huh")[0];
        let dCommand = d3MenuCommands.filter(x => x.name === "help")[0];
        t.commandMgr.exec(dIbGib, dCommand);
        let dRoot = t.graphData.nodes.filter(x => x.cat === "ibGib")[0];
        t.toggleDefaultVirtualNodes(dRoot);
      } else if (d.cat === "query") {
        t.clearSelectedNode();
        t.selectNode(d);

        let dIbGib = t.graphData.nodes.filter(x => x.cat === "query")[0];
        let dCommand = d3MenuCommands.filter(x => x.name === "query")[0];
        t.commandMgr.exec(dIbGib, dCommand);

        let dRoot = t.graphData.nodes.filter(x => x.cat === "ibGib")[0];
        t.toggleDefaultVirtualNodes(dRoot);
      } else {
        // super.handleNodeNormalClicked(d);
      }
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
      if (t.menu.currentDetails) { t.menu.currentDetails.reposition(); }
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

  toggleDefaultVirtualNodes(d) {
    let t = this;
    if (d.defaultVirtualNodes) {
      d.defaultVirtualNodes.forEach(virtualNode => {
        t.remove(virtualNode, /*updateParentOrChild*/ true)
      });
      delete d.defaultVirtualNodes;
    } else {
      d.defaultVirtualNodes = t.getDefaultVirtualNodes(d);
    }
  }

  getDefaultVirtualNodes(d) {
    if (d.cat === "ibGib") {
      t.huhGibYo(dRoot, dHuh => t.addAndAnimateRootGib(dRoot, dHuh));
      t.queryGibYo(dRoot, dQuery => t.addAndAnimateRootGib(dRoot, dQuery));
    } else {

    }
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

  huhGibYo(rootNode, callback) {
    let t = this;

    // let rootNode = t.graphData.nodes.filter(x => x.id === t.getUniqueId("root"))[0];
    let huhId = t.getUniqueId("huh");

    if (t.graphData.nodes.some(n => n.id === huhId)) {
      console.log("huh already added.");
      return;
    }

    t.getIbGibJson("huh^gib", ibGibJson => {
      let newNode = {
        id: huhId,
        title: "Help", // shows as the label
        label: "\uf29c", // Shows as the tooltip
        fontFamily: "FontAwesome",
        fontOffset: "9px",
        name: "huh",
        cat: "huh",
        ibgib: ibHelper.getFull_ibGib(ibGibJson),
        ibGibJson: ibGibJson,
        shape: "circle",
        x: rootNode.x,
        y: rootNode.y,
        virtualId: ibHelper.getRandomString()
      };

      callback(newNode);
    });
  }
  queryGibYo(rootNode, callback) {
    let t = this;

    // let rootNode = t.graphData.nodes.filter(x => x.id === t.getUniqueId("root"))[0];
    let queryId = t.getUniqueId("query");
    let queryIbgib = "query^gib";

    if (t.graphData.nodes.some(n => n.id === queryId)) {
      console.log("query already added.");
      return;
    }

    let virtualNode = t.createVirtualNode(queryId, queryIbgib);

    t.getIbGibJson("query^gib", ibGibJson => {
      let newNode = {
        id: queryId,
        title: "Search", // shows as the label
        label: "\uf002", // Shows as the tooltip
        fontFamily: "FontAwesome",
        fontOffset: "9px",
        name: "query",
        cat: "query",
        ibgib: ibHelper.getFull_ibGib(ibGibJson),
        ibGibJson: ibGibJson,
        shape: "circle",
        x: rootNode.x,
        y: rootNode.y,
        virtualId: ibHelper.getRandomString()
      };

      callback(newNode);
    });
  }

  createVirtualNode(id, type, nameOrIbGib, shape) {
    let virtualNode = {
      id: id || ibHelper.getRandomString(),
      title: "...", // shows as the label
      label: "...", // shows as the tooltip
      fontFamily: "FontAwesome",
      fontOffset: "9px",
      type: type,
      name: nameOrIbGib,
      shape: shape || "circle",
      virtualId: ibHelper.getRandomString()
    };

    if (type === "ibGib") {
      virtualNode.ibGib = nameOrIbGib;
    }

    return virtualNode;
  }
}
