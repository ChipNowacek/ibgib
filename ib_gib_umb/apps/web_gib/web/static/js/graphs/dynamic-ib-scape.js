import * as d3 from 'd3';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands } from '../d3params';

import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import { DynamicIbScapeMenu } from './dynamic-ib-scape-menu';
import * as ibHelper from '../services/ibgib-helper';
import { IbGibCommandMgr } from '../services/commanding/ibgib-command-mgr';

export class DynamicIbScape extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, baseJsonPath, ibGibCache, ibGibImageProvider, ibgib) {
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
  }

  init() {
    super.init();
    let t = this;

    console.log("init")

    t.initResize();
    t.addRoot();
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

  addRoot() {
    let t = this;

    if (!t.graphData || !t.graphData.nodes || t.graphData.nodes.length === 0) {
      t.getIbGibJson("ib^gib", ibGibJson => {
        let node = {
          id: t.getUniqueId("root"),
          title: "ib",
          name: "ib",
          cat: "ibgib",
          ibgib: "ib^gib",
          ibGibJson: ibGibJson,
          shape: "circle"
        };

        t.add([node], [], /*updateParentOrChild*/ true);
      })
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
      };

      callback(newNode);
    });
  }
  queryGibYo(rootNode, callback) {
    let t = this;

    // let rootNode = t.graphData.nodes.filter(x => x.id === t.getUniqueId("root"))[0];
    let queryId = t.getUniqueId("query");

    if (t.graphData.nodes.some(n => n.id === queryId)) {
      console.log("query already added.");
      return;
    }

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
      };

      callback(newNode);
    });
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
    if (d.ibgib === "ib^gib") {
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

      t.setShapesOpacity("circle", 1);
      t.setShapesOpacity("rect", 1);

      t.selectedNode
          .style("opacity", 1)
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

    t.animateNodeBorder(d, /*node*/ null);

    if (d.cat === "ibgib") {
      t.toggleRootGibs(d);
    } else if (d.cat === "huh") {
      t.clearSelectedNode();
      t.selectNode(d);

      let dIbGib = t.graphData.nodes.filter(x => x.cat === "huh")[0];
      let dCommand = d3MenuCommands.filter(x => x.name === "help")[0];
      t.commandMgr.exec(dIbGib, dCommand);
    } else if (d.cat === "query") {
      t.clearSelectedNode();
      t.selectNode(d);

      let dIbGib = t.graphData.nodes.filter(x => x.cat === "query")[0];
      let dCommand = d3MenuCommands.filter(x => x.name === "query")[0];
      t.commandMgr.exec(dIbGib, dCommand);
    } else {
      // super.handleNodeNormalClicked(d);
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

  toggleRootGibs(dRoot) {
    let t = this;
    if (t.rootGibs) {
      t.rootGibs.forEach(rootGib => {
        t.remove(rootGib, /*updateParentOrChild*/ true)
      });
      t.rootGibs = null;
    } else {
      t.rootGibs = [];
      t.huhGibYo(dRoot, dHuh => t.addAndAnimateRootGib(dRoot, dHuh));
      t.queryGibYo(dRoot, dQuery => t.addAndAnimateRootGib(dRoot, dQuery));
    }
  }

  addAndAnimateRootGib(root, rootGib) {
    let t = this;
    t.add([rootGib], [{ source: root, target: rootGib }], /*updateParentOrChild*/ true);
    t.animateNodeBorder(rootGib, /*node*/ null);
    t.rootGibs.push(rootGib);
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
    d3.select(`#${this.getGraphNodesGroupId()}`)
      .selectAll(shape)
      .style("opacity", opacity);
  }

}
