import * as d3 from 'd3';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3BoringRel8ns, d3RequireExpandLevel2, d3MenuCommands, d3Rel8nIcons, d3RootUnicodeChar, d3AddableRel8ns } from '../d3params';

import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import { DynamicIbScapeMenu } from './dynamic-ib-scape-menu';
import * as ibHelper from '../services/ibgib-helper';
import { CommandManager } from '../services/commanding/command-manager';
import { IbGibIbScapeBackgroundRefresher } from '../services/ibgib-ib-scape-background-refresher';

/**
 * This is the ibGib d3 graph that contains all the stuff for our IbGib data
 * interaction. So on the client side, this is the big enchilada.
 *
 *
 */
export class DynamicIbScape extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, baseJsonPath, ibGibCache, ibGibImageProvider, sourceIbGib, ibGibSocketManager, ibGibEventBus, isPrimaryIbScape) {
    super(graphDiv, svgId, {});
    let t = this;

    t.baseJsonPath = baseJsonPath;
    t.ibGibCache = ibGibCache;
    t.ibGibImageProvider = ibGibImageProvider;
    t.ibGibSocketManager = ibGibSocketManager;
    t.ibGibEventBus = ibGibEventBus;
    t.commandMgr = new CommandManager(t, ibGibSocketManager);
    t.virtualNodes = {};
    t.isPrimaryIbScape = isPrimaryIbScape;

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
        velocityDecay: 0.75,
        chargeStrength: 135,
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
        rootFadeTimeoutMs: 7777,
        rootFadeTimeoutMs_Fast: 777,
        cmdFadeTimeoutMs_Default: 4000,
        cmdFadeTimeoutMs_Specialized: 10000,
        rel8nFadeTimeoutMs_Boring: 4000,
        rel8nFadeTimeoutMs_Spiffy: 0,
      }
    }
    t.config = $.extend({}, defaults, config || {});

    t.contextIbGib = sourceIbGib || "ib^gib";
  }
  destroy() {
    let t = this;
    if (t.backgroundRefresher) { t.backgroundRefresher.destroy(); }
    super.destroy();
  }

  init() {
    super.init();
    let t = this;

    console.log("init");
    t.commandMgr.init();

    t.initNoScrollHtmlAndBody();
    t.initCloseDetails();
    t.initResize();
    t.initRoot();
    t.initBackgroundRefresher();
    t.initContext();
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
  initRoot() {
    let t = this;
    t.rootPos = {x: t.center.x, y: t.center.y};
    t.addRootNode();
  }
  initContext() {
    let t = this;

    t.addContextNode();

    window.onpopstate = (event) => {
      console.warn("pop state triggered");
      delete t.contextNode.ibGibJson;
      // Trim /ibgib/ or ibgib/ to get the ib^gib from the pathname
      let leadingTrimLength = window.location.pathname[0] === "/" ? 7 : 6;
      let newContextIbGib = window.location.pathname.replace("%5E", "^").substring(leadingTrimLength);

      t.updateIbGib(t.contextNode,
                    newContextIbGib,
                    /*skipUpdateUrl*/ true,
                    () => t.syncContextChildren());
    }

    t.refreshContextNode();
  }
  refreshContextNode() {
    let t = this;

    if (t.contextNode) {
      t.backgroundRefresher.exec([t.contextNode.ibGib], successMsg => {
        // now we can refresh the source nodes.
        t.getIbGibJson(t.contextNode.ibGib, ibGibJson => {
          let ibGibsToRefresh =
            Object.keys(ibGibJson.rel8ns)
              .filter(rel8nName => rel8nName === "ib^gib" || !d3BoringRel8ns.includes(rel8nName))
              .map(rel8nName => ibGibJson.rel8ns[rel8nName])
              .reduce((acc, rel8nIbGibs) => {
                rel8nIbGibs.forEach(rel8nIbGib => {
                  if (!acc.includes(rel8nIbGib) && rel8nIbGib !== "ib^gib") {
                    acc.push(rel8nIbGib)
                  }
                });
                return acc;
              }, []);
          console.log(`Initial source node ibGibs to refresh: ${JSON.stringify(ibGibsToRefresh)}`);
          if (ibGibsToRefresh.length > 0) {
            t.backgroundRefresher.exec(ibGibsToRefresh, successMsg => {
              console.log(`Initial refresh source nodes complete. successMsg: ${JSON.stringify(successMsg)}`);
            }, errorMsg => {
              console.error(`Error on initial refresh source nodes: ${JSON.stringify(errorMsg)}`);
            });
          }
        });
      },
      errorMsg => {
        console.error("Error on context node initial refresh.")
      });
    }
  }
  initBackgroundRefresher() {
    let t = this;
    // only init if we don't already have a refresher.
    if (t.backgroundRefresher) { return; }

    t.backgroundRefresher = new IbGibIbScapeBackgroundRefresher(t);

    t.backgroundRefresher
      .start(
        successMsg => {
          if (successMsg && successMsg.data && successMsg.data.latest_ib_gibs) {
            console.log(`Background refresher found newer ibGibs. latest_ib_gibs:  ${JSON.stringify(successMsg.data.latest_ib_gibs)}`);
          }
        },
        errorMsg => {
          console.error(`Error background refresher: ${JSON.stringify(errorMsg)}`);
        },
        /*intervalMs*/ 5000);
        // It checks on this interval, but does not necessarily execute if there
        // are no ibGibs in the queue.
  }

  /** Adds the root */
  addRootNode() {
    let t = this;
    console.log("addRootNode");

    // Remove existing rootNode (if exists)
    if (t.rootNode) {
      t.rootPos.x = t.rootNode.x;
      t.rootPos.y = t.rootNode.y;

      t.clearFadeTimeout(t.rootNode);
      t.remove(t.rootNode);
    }

    // Setup the rootNode params based on environment.
    let nonRootNodeCount = t.graphData.nodes.length;
    let rootId = t.getUniqueId("root"),
        rootType = "ibGib",
        rootIbGib = "ib^gib",
        rootShape = "circle";
    let autoZap,
        fadeTimeoutMs,
        rootPulseMs;
    if (nonRootNodeCount === 0) {
      // There are no nodes, so pulse the root and don't auto zap it.
      // This lets any new users learn about clicking and zapping.
      autoZap = false;
      fadeTimeoutMs = 5000;
      rootPulseMs = 3000;
    } else {
      // There are other nodes, so don't pulse the root, just let it fade.
      autoZap = true;
      fadeTimeoutMs = t.config.other.rootFadeTimeoutMs;
      rootPulseMs = 0;
    }

    // Add the rootNode
    t.rootNode = t.addVirtualNode(rootId, rootType, rootIbGib, /*srcNode*/ null, rootShape, autoZap, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ null, /*label*/ null, /*startPos*/ null, /*isAdjunct*/ false);

    if (!t.contextIbGib || t.contextIbGib === "ib^gib") {
      t.rootNode.isSource = true;
    }
    t.rootNode.isRoot = true;
    // Restore the rootNode's position if we were replacing an existing one.
    t.rootNode.x = t.rootPos.x;
    t.rootNode.y = t.rootPos.y;

    // Pulse if applicable (see above)
    if (rootPulseMs) {
      // Call recursively. If it was succesfully added and subsequently
      // zapped by the user, then we won't be at this point.
      clearTimeout(t.rootPulseTimer);
      t.rootPulseTimer =
        setTimeout(() => t.addRootNode(), fadeTimeoutMs + rootPulseMs);
    }
  }

  addContextNode() {
    let t = this;

    // If already exists, immediately return.
    if (t.contextNode) { return; }

    if (t.contextIbGib && t.contextIbGib !== "ib^gib") {
      let { ib } = ibHelper.getIbAndGib(t.contextIbGib),
          srcId = t.getUniqueId("src"),
          srcType = "ibGib",
          srcShape = t.getNodeShapeFromIb(ib),
          autoZap = true,
          fadeTimeoutMs = 0;

      t.contextNode = t.addVirtualNode(srcId, srcType, t.contextIbGib, /*srcNode*/ null, srcShape, autoZap, fadeTimeoutMs, /*cmd*/ null, /*title*/ null, /*label*/ null, /*startPos*/ {x: t.rootNode.x, y: t.rootNode.y}, /*isAdjunct*/ false);
      t.contextNode.isContext = true;

      t.syncContextChildren();
    } else {
      console.warn(`No contextNode set. (t.contextIbGib is ${t.contextIbGib})`);
    }
  }

  syncContextChildren() {
    let t = this;
    t.setBusy(t.contextNode);
    t.getIbGibJson(t.contextNode.ibGib, ibGibJson => {
      console.log(`got context's json: ${JSON.stringify(ibGibJson)}`);
      t.contextNode.ibGibJson = ibGibJson;
      t.contextNode.tempJuncIbGib =
        ibHelper.getTemporalJunctionIbGib(ibGibJson);
      try {
        // Prune vestigial rel8nNodes first, because they will not be covered
        // in iterating the current rel8ns (next).
        let rel8nNames = Object.keys(ibGibJson.rel8ns);
        let rel8nNodes = t.pruneRel8nNodes(t.contextNode, rel8nNames);

        // Iterate rel8ns
        rel8nNames
          .forEach(rel8nName => {
            let rel8nIbGibs = ibGibJson.rel8ns[rel8nName];
            if (rel8nName === "ib^gib") {
              t.syncContextSourceNodes(rel8nIbGibs);
            }

            t.syncContextRel8nNode(rel8nName, rel8nNodes, rel8nIbGibs);
            // t.syncContextAdjuncts();
          });

        // If we've just gone back in history and there are no rel8ns via
        // ib^gib, then we should sync with an empty array.
        if (!rel8nNames.includes("ib^gib")) {
          t.syncContextSourceNodes(/*rel8nIbGibs*/ []);
        }

      } catch (e) {
        console.error(`error syncing context children: ${e}`)
      } finally {
        t.clearBusy(t.contextNode);
      }
    });
  }

  syncAdjuncts(tempJuncIbGib) {
    let t = this;
    if (tempJuncIbGib === t.contextNode.tempJuncIbGib) {
      t.syncContextAdjuncts();
    }
  }

  /**
   * Syncs the adjuncts for the contextNode only. We need separate code for
   * the context, because it behaves differently than other ibGib nodes.
   *
   * Note: Right now to simplify things, we're pretending that adjuncts do not
   * change (i.e. the user doesn't edit their comment).
   */
  syncContextAdjuncts() {
    let t = this;
    let contextIbGibJson = t.contextNode.ibGibJson;
    if (!contextIbGibJson) { console.warn("no contextIbGibJson. this is assumed to be populated at this point."); }

    let adjunctInfos = t.ibGibCache.getAdjunctInfos(t.contextNode.tempJuncIbGib);

    if (adjunctInfos && adjunctInfos.length > 0) {
      // If the adjunct ibGib has been "assimilated" into the user's scene
      // directly, then we no longer need to show it as an "adjunct". So filter
      // those out.
      // So, "!some(rel8ns)" pointing to the adjunctIbGib
      adjunctInfos =
        adjunctInfos.filter(info => {
          return !Object.keys(contextIbGibJson.rel8ns)
            .map(key => contextIbGibJson.rel8ns[key])
            .some(rel8nIbGibs => rel8nIbGibs.includes(info.adjunctIbGib))
        });

      let adjunctSourceNodes =
        t.graphData.nodes.filter(n => n.isSource && n.id !== t.contextNode.id && !n.isRoot && n.isAdjunct);

      // prune
      adjunctSourceNodes
        .filter(n => !adjunctInfos.some(info => info.adjunctIbGib))
        .forEach(n => t.removeNodeAndChildren(n));

      // reeval after pruning
      adjunctSourceNodes =
        t.graphData.nodes.filter(n => n.isSource && n.id !== t.contextNode.id && !n.isRoot && n.isAdjunct);

      adjunctInfos
        .filter(info => !adjunctSourceNodes.some(sn => sn.ibGib === info.adjunctIbGib))
        .forEach(info => {
          let newNode = t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ info.adjunctIbGib, /*srcNode*/ null, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: t.contextNode.x, y: t.contextNode.y}, /*isAdjunct*/ true);
        });
    }
  }

  pruneRel8nNodes(node, rel8nNames) {
    let t = this;
    t.getChildren(node)
      .filter(n => n.type === "rel8n")
      .filter(n => !rel8nNames.includes(n.rel8nName))
      .forEach(n => t.remove(n));

    return t.getChildren(node).filter(n => n.type === "rel8n");
  }

  /**
   * The source nodes are the ib^gib/ib rel8ns to this.contextNode.
   * These appear as "free-floating" ibGib source nodes, not connected to a
   * rel8n node.
   */
  syncContextSourceNodes(ibGibs) {
    let t = this;
    let sourceNodes =
      t.graphData.nodes.filter(n => n.isSource && n.id !== t.contextNode.id && !n.isRoot);

    // not optimized :scream:

    // prune
    sourceNodes
      .filter(sourceNode => !ibGibs.includes(sourceNode.ibGib))
      .forEach(nodeNotFound => t.removeNodeAndChildren(nodeNotFound));

    // add
    let newIbGibs =
      ibGibs.filter(ibGib => !sourceNodes.some(sn => sn.ibGib === ibGib));

    newIbGibs
      .forEach(ibGib => {
        t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ ibGib, /*srcNode*/ null, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: t.contextNode.x, y: t.contextNode.y}, /*isAdjunct*/ false);
      });

    if (newIbGibs && newIbGibs.length > 0) {
      t.backgroundRefresher.exec(newIbGibs,
        successMsg => {
          console.log("syncContextSourceNodes: refresh newIbGibs succeeded.")
        },
        errorMsg => {
          console.error(`syncContextSourceNodes: refresh newIbGibs failed. Error: ${JSON.stringify(errorMsg)}`)
        });
    }
  }

  removeNodeAndChildren(node) {
    let t = this;
    let children = t.getChildren(node);
    children.forEach(child => t.removeNodeAndChildren(child));
    t.remove(node, /*updateParentOrChild*/ true);
  }

  /**
   * Each rel8n of this.contextNode that is not ib^gib or ib will have a
   * rel8n node that other ibGibs will be connected to.
   */
  syncContextRel8nNode(rel8nName, rel8nNodes, ibGibs) {
    let t = this;
    // Be sure that there is a rel8n node.
    let rel8nNode = rel8nNodes.filter(n => n.rel8nName === rel8nName);

    if (rel8nNode) {
      // rel8nNode exists. If expanded, ensure children are up-to-date.
      let children = t.getChildren(rel8nNode);
      if (children.length > 0) {
        // prune
        children
          .filter(child => !ibGibs.includes(child.ibGib))
          .forEach(nodeNotFound => t.removeNodeAndChildren(nodeNotFound));

        // add
        ibGibs
          .filter(ibGib => !children.some(child => child.ibGib === ibGib))
          .forEach(ibGib => {
            t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ ibGib, /*srcNode*/ rel8nNode, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: rel8nNode.x, y: rel8nNode.y}, /*isAdjunct*/ false);
          });
      }
    } else {
      // rel8nNode does not yet exist.
      // do nothing?

      // let fadeTimeoutMs =
      //   d3BoringRel8ns.includes(rel8nName) ?
      //   t.config.other.rel8nFadeTimeoutMs_Boring :
      //   t.config.other.rel8nFadeTimeoutMs_Spiffy;
      // Object.keys(node.ibGibJson.rel8ns)
      //   .filter(rel8n => !d3BoringRel8ns.includes(rel8n))
      //   .forEach(rel8n => {
      //     t.addRel8nVirtualNode(t.contextNode, rel8nName, /*fadeTimeoutMs*/ 0);
      //   });
    }
  }

  getNodeShapeFromIb(ib) {
    return ib === "comment" ? "rect" : "circle";
  }

  createVirtualNode(id, type, nameOrIbGib, shape, cmd, title, label, isAdjunct) {
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

    if (isAdjunct) {
      virtualNode.isAdjunct = true;
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
  addVirtualNode(id, type, nameOrIbGib, srcNode, shape, autoZap, fadeTimeoutMs, cmd, title, label, startPos, isAdjunct) {
    let t = this;

    let virtualNode = t.createVirtualNode(id, type, nameOrIbGib, shape, cmd, title, label, isAdjunct);
    if (startPos) {
      virtualNode.x = startPos.x;
      virtualNode.y = startPos.y;
    }

    let links = srcNode ? [{ source: srcNode, target: virtualNode }] : [];
    t.add([virtualNode], links, /*updateParentOrChild*/ true);

    if (srcNode) {
      t.animateNodeBorder(/*d*/ srcNode, /*nodeShape*/ null);
    } else {
      virtualNode.isSource = true;
    }

    t.animateNodeBorder(/*d*/ virtualNode, /*nodeShape*/ null);

    t.virtualNodes[virtualNode.id] = virtualNode;

    if (type !== "cmd" && autoZap) {
      t.zapVirtualNode(virtualNode);
    } else if (fadeTimeoutMs) {
      t.fadeOutNode(virtualNode, fadeTimeoutMs);
    }

    return virtualNode;
  }
  fadeOutNode(node, fadeTimeoutMs) {
    let t = this;
    console.log("fading out...");

    t.clearFadeTimeout(node);

    let transition =
      d3.transition()
        .duration(fadeTimeoutMs)
        .ease(d3.easeLinear);

    d3.select("#" + node.id)
      .attr("opacity", 1)
      .transition(transition)
      .attr("opacity", 0.1);

    node.fadeTimer = setTimeout(() => {
      t.removeVirtualNode(node, /*keepInGraph*/ false);
    }, fadeTimeoutMs);
  }
  removeVirtualNode(node, keepInGraph) {
    let t = this;
    delete t.virtualNodes[node.id];

    t.clearFadeTimeout(node);

    if (!keepInGraph) {
      if (t.graphData.nodes.some(n => n.id === node.id)) {
        t.removeNodeAndChildren(node);
        // t.remove(node, /*updateParentOrChild*/ true);
      }
    }
  }
  removeAllVirtualNodes() {
    let t = this;

    let toRemove = Object.keys(t.virtualNodes).map(nodeId => t.virtualNodes[nodeId]);
    toRemove
      .forEach(node => {
        if (node.fadeTimer) {
          clearTimeout(node.fadeTimer);
          delete node.fadeTimer;
        }
      // virtual nodes aren't supposed to have children, but shotgunning here.
        t.removeNodeAndChildren(node);
      })
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
      if (!n.fx && !n.fy) {
        n.fx = n.x;
        n.fy = n.y;
        n.frozen = true;
      }
    });

    setTimeout(() => {
      t.graphData.nodes.forEach(n => {
        if (n.frozen) {
          delete n.fx;
          delete n.fy;
          delete n.fixedBeforeFreeze;
          delete n.frozen;
        }
      });
    }, durationMs);
  }

  zapVirtualNode(virtualNode) {
    let t = this;

    t.clearFadeTimeout(virtualNode);

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

    if (t.rootPulseTimer) {
      clearTimeout(t.rootPulseTimer);
      delete t.rootPulseTimer;
    }

    t.getIbGibJson(node.ibGib, ibGibJson => {
      console.log(`got json: ${JSON.stringify(ibGibJson)}`);
      node.ibGibJson = ibGibJson;

      t.updateRender(node);

      t.removeVirtualNode(node, /*keepInGraph*/ true);
      delete node.virtualId;
      t.swap(node, node, /*updateParentOrChild*/ true);

      if (node.ibGib !== "ib^gib") {
        let tempJuncIbGib = ibHelper.getTemporalJunctionIbGib(ibGibJson);

        t.ibGibEventBus.connect(/*connectionId*/ node.id, tempJuncIbGib, msg => {
          switch (msg.metadata.name) {
            case "update":
              t.handleEventBusMsg_Update(tempJuncIbGib, node.ibGib, msg);
              break;
            case "adjuncts":
              t.handleEventBusMsg_Adjuncts(tempJuncIbGib, node.ibGib, msg);
              break;
            default:
              console.error(`Unhandled/invalid msg received on event bus. Msg: ${JSON.stringify(msg)}`)
          }
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
      t.removeAllVirtualNodes();
      // t.removeVirtualCmdNodes();
      t.addCmdVirtualNodes_Default(node);
    } else if (node.type === "ibGib") {
      t.removeAllVirtualNodes();
      // t.removeVirtualCmdNodes();
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
        // t.addCmdVirtualNodes_Default(node);
        node.expandLevel = 2;
        break;
      default:
        t.removeAllRel8ns(node);
        node.expandLevel = 0;
    }
  }
  toggleExpandCollapseLevel_Rel8n(rel8nNode) {
    let t = this;
    // t.removeVirtualCmdNodes();
    t.removeAllVirtualNodes();

    switch (rel8nNode.expandLevel) {
      case 0:
        if (d3AddableRel8ns.includes(rel8nNode.rel8nName)) {
          t.addCmdVirtualNode(rel8nNode, "add", t.config.other.cmdFadeTimeoutMs_Specialized);
          rel8nNode.showingAdd = true;
          if (rel8nNode.toggleExpandTimer) {
            clearTimeout(rel8nNode.toggleExpandTimer);
          }
          rel8nNode.toggleExpandTimer = setTimeout(() => {
            console.log("clearing rel8nNode.showingAdd")
            delete rel8nNode.showingAdd;
          }, t.config.other.cmdFadeTimeoutMs_Specialized);
        }
        let { rel8nName, rel8nSrc } = rel8nNode;
        let srcRel8ns = rel8nSrc.ibGibJson.rel8ns[rel8nName] || [];
        srcRel8ns
          .forEach(rel8dIbGib => {
            t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ rel8dIbGib, /*srcNode*/ rel8nNode, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: rel8nNode.x, y: rel8nNode.y}, /*isAdjunct*/ false);
          });
        rel8nNode.expandLevel = 1;
        break;

      default:
        if (d3AddableRel8ns.includes(rel8nNode.rel8nName) && !rel8nNode.showingAdd) {
          t.addCmdVirtualNode(rel8nNode, "add", t.config.other.cmdFadeTimeoutMs_Specialized);
        } else {
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
        // Don't add the ib^gib rel8n for the context node, because these
        // children are shown in the environment as free-floating ibGib.
        if (!(node.isContext && rel8n === "ib^gib")) {
          t.addRel8nVirtualNode(node, rel8n, fadeTimeoutMs);
        }
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

  handleEventBusMsg_Update(tempJuncIbGib, ibGib, msg) {
    let t = this;
    console.log(`msg:\n${JSON.stringify(msg)}`)

    if (msg && msg.data &&
        msg.data.first_ib_gib === tempJuncIbGib &&
        msg.data.new_ib_gib) {
      t.graphData.nodes
        .filter(n => n.ibGib === ibGib)
        .forEach(n => {
          console.log(`updating ibGib node`)
          t.clearBusy(n);
          // ibGib in the "past" rel8n will be paused, because we don't want to
          // update those, rather we want to keep them at that particular frame
          // in time. There may be other use cases for pausing (e.g. user
          // pauses the ibGib for whatever reason, or possibly when we navigate
          // to an ibGib in the past rel8n).
          if (n.isPaused) {
            console.log(`msg received, but node ${n.id} is paused.`);
          } else {
            t.updateIbGib(n,
                          msg.data.new_ib_gib,
                          /*skipUpdateUrl*/ false,
                          /*callback*/ null);
          }
        });
    } else {
      console.warn(`Unused msg(?): ${JSON.stringify(msg)}`);
    }
  }

  handleEventBusMsg_Adjuncts(tempJuncIbGib, ibGib, msg) {
    let t = this;
    console.log(`msg:\n${JSON.stringify(msg)}`)
    if (msg && msg.data && msg.data.ib_gib === tempJuncIbGib) {
      let adjunctIbGibs =
        msg.data.adjunct_ib_gibs
          .filter(adjunctIbGib => {
            // For now, filter for only comments, pics, and links. In the
            // future, this will have to be generalized (or not filtered at
            // this stage)
            let adjunctIb = ibHelper.getIbAndGib(adjunctIbGib).ib;
            return adjunctIb === "comment" || adjunctIb === "pic" || adjunctIb === "link";
          })
          .forEach(adjunctIbGib => {
            t.getIbGibJson(adjunctIbGib, adjunctIbGibJson => {
              t.ibGibCache.addAdjunctInfo(tempJuncIbGib, ibGib, adjunctIbGib, adjunctIbGibJson);
              t.syncAdjuncts(tempJuncIbGib);
            });
          })
    } else {
      console.warn(`Unused msg(?): ${JSON.stringify(msg)}`);
    }
  }

  updateIbGib(node, newIbGib, skipUpdateUrl, callback) {
    let t = this;

    node.ibGib = newIbGib;

    t.swap(node, node, /*updateParentOrChild*/ true);
    node.virtualId = ibHelper.getRandomString();
    t.zapVirtualNode(node);

    if (!skipUpdateUrl) {
      if (node.isContext) {
        // update URL
        history.pushState({ibGib: node.ibGib, ibGibJson: node.ibGibJson}, "_", newIbGib);
        t.syncContextChildren();
      }
    }

    t.animateNodeBorder(node, /*nodeShape*/ null);

    if (callback) { callback(); }
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

  clearFadeTimeout(node) {
    let t = this;

    if (node.fadeTimer) {
      clearTimeout(node.fadeTimer);
      delete node.fadeTimer;
    }

    d3.select("#" + t.getNodeShapeId(node.id))
      .attr("opacity", d => t.getNodeShapeOpacity(d))
      .transition(); // resets/"removes" the fade transition
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
        if (d.isContext) {
          multiplier = d3Scales["context"];
        } else if (d.isSource) {
          multiplier = d3Scales["source"];
        } else if (d.isRoot) {
          multiplier = d3Scales["root"];
        } else if (d.virtualId && d.ibGib === "ib^gib") {
          multiplier = d3Scales["ib^gib"]
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
      } else if (d.ibGib === t.contextIbGib) {
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

        if (d.isContext) {
          index = "context";
        } else if (d.ibGib === "ib^gib") {
          index = "ibGib";
        } else if (d.render && d.render === "text") {
          index = "text";
        } else if (d.render && d.render === "image") {
          index = "image";
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
    if (d.virtualId) {
      return "16,8,16";
    } else if (d.isAdjunct) {
      return "7,7,7";
    } else {
      return null;
    }
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
          return d3RootUnicodeChar;
        } else {
          return d.ibGibJson.ib;
        }
      } else if (d.ibGib === "ib^gib") {
        return d3RootUnicodeChar;
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

  /** Overridden to remove the center force. Much more tolerable this way. */
  getForceCenter() { return null; }
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

    if (t.rootNode) { t.clearFadeTimeout(t.rootNode); }

    t.addRootNode();

    let transform = ibHelper.parseTransformString(t.svgGroup.attr("transform"));

    let trans =
      d3.transition()
        .duration(75)
        .ease(d3.easeLinear);

    t.rootNode.x = (event.clientX - transform.translateX) / transform.scaleX;
    t.rootNode.y = (event.clientY - transform.translateY) / transform.scaleY;
    t.rootNode.fx = t.rootNode.x;
    t.rootNode.fy = t.rootNode.y;
    t.rootPos.x = t.rootNode.x;
    t.rootPos.y = t.rootNode.y;
    t.swap(t.rootNode, t.rootNode, /*updateParentOrChild*/ true);

    t.animateNodeBorder(t.rootNode, /*nodeShape*/ null);
  }

  handleDragged(d) {
    super.handleDragged(d);
    let t = this;
    if (d.isRoot) {
      t.rootPos.x = d.x;
      t.rootPos.y = d.y;
      t.clearFadeTimeout(d);
    }
  }
  handleDragEnded(d) {
    let t = this;
    super.handleDragEnded(d);
    if (d.isRoot) {
      t.fadeOutNode(d, t.config.other.rootFadeTimeoutMs);
    }
  }
  handleBackgroundClicked() {
    let t = this;
    if (t.selectedNode) {
      t.clearSelectedNode();
    } else {
      t.removeAllVirtualNodes();
      // t.removeVirtualCmdNodes();
      t.moveRootToClickPos(d3.event);
      t.fadeOutNode(t.rootNode, t.config.other.rootFadeTimeoutMs);
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
    if (!d.isRoot) { t.fadeOutNode(t.rootNode, t.config.other.rootFadeTimeoutMs_Fast); }

    // t.freezeNodes(500);
    if (d.virtualId) {
      t.zapVirtualNode(d);
    } else {
      t.toggleExpandCollapseLevel(d);
    }


  }
  handleNodeLongClicked(d) {
    let t = this;
    if (d.virtualId) {
      t.commandMgr.exec(d, d3MenuCommands.filter(c => c.name === "huh")[0]);
      // t.zapVirtualNode(d);
    } else if (d.type === "ibGib") {
      t.clearSelectedNode();
      t.selectNode(d);
    } else if (d.type === "rel8n") {
      t.toggleExpandCollapseLevel_Rel8n(d);
    }
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

    if (t.currentCmd && t.currentCmd.repositionView) {
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

    let node = t.addVirtualNode(t.getUniqueId(`${dSrc.id}_${cmdName}`), /*type*/ "cmd", `${cmdName}^gib`, /*srcNode*/ dSrc, "circle", /*autoZap*/ false, fadeTimeoutMs, cmd, /*title*/ null, /*label*/ null, /*startPos*/ {x: dSrc.x, y: dSrc.y}, /*isAdjunct*/ false);
    node.cmdTarget = dSrc;
  }

  addRel8nVirtualNode(dSrc, rel8nName, fadeTimeoutMs) {
    let t = this;

    let title = rel8nName in d3Rel8nIcons ? d3Rel8nIcons[rel8nName] : "";
    let node = t.addVirtualNode(t.getUniqueId(`${dSrc.id}_${rel8nName}`), /*type*/ "rel8n", `rel8n^gib`, /*srcNode*/ dSrc, "circle", /*autoZap*/ false, fadeTimeoutMs, /*cmd*/ null, title, /*label*/ rel8nName, /*startPos*/ {x: dSrc.x, y: dSrc.y}, /*isAdjunct*/ false);
    node.rel8nSrc = dSrc;

    return node;
  }

  addAdjunctVirtualNode(adjunctIbGibJson, dSrc) {
    let adjunctRel8n = adjunctIbGibJson.data.adjunct_rel8n;
    let srcIbGib = adjunctIbGibJson.data.rel8ns[adjunctRel8n];
    debugger;
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
  getChildren(node) {
    let t = this;
    return t.graphData.links
      .filter(l => l.source.id === node.id)
      .map(l => l.target);
  }
  getChildrenCount_All(node) {
    return this.getChildren(node).length;
  }
}
