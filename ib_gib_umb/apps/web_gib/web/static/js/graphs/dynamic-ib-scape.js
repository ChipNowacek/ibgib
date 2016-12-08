import * as d3 from 'd3';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3BoringRel8ns, d3RequireExpandLevel2, d3MenuCommands, d3Rel8nIcons, d3AddableRel8ns } from '../d3params';

import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import { DynamicIbScapeMenu } from './dynamic-ib-scape-menu';
import * as ibHelper from '../services/ibgib-helper';
import { CommandManager } from '../services/commanding/command-manager';

export class DynamicIbScape extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, baseJsonPath, ibGibCache, ibGibImageProvider, sourceIbGib, ibGibSocketManager, ibGibEventBus) {
    super(graphDiv, svgId, {});
    let t = this;

    t.baseJsonPath = baseJsonPath;
    t.ibGibCache = ibGibCache;
    t.ibGibImageProvider = ibGibImageProvider;
    t.ibGibSocketManager = ibGibSocketManager;
    t.ibGibEventBus = ibGibEventBus;
    t.commandMgr = new CommandManager(t, ibGibSocketManager);
    t.virtualNodes = {};

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
        velocityDecay: 0.55,
        chargeStrength: 35,
        chargeDistanceMin: 10,
        chargeDistanceMax: 10000,
        linkDistance: 125,
        linkDistance_Src_Rel8n: 25,
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
      },
      other: {
        cmdFadeTimeoutMs_Default: 4000,
        cmdFadeTimeoutMs_Specialized: 10000,
        rel8nFadeTimeoutMs_Boring: 4000,
        rel8nFadeTimeoutMs_Spiffy: 0,

      }
    }
    t.config = $.extend({}, defaults, config || {});

    t.sourceIbGib = sourceIbGib || "ib^gib";
  }

  init() {
    super.init();
    let t = this;

    console.log("init");
    t.commandMgr.init();

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
        if (t.currentCmd) {
          debugger;

          t.currentCmd.close();
        }
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

        rootNode.isSource = true;

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
      let node = t.addVirtualNode(srcId, srcType, t.sourceIbGib, /*srcNode*/ root, srcShape, autoZap, fadeTimeoutMs, /*cmd*/ null, /*title*/ null, /*label*/ null, /*startPos*/ {x: root.x, y: root.y});
      node.isSource = true;
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

    t.virtualNodes[virtualNode.id] = virtualNode;

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
        t.removeVirtualNode(virtualNode, /*keepInGraph*/ false);
      }, fadeTimeoutMs);
    }

    return virtualNode;
  }
  removeVirtualNode(node, keepInGraph) {
    let t = this;
    delete t.virtualNodes[node.id];

    if (node.fadeTimer) {
      clearTimeout(node.fadeTimer);
      delete node.fadeTimer;
    }

    if (!keepInGraph) {
      if (t.graphData.nodes.some(n => n.id === node.id)) {
        t.remove(node, /*updateParentOrChild*/ true);
      }
    }
  }
  removeVirtualCmdNodes() {
    let t = this;
    t.freezeNodes(1000);

    Object.keys(t.virtualNodes)
      .filter(key => t.virtualNodes[key].type === "cmd")
      .map(key => t.virtualNodes[key])
      .forEach(n => t.removeVirtualNode(n));
  }

  freezeNodes(durationMs) {
    let t = this;
    t.graphData.nodes.forEach(n => {
      n.fx = n.x;
      n.fy = n.y;
    });

    setTimeout(() => {
      t.graphData.nodes.forEach(n => {
        delete n.fx;
        delete n.fy;
      });
    }, durationMs);
  }

  zapVirtualNode(virtualNode) {
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
        t.zapVirtualIbGibNode(virtualNode);
        break;

      case "rel8n":
        t.zapVirtualRel8nNode(virtualNode);
        break;

      case "error":
        let links = t.graphData.links.filter(l => l.source.id === virtualNode.id || l.target.id === virtualNode.id);

        if (virtualNode.notified) {
          // The user's already been notified, so remove the node.
          t.remove(virtualNode);
        } else {
          // Notify the user that something went wrong, re-add node to update
          // the label/tooltip.
          alert(virtualNode.errorMsg);
          virtualNode.notified = true;
          t.swap(virtualNode, virtualNode, /*updateParentOrChild*/ true);
        }

        t.clearBusy(virtualNode);
        break;

      default:
        console.warn(`zapVirtualNode: Unknown node type: ${virtualNode.type}`);
    }
  }
  zapVirtualIbGibNode(node) {
    let t = this;

    t.clearFadeTimeout(node);

    t.getIbGibJson(node.ibGib, ibGibJson => {
      console.log(`got json: ${JSON.stringify(ibGibJson)}`);
      node.ibGibJson = ibGibJson;

      t.updateRender(node);

      t.removeVirtualNode(node, /*keepInGraph*/ true);
      delete node.virtualId;
      t.swap(node, node, /*updateParentOrChild*/ true);

      if (node.ibGib !== "ib^gib") {
        t.ibGibEventBus.connect(node.ibGib, updateMsg => {
          t.handleEventBusUpdateMsg(node.ibGib, updateMsg);
        });
      }

      t.clearBusy(node);
      t.animateNodeBorder(node, /*nodeShape*/ null);
    });
  }
  zapVirtualRel8nNode(rel8nNode) {
    let t = this;

    t.clearFadeTimeout(rel8nNode);
    t.clearBusy(rel8nNode);
    t.removeVirtualNode(rel8nNode);
    delete rel8nNode.virtualId;
    t.add([rel8nNode], [{source: rel8nNode.rel8nSrc.id, target: rel8nNode.id}], /*updateParentOrChild*/ true);
    t.toggleExpandCollapseLevel(rel8nNode);
  }

  /** Toggles the expand/collapse level for the node, showing/hiding rel8ns */
  toggleExpandCollapseLevel(node) { let t = this;
    node.expandLevel = node.expandLevel || 0;

    if (node.expandLevel && t.getChildrenCount_All(node) === 0) {
      node.expandLevel = 0;
    }


    if (node.ibGib === "ib^gib") {
      t.removeVirtualCmdNodes();
      t.addCmdVirtualNodes_Default(node);
    } else if (node.type === "ibGib") {
      t.removeVirtualCmdNodes();
      t.toggleExpandCollapseLevel_IbGib(node);
    } else if (node.type === "rel8n") {
      t.toggleExpandCollapseLevel_Rel8n(node);
    } else {
      console.warn("unknown node type for toggle expand collapse");
    }
  }
  toggleExpandCollapseLevel_IbGib(node) {
    let t = this;
    switch (node.expandLevel) {
      case 0:
        node.expandLevel = 1;
        t.addSpiffyRel8ns(node);
        t.addCmdVirtualNodes_Default(node);
        break;
      case 1:
        t.addBoringRel8ns(node);
        t.addCmdVirtualNodes_Default(node);
        node.expandLevel = 2;
        break;
      default:
        t.removeAllRel8ns(node);
        node.expandLevel = 0;
    }
  }
  toggleExpandCollapseLevel_Rel8n(rel8nNode) {
    let t = this;

    if (d3AddableRel8ns.includes(rel8nNode.rel8nName) && t.getChildrenCount_Cmds(rel8nNode) === 0) {
      t.addCmdVirtualNode(rel8nNode, "add", t.config.other.cmdFadeTimeoutMs_Specialized);
    } else {
      switch (rel8nNode.expandLevel) {
        case 0:
          let { rel8nName, rel8nSrc } = rel8nNode;
          let srcRel8ns = rel8nSrc.ibGibJson.rel8ns[rel8nName] || [];
          srcRel8ns
            .forEach(rel8dIbGib => {
              t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ rel8dIbGib, /*srcNode*/ rel8nNode, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: rel8nNode.x, y: rel8nNode.y});
            });
          rel8nNode.expandLevel = 1;
          break;

        default:
          t.removeAllRel8ns(rel8nNode);
          rel8nNode.expandLevel = 0;
      }
    }
  }
  /**
   * Adds "important" rel8ns that are not collapsed by default.
   * For example, adds "comment", "pic", etc. rel8ns, but not "dna", "past"
   */
  addSpiffyRel8ns(node) {
    let t = this;

    // Don't add for root node.
    if (node.ibGib === "ib^gib") { return; }

    let fadeTimeoutMs = t.config.other.rel8nFadeTimeoutMs_Spiffy;
    Object.keys(node.ibGibJson.rel8ns)
      .filter(rel8n => !d3BoringRel8ns.includes(rel8n))
      .forEach(rel8n => {
        t.addRel8nVirtualNode(node, rel8n, fadeTimeoutMs);
      });

    d3AddableRel8ns.forEach(rel8n => {
      if (!node.ibGibJson.rel8ns[rel8n]) {
        t.addRel8nVirtualNode(node, rel8n, fadeTimeoutMs);
        // t.addCmdVirtualNode(node, rel8n, t.config.other.cmdFadeTimeoutMs_Default);
      }
    })
  }
  /**
   * Adds "boring" rel8ns that are not collapsed by default.
   * For example, adds "dna", "past", etc., but not "comment", "pic"
   */
  addBoringRel8ns(node) {
    let t = this;

    // Don't add for root node.
    if (node.ibGib === "ib^gib") { return; }

    let fadeTimeoutMs = t.config.other.rel8nFadeTimeoutMs_Boring;
    Object.keys(node.ibGibJson.rel8ns)
      .filter(rel8n => d3BoringRel8ns.includes(rel8n))
      .forEach(rel8n => {
        t.addRel8nVirtualNode(node, rel8n, fadeTimeoutMs);
      });
  }
  removeAllRel8ns(node) {
    let t = this;

    // Don't remove for root node.
    if (node.ibGib === "ib^gib") { return; }

    let directChildNodes =
      t.graphData.links
        .filter(l => l.source.id === node.id)
        .map(l => l.target)
        .forEach(childNode => {
          t.removeAllRel8ns(childNode);
          if (childNode.virtualId) {
            t.removeVirtualNode(childNode);
          } else {
            t.remove(childNode, /*updateParentOrChild*/ true);
          }
        });
  }

  handleEventBusUpdateMsg(ibGib, updateMsg) {
    let t = this;
    console.log(`updateMsg:\n${JSON.stringify(updateMsg)}`)

    if (updateMsg && updateMsg.data && updateMsg.data.old_ib_gib === ibGib && updateMsg.data.new_ib_gib) {

      t.ibGibEventBus.disconnect(ibGib);
      t.graphData.nodes
        .filter(n => n.ibGib === ibGib)
        .forEach(n => t.updateIbGib(n, updateMsg.data.new_ib_gib));
    } else {
      console.warn(`Unused updateMsg(?): ${JSON.stringify(updateMsg)}`);
    }
  }

  updateIbGib(node, newIbGib) {
    let t = this;

    node.ibGib = newIbGib;

    t.swap(node, node, /*updateParentOrChild*/ true);
    node.virtualId = ibHelper.getRandomString();
    t.zapVirtualNode(node);
    t.animateNodeBorder(node, /*nodeShape*/ null);
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

  getNodeShape(d) {
    if (d.ibGibJson && d.ibGibJson.data && d.ibGibJson.data.shape) {
      if (d.ibGibJson.data.shape === "circle") {
        return "circle";
      } else if (d.ibGibJson.data.shape === "rect") {
        return "rect";
      } else {
        return super.getNodeShape(d);
      }
    } else {
      return super.getNodeShape(d);
    }
  }
  getNodeShapeRadius(d) {
    let t = this;
    let multiplier;

    switch (d.type) {
      case "ibGib":
        if (d.isSource) {
          multiplier = d3Scales["source"];
        } else if (d.virtualId && d.ibGib === "ib^gib") {
          multiplier = d3Scales["ibGib"]
        } else if (d.virtualId) {
          multiplier = d3Scales["virtual"];
        } else {
          multiplier = t.getIbGibMultiplier(d);
        }
        break;

      case "cmd":
        multiplier = d3Scales["cmd"];
        break;

      case "rel8n":
        multiplier = d3Scales["rel8n"];
        break;

      default:
        multiplier = d3Scales["default"];
    }

    return d3CircleRadius * multiplier;
  }
  getIbGibMultiplier(d) {
    let t = this;
    if (d.ibGibJson) {
      if (d.ibGibJson.data && d.ibGibJson.data.render) {
        return d3Scales[d.ibGibJson.data.render] || d3Scales["default"];
      } else if (d.ibGib === t.sourceIbGib) {
        return d3Scales["source"];
      } else if (d.ibGib === "ib^gib") {
        return d3Scales["ib^gib"];
      } else {
        return d3Scales[d.ibGibJson.ib] || d3Scales["default"];
      }
    } else {
      console.warn("getIbGibMultiplier assumes d.ibGibJson is truthy...");
      return d3Scales["default"];
    }
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
  getNodeLabelText(d) {
    if (d.type === "ibGib" && d.ibGibJson) {
      if (d.ibGibJson && d.ibGibJson.data) {
        if (d.ibGibJson.data.render &&
            d.ibGibJson.data.render === "text" &&
            d.ibGibJson.data.text) {
          return d.ibGibJson.data.text;
        } else if (d.ibGibJson.data.label) {
          return d.ibGibJson.data.label;
        } else if (d.ibGib === "ib^gib") {
          return "\uf10c";
        } else {
          return d.ibGibJson.ib;
        }
      } else if (d.ibGib === "ib^gib") {
        return "\uf10c";
      } else {
        return d.ibGibJson.ib;
      }
    } else if (d.virtualId && d.type === "ibGib") {
      return "\u26a1";
    } else if (d.type === "cmd" && d.cmd) {
      return d.cmd.icon;
    } else if (d.type === "error") {
      return "\u26a0";
    } else if (d.type === "rel8n") {
      return d3Rel8nIcons[d.rel8nName] || d.rel8nName;
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
    } else if (d.type === "error") {
      return "There was an error...noooooooooo 😱";
    } else {
      return d.id;
    }
  }

  getForceLinkDistance(l) {
    let t = this;
    if (l.source.type === "rel8n") {
      return t.config.simulation.linkDistance_Src_Rel8n;
    } else {
      return super.getForceLinkDistance(l);
    }
  }
  getForceCollideDistance(d) {
    return super.getForceCollideDistance(d) * 1.1;
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

  moveRootToClickPos(event) {
    let t = this;
    let root = t.addRoot();

    // t.freezeNodes(100);
    root.x = event.x;
    root.y = event.y;
    root.fx = event.x;
    root.fy = event.y;
    t.swap(root, root, /*updateParentOrChild*/ true);
  }

  handleBackgroundClicked() {
    let t = this;
    if (t.selectedNode) {
      t.clearSelectedNode();
    } else {
      t.moveRootToClickPos(d3.event);
    }

    if (t.currentCmd) {
      if (t.currentCmd.close) {
        t.currentCmd.close();
      }
      delete t.currentCmd;
    }

    d3.event.preventDefault();
  }
  handleNodeNormalClicked(d) {
    let t = this;
    console.log(`node clicked: ${JSON.stringify(d)}`);

    t.clearSelectedNode();

    t.animateNodeBorder(d, /*nodeShape*/ null);

    t.freezeNodes(500);
    if (d.virtualId) {
      t.zapVirtualNode(d);
    } else {
      t.toggleExpandCollapseLevel(d);
    }
  }
  handleNodeLongClicked(d) {
    let t = this;
    t.clearSelectedNode();
    t.selectNode(d);
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

  // addCmdVirtualNodes_Specialized(d) {
  //   let t = this;
  //
  //   const fadeTimeoutMs = t.config.other.cmdFadeTimeoutMs_Specialized;
  //
  //   if (d.ibGibJson) {
  //     if (t.virtualNodes.filter(x => x.type === "cmd").length === 0) {
  //       return [
  //         t.addCmdVirtualNode(d, "huh", fadeTimeoutMs),
  //         t.addCmdVirtualNode(d, "help", fadeTimeoutMs),
  //       ];
  //     } else {
  //       return [];
  //     }
  //   } else {
  //     // not a loaded ibGibJson, so no virtual nodes to add.
  //     // So we are assuming this is a virtual node itself.
  //     if (!d.virtualId) { console.warn("addCmdVirtualNodes_Default on non-virtual node without ibGibJson"); }
  //     return [];
  //   }
  // }
  addCmdVirtualNodes_Default(d) {
    let t = this;

    const fadeTimeoutMs = t.config.other.cmdFadeTimeoutMs_Default;

    if (d.ibGib === "ib^gib") {
      return [
        t.addCmdVirtualNode(d, "huh", fadeTimeoutMs),
        t.addCmdVirtualNode(d, "help", fadeTimeoutMs),
        t.addCmdVirtualNode(d, "query", fadeTimeoutMs),
        t.addCmdVirtualNode(d, "fork", fadeTimeoutMs),
      ];
    } else {
      if (d.ibGibJson) {
        return [
          t.addCmdVirtualNode(d, "huh", fadeTimeoutMs),
          t.addCmdVirtualNode(d, "help", fadeTimeoutMs),
          t.addCmdVirtualNode(d, "fork", fadeTimeoutMs),
        ];
      } else {
        // not a loaded ibGibJson, so no virtual nodes to add.
        // So we are assuming this is a virtual node itself.
        if (!d.virtualId) { console.warn("addCmdVirtualNodes_Default on non-virtual node without ibGibJson"); }
        return [];
      }
    }
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
    node.rel8nSrc = dSrc;

    return node;
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

  getChildrenCount_Cmds(node) {
    let t = this;
    return t.graphData.links
      .filter(l => l.source.id === node.id && l.target.type === "cmd")
      .length;
  }
  getChildrenCount_Virtual(node) {
    let t = this;
    return t.graphData.links
      .filter(l => l.source.id === node.id && l.target.virtualId)
      .length;
  }
  getChildren_Rel8ns(node) {
    let t = this;
    return t.graphData.links
      .filter(l => l.source.id === node.id && l.target.type === "rel8n");
  }
  getChildrenCount_All(node) {
    let t = this;
    return t.graphData.links
      .filter(l => l.source.id === node.id)
      .length;
  }
}
