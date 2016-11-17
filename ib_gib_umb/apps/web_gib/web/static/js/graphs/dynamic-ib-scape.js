import * as d3 from 'd3';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands } from '../d3params';

import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import { DynamicIbScapeMenu } from './dynamic-ib-scape-menu';
import * as ibHelper from '../services/ibgib-helper';

export class DynamicIbScape extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, baseJsonPath, ibGibCache, ibGibImageProvider, ibgib) {
    super(graphDiv, svgId, {});

    let t = this;

    t.baseJsonPath = baseJsonPath;
    t.ibGibCache = ibGibCache;
    t.ibGibImageProvider = ibGibImageProvider;

    let defaults = {
      background: {
        fill: "green",
        opacity: 1,
        shape: "rect"
      },
      mouse: {
        dblClickMs: 250,
        longPressMs: 800
      },
      simulation: {
        velocityDecay: 0.45,
        chargeStrength: -25,
        chargeDistanceMin: 10,
        chargeDistanceMax: 10000,
        linkDistance: 75,
        collideDistance: 25,
      },
      node: {
        cursorType: "crosshair",
        baseRadiusSize: 35,
        defShapeFill: "lightblue",
        defBorderStroke: "darkgreen",
        defBorderStrokeWidth: "2px",
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

    t.addRoot();
  }


  addRoot() {
    let t = this;

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

  addHuh() {
    let t = this;

    let huhId = t.getUniqueId("huh");

    if (t.graphData.nodes.some(n => n.id === huhId)) {
      console.log("huh already added.");
      return;
    }

    t.getIbGibJson("huh^gib", ibGibJson => {
      let newNode = {
        id: huhId,
        title: "?",
        name: "huh",
        cat: "huh",
        ibgib: ibHelper.getFull_ibGib(ibGibJson),
        ibGibJson: ibGibJson,
        shape: "circle"
      };

      let link = { source: t.getUniqueId("root"), target: newNode };

      t.add([newNode], [link], /*updateParentOrChild*/ true);
      t.animateNodeBorder(newNode, /*node*/ null);
    });
  }

  handleBackgroundClicked() {
    let t = this;
    t.clearSelectedNode();

    // d3.select("#ib-d3-graph-menu-div")
    //   .style("left", t.center.x + "px")
    //   .style("top", t.center.y + "px")
    //   .style("visibility", "hidden")
    //   .attr("z-index", -1);

    d3.event.preventDefault();
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

  handleNodeNormalClicked(d) {
    let t = this;
    t.clearSelectedNode();
    if (d.cat === "ibgib") {
      t.addHuh();
    } else {
      super.handleNodeNormalClicked(d);
    }
    t.animateNodeBorder(d, /*node*/ null);
  }
  handleNodeLongClicked(d) {
    this.clearSelectedNode();
    this.selectNode(d);
  }

  openMenu(d) {
    let t = this;

    const size = 240;
    const halfSize = Math.trunc(size / 2);
    const pos = {x: t.center - halfSize, y: t.center - halfSize};

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

    // let menuDiv = t.menu.graphDiv;
    t.menu.destroy();

    delete t.menu;

    d3.select("#" + t.getUniqueId("menu")).remove();
  }

  setShapesOpacity(shape, opacity) {
    d3.select(`#${this.getGraphNodesGroupId()}`)
      .selectAll(shape)
      .style("opacity", opacity);
  }
}
