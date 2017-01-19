import * as d3 from 'd3';

// var md = require('markdown-it')('commonmark');
var md = require('markdown-it')({
  html: true,
  linkify: true,
  typographer: true,
});
var emoji = require('markdown-it-emoji');
md.use(emoji);

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3BoringRel8ns, d3AlwaysRel8ns, d3RequireExpandLevel2, d3MenuCommands, d3Rel8nIcons, d3RootUnicodeChar, d3AddableRel8ns, d3PausedRel8ns } from '../d3params';

import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';
import { DynamicIbScapeMenu } from './dynamic-ib-scape-menu';
import * as ibHelper from '../services/ibgib-helper';
import * as ibAuthz from '../services/ibgib-authz';
import { CommandManager } from '../services/commanding/command-manager';
import * as commands from '../services/commanding/commands';
import { IbGibIbScapeBackgroundRefresher } from '../services/ibgib-ib-scape-background-refresher';

/**
 * This is the ibGib d3 graph that contains all the stuff for our IbGib
 * data interaction. So on the client side, this is the big enchilada.
 */
export class DynamicIbScape extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config, baseJsonPath, ibGibCache, ibGibImageProvider, sourceIbGib, ibGibSocketManager, ibGibEventBus, isPrimaryIbScape, ibGibProvider, currentIdentityIbGibs) {
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
    t.ibGibProvider = ibGibProvider;
    t.currentIdentityIbGibs = currentIdentityIbGibs;

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
        chargeStrength: -1000,
        chargeDistanceMin: 10,
        chargeDistanceMax: 300,
        linkDistance: 65,
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
        rootPulseMs: 777,
        cmdFadeTimeoutMs_Default: 4000,
        cmdFadeTimeoutMs_Specialized: 10000,
        rel8nFadeTimeoutMs_Boring: 4000,
        rel8nFadeTimeoutMs_Spiffy: 10000,
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
    t.initIdentities();
  }
  initSvg() {
    super.initSvg();
    let t = this;
    t.initSvgGradients();
  }
  initSvgGradients() {
    let t = this;
    
    t.svgGradientId_Context = "context" + ibHelper.getRandomString();
    t.addSvgGradient_Simple(t.svgGradientId_Context, "#F7FF9E", "#F2EC41", "gold");
    
    t.svgGradientId_Root = "root" + ibHelper.getRandomString();
    t.addSvgGradient_Simple(t.svgGradientId_Root, "#30B315", "green", "darkgreen");

    t.svgGradientId_Comment = "comment" + ibHelper.getRandomString();
    t.addSvgGradient_Simple(t.svgGradientId_Comment, "#D8EB6E", "#AFD147", "#91BD1A", "50%", "50%", "40%", "50%", "90%");
    // t.addSvgGradient_Simple(t.svgGradientId_Comment, "#D8EB6E", "#AFD147", "#91BD1A");

    t.svgGradientId_Image = "image" + ibHelper.getRandomString();
    t.addSvgGradient_Simple(t.svgGradientId_Image, "#590782", "#0FF21E", "#0FF21E", "50%", "50%", "40%", "50%", "90%");
    // t.addSvgGradient_Simple(t.svgGradientId_Image, "#AD9DFA", "#9B2ED1", "#6E368A");

    t.svgGradientId_Rel8n = "rel8n" + ibHelper.getRandomString();
    t.addSvgGradient_Simple(t.svgGradientId_Rel8n, "#90C3D4", "#71A3EB", "#61A1FA");
    
    t.svgGradientId_Background = "background" + ibHelper.getRandomString();
    t.addSvgGradient_Simple(t.svgGradientId_Background, "#108201", "#128C01", "#3FA132", "50%", "50%", "50%", "60%", "70%");
    
    t.svgGradientId_Default = "default" + ibHelper.getRandomString();
    t.addSvgGradient_Simple(t.svgGradientId_Default, "#72DFED", "#56CCDB", "#31C1D4");
  }
  /**
   * Adds a simple radialGradient to t.svg.
   * Thanks! https://jsfiddle.net/IPWright83/f76zL96e/
   */
  addSvgGradient_Simple(id, color1, color2, color3, cXY, fXY, offset1, offset2, offset3) {
    let t = this;
    let gradient = t.svg
      .append("radialGradient")
      .attr("xmlns", "http://www.w3.org/2000/svg")
      .attr("id", id)
      .attr("cx", cXY || "10%")
      .attr("cy", cXY || "10%")
      .attr("r", "100%")
      .attr("fx", fXY || "30%")
      .attr("fy", fXY || "30%");
    gradient
      .append("stop")
      // .attr("stop-color", "rgb(192,0,0)")
      .attr("stop-color", color1)
      .attr("offset", offset1 || "0%");
    gradient
      .append("stop")
      // .attr("stop-color", "rgb(127,0,0)")
      .attr("stop-color", color2)
      .attr("offset", offset2 || "10%");
    gradient
      .append("stop")
      // .attr("stop-color", "rgb(64,0,0)")
      .attr("stop-color", color3)
      .attr("offset", offset3 || "85%");
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
  initIdentities() {
    let t = this;

    t.currentIdentityIbGibs
      .forEach(identityIbGib =>
        t.connectToEventBus_Identity(identityIbGib)
      );
  }

  refreshContextNode() {
    let t = this, lc = `refreshContextNode`;

    if (t.contextNode) {
      t.backgroundRefresher.exec([t.contextNode.ibGib], successMsg => {
        let newContextIbGib = successMsg.latest_ib_gibs ?
          successMsg.latest_ib_gibs[t.contextNode.ibGib] :
          t.contextNode.ibGib;

        t.updateIbGib(t.contextNode, newContextIbGib, /*skipUpdateUrl*/ false, () => {

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
            console.log(`${lc} Initial source node ibGibs to refresh: ${JSON.stringify(ibGibsToRefresh)}`);
            t.refreshIbGibs(ibGibsToRefresh, /*callback*/ null);
          });

        });
      },
      errorMsg => { // error refreshing contextNode
        console.error("Error on context node initial refresh.")
      });
    }
  }
  refreshIbGibs(ibGibs, callback) {
    let t = this, lc = `refreshIbGibs(ibGibs: ${JSON.stringify(ibGibs)})`;

    t.backgroundRefresher.exec(ibGibs, successMsg => {
      // console.log(`${lc} Initial refresh source nodes complete. successMsg: ${JSON.stringify(successMsg)}`);
        if (successMsg && successMsg.data) {
          let latestIbGibs = successMsg.data.latest_ib_gibs || {};
          Object.keys(latestIbGibs)
            .forEach(oldIbGib => {
              t.getIbGibJson(oldIbGib, oldIbGibJson => {
                let oldTempJunc = ibHelper.getTemporalJunctionIbGib(oldIbGibJson);
                let newIbGib = latestIbGibs[oldIbGib];
                t.ibGibEventBus.broadcastIbGibUpdate_LocallyOnly(oldTempJunc, newIbGib);
              });
            });
        } else if (successMsg === null) {
          console.log(`${lc} Nothing to refresh.`);
        } else {
          console.error(`${lc} successMsg.data problem.`);
        }
        if (callback) { callback(); }
    }, errorMsg => {
      console.error(`Error on refresh ibGibs. errorMsg: ${JSON.stringify(errorMsg)}`);
      if (callback) { callback(); }
    });
  }

  // Updates -------------------------------

  updateNodeLabels() {
    let t = this;

    t.graphNodesEnter_Comments =
      t.graphNodesEnter
        .filter(d => {
          return ["text", "link"].includes(t.getNodeRenderType(d) || "");
        })
        .append("foreignObject")
          .attr("id", d => t.getUniqueId(d.id, "label", "foreignObject"))
          .attr("width", d => 2 * t.getNodeShapeRadius(d))
          .attr("height", d => 2 * t.getNodeShapeRadius(d))
          .attr("x", d => (-1) * t.getNodeShapeRadius(d))
          .attr("y", d => (-1) * t.getNodeShapeRadius(d))
        .append("xhtml:body")
          .style("background", "transparent")
          .style("width", "100%")
          .style("height", "100%")
          .style("margin", "0px")
        .append("div")
          .style("width", "100%")
          .style("height", "100%")
          .style("padding", "5px")
          .style("display", "flex")
          .style("align-items", "center")
          .style("justify-content", "center")
          .style("word-break", "break-word")
          .style("word-wrap", "break-word")
          .style("font-size", d => {
            let text = ibHelper.getDataText(d.ibGibJson);
            if (text) {
              let textLength = text.length;
              // let singleEmojiRegEx = /^:\w+:$/;
              // let regExResult = text.match(singleEmojiRegEx);
              // let textIsSingleEmoji = regExResult && regExResult.length > 0;
              let textIsSingleEmoji = false;
              let fontSize = 0;
              if (d.isSource) {
                // emoji, smileys
                if (textLength <= 3 || textIsSingleEmoji) {
                  fontSize = 65;
                } else if (textLength <= 20) {
                  fontSize = 35;
                } else if (textLength <= 40) {
                  fontSize = 25;
                } else if (textLength <= 80) {
                  fontSize = 14;
                } else {
                  fontSize = 12;
                }
              } else {
                // not a source, so is slightly smaller.
                if (textLength <= 3 || textIsSingleEmoji) {
                  fontSize = 45;
                } else if (textLength <= 20) {
                  fontSize = 25;
                } else if (textLength <= 40) {
                  fontSize = 20;
                } else if (textLength <= 80) {
                  fontSize = 11;
                } else {
                  fontSize = 7;
                }
              }

              // Hack to adjust if the comment includes markdown headers that change the font size.
              if (text.includes("##")) {
                fontSize *= 0.5;
                if (fontSize < 7) {
                  fontSize = 7;
                }
              }

              return fontSize + "px";
            } else {
              // doesn't matter
              return "15px";
            }
          })
        .append("div")
          .style("width", "100%")
          .style("overflow", () => {
            // On mobile, the user must use the view command to view
            // long comments (there is no mousewheel to scroll, plus
            // there is a bug with overflow + d3 on mobile).
            return ibHelper.isMobile() ? "hidden" : "auto";
          })
          .style("max-height", d => (2 * t.getNodeShapeRadius(d)) + "px")
          .style("text-align", "center")
          .html(d => {
            if (d.ibGibJson) {
              let dataText = ibHelper.getDataText(d.ibGibJson);
              if (dataText) {
                let html;
                if (d.render === "link") {
                  html = `<a href="${dataText}" target="_blank">${dataText}</a>`;
                } else {
                  html = md.render(dataText);
                }
                return html;
              } else {
                console.warn("update node label: no dataText?")
                return "...";
              }
            } else {
              // This happens during fully expanding automatically.
              // I'm not sure if it's a bad thing or what.
              // (Though I think it's probably fine.)
              // console.warn("update node label: no ibGibJson?")
              return "...";
            }
          });

    t.graphNodesEnter_NonComments =
      t.graphNodesEnter
        .filter(d => {
          return !["text", "link"].includes(t.getNodeRenderType(d) || "");
        })
        .append("text")
        .attr("id", d => t.getNodeLabelId(d))
        .attr("font-size", d => t.getNodeLabelFontSize(d))
        .attr("font-family", d => t.getNodeLabelFontFamily(d))
        .attr("stroke", d => t.getNodeLabelStroke(d))
        .attr("fill", d => t.getNodeLabelFill(d))
        .attr("text-anchor", "middle")
        .attr("y", d => t.getNodeLabelFontOffset(d))
        .text(d => t.getNodeLabelText(d));

    t.graphNodeLabels = t.graphNodesEnter_Comments.merge(t.graphNodesEnter_NonComments);

    t.graphNodesEnter_Comments
      .append("title")
      .text(d => t.getNodeTitle(d));
    t.graphNodesEnter_NonComments
      .append("title")
      .text(d => t.getNodeTitle(d));
  }

  updateIbGib(node, newIbGib, skipUpdateUrl, callback) {
    let t = this;

    if (node.ibGib === newIbGib) {
      if (callback) { callback(); }
    } else {
      node.ibGib = newIbGib;
      delete node.ibGibJson;

      t.swap(node, node, /*updateParentOrChild*/ true);
      node.virtualId = ibHelper.getRandomString();
      t.zap(node, () => {
        if (!skipUpdateUrl) {
          if (node.isContext) {
            // update URL
            history.pushState({ibGib: node.ibGib, ibGibJson: node.ibGibJson}, "_", newIbGib);
            t.syncContextChildren();
          }
        }

        t.syncChildren_IbGib(node, () => {
          t.animateNodeBorder(node, /*nodeShape*/ null);

          t.syncAdjuncts(node.tempJuncIbGib, () => {
            if (callback) { callback(); }
          });
        });
      });
    }
  }
  updateRender(node) {
    if (node.ibGibJson) {
      if (ibHelper.isImage(node.ibGibJson)) {
        node.render = "image";
      } else if (ibHelper.isComment(node.ibGibJson)) {
        node.render = "text";
      } else if (ibHelper.isLink(node.ibGibJson)) {
        node.render = "link";
      } else if (ibHelper.isIdentity(node.ibGibJson)) {
        node.render = "identity";
      } else {
        delete node.render;
      }
    } else {
      delete node.render;
    }
  }

  /**
   * Syncs the visible children nodes of the given ibGib `node`.
   * Currently, this just does adjuncts who are no longer adjuncts.
   * In the future, when unrel8ng becomes a thing, will need to revisit
   * this to implement pruning.
   */
  syncChildren_IbGib(node, callback) {
    let t = this, lc = `syncChildren_IbGib(${node.ibGib})`;
    // console.log(`${lc} starting...`);

    t.getAdjunctInfos(node.tempJuncIbGib, nodeAdjunctInfos => {
      let nodeChildren = t.getChildren(node);
      if (nodeChildren.length > 0) {
        // use case right now is children who are adjuncts but have been
        // turned into direct rel8ns.
        nodeChildren
          .filter(child => child.type === "rel8n")
          .forEach(rel8nNode => {
            let directRel8nIbGibs = node.ibGibJson.rel8ns[rel8nNode.rel8nName];
            let rel8nNodeChildren = t.getChildren(rel8nNode);
            rel8nNodeChildren.filter(rnc => rnc.isAdjunct)
              .forEach(adjunctNode => {
                let adjunctInfo = nodeAdjunctInfos.filter(info => info.adjunctIbGib === adjunctNode.ibGib)[0];
                if (directRel8nIbGibs.includes(adjunctNode.ibGib)) {
                  adjunctNode.isAdjunct = false;
                  t.swap(adjunctNode, adjunctNode, /*updateParentOrChild*/ true);
                }
              });
          });
        }

        if (callback) {
          callback();
        } else {
          console.warn(`${lc} no callback?`)
        }
    });

  }
  syncContextChildren() {
    let t = this;
    t.setBusy(t.contextNode);
    t.getIbGibJson(t.contextNode.ibGib, ibGibJson => {
      // console.log(`got context's json: ${JSON.stringify(ibGibJson)}`);
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
            t.syncContextAdjuncts();
          });

        // If we've just gone back in history and there are no rel8ns via
        // ib^gib, then we should sync with an empty array.
        if (!rel8nNames.includes("ib^gib")) {
          t.syncContextSourceNodes(/*rel8nIbGibs*/ []);
        }

        // t.syncAdjuncts(t.contextNode.tempJuncIbGib);
      } catch (e) {
        console.error(`error syncing context children: ${e}`)
      } finally {
        t.clearBusy(t.contextNode);
      }
    });
  }
  /**
   * Sync all adjunct nodes that are related to the given `tempJuncIbGib`.
   * @param tempJuncIbGib is the src/target node's temporal junction point, NOT the _adjunct's_ temporal junction point.
   */
  syncAdjuncts(tempJuncIbGib, callback) {
    let t = this;

    t.getAdjunctInfos(tempJuncIbGib, adjunctInfos => {
      // console.log(`syncAdjuncts: adjunctInfos: ${JSON.stringify(adjunctInfos)}`);

      if (tempJuncIbGib === t.contextNode.tempJuncIbGib) {
        // console.log(`syncAdjuncts: calling syncContextAdjuncts...`);
        t.syncContextAdjuncts(adjunctInfos);
      }

      let prunedAdjunctTempJuncIbGibs = t.pruneAdjuncts(tempJuncIbGib);

      // console.log(`syncAdjuncts: prunedAdjunctTempJuncIbGibs: ${JSON.stringify(prunedAdjunctTempJuncIbGibs)}`)

      t.graphData.nodes
        .filter(n => n.type === "rel8n" &&
                     !n.virtualId &&
                     !["past", "ancestor"].includes(n.rel8nName))
        .forEach(rel8nNode => {
          let src = rel8nNode.rel8nSrc;
          let childrenTempJuncIbGibs = t.getChildren(rel8nNode).filter(c => c.type === "ibGib").map(child => child.tempJuncIbGib);

          adjunctInfos
            .filter(info => {
              // only infos for this rel8n
              return info.adjunctTargetRel8n === rel8nNode.rel8nName;
            })
            .filter(info => {
              // Don't add pruned (assimilated) adjuncts.
              return !prunedAdjunctTempJuncIbGibs.includes(info.adjunctTempJuncIbGib);
            })
            .filter(info => {
              // Only corresponding adjuncts to the given tempJunc
              // (Not the given adjunct temp junc)
              return info.tempJuncIbGib === src.tempJuncIbGib;
            })
            .forEach(info => {
              // Don't add ones that already exist.
              if (!childrenTempJuncIbGibs.includes(info.adjunctTempJuncIbGib)) {
                childrenTempJuncIbGibs.push(info.adjunctTempJuncIbGib);
                t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ info.adjunctIbGib, /*srcNode*/ rel8nNode, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: rel8nNode.x, y: rel8nNode.y}, /*isAdjunct*/ true);
              }
            });
        });
      if (callback) {
        callback();
      }
    });
  }
  /**
   * Syncs the adjuncts for the contextNode only. We need separate code for
   * the context, because it behaves differently than other ibGib nodes in that
   * it has the additional free-floating nodes.
   *
   * Note: Right now to simplify things, we're pretending that adjuncts do not
   * change i.e. the user doesn't edit their comment. Worst case is that
   * multiple adjuncts show up that are different frames of the same ibGib.
   */
  syncContextAdjuncts(adjunctInfos) {
    let t = this;
    // console.log(`syncContextAdjuncts: starting...`);
    let contextIbGibJson = t.contextNode.ibGibJson;
    if (!contextIbGibJson) { console.warn("syncContextAdjuncts: no contextIbGibJson. this is assumed to be populated at this point."); }

    if (adjunctInfos && adjunctInfos.length > 0) {
      // If the adjunct ibGib has been "assimilated" into the user's scene
      // directly, then we no longer need to show it as an "adjunct". So filter
      // those out.
      // So, "!some(rel8ns)" pointing to the adjunctIbGib
      adjunctInfos =
        adjunctInfos.filter(info => {
          return !Object.keys(contextIbGibJson.rel8ns)
            .map(key => contextIbGibJson.rel8ns[key])
            .some(rel8nIbGibs => {
              return rel8nIbGibs.includes(info.adjunctTempJuncIbGib) ||
                rel8nIbGibs.includes(info.adjunctIbGib);
            })
        });
      let adjunctSourceNodes =
        t.graphData.nodes.filter(n => n.isSource && n.id !== t.contextNode.id && !n.isRoot && n.isAdjunct);

      // prune
      // Go through the source nodes and remove any that are adjuncts but are not found in adjunctInfos (because they
      // have already been assimilated.)
      adjunctSourceNodes
        .filter(n => !adjunctInfos.some(info => {
          return !t.getChildren(n).map(c => c.tempJuncIbGib).includes(info.adjunctTempJuncIbGib);
        }))
        .forEach(n => t.removeNodeAndChildren(n));

      // reeval after pruning
      adjunctSourceNodes =
        t.graphData.nodes.filter(n => n.isSource && n.id !== t.contextNode.id && !n.isRoot && n.isAdjunct);

      adjunctInfos
        .filter(info => !adjunctSourceNodes.some(sn => {
          let adjTempJuncIbGib = ibHelper.getTemporalJunctionIbGib(info.adjunctIbGibJson);
          return sn.tempJuncIbGib === adjTempJuncIbGib;
        }))
        .forEach(info => {
          t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ info.adjunctIbGib, /*srcNode*/ null, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: t.contextNode.x, y: t.contextNode.y}, /*isAdjunct*/ true);
        });
    } else {
      // console.log(`syncContextAdjuncts: no adjunctInfos.`)
    }
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
    }
  }
  /**
   * Prunes the non-source rel8nNodes of adjunct nodes that have been
   * assimilated directly to their corrsponding target nodes.
   * @param tempJuncIbGib is the src/target node's temporal junction point, NOT the _adjunct's_ temporal junction point.
   */
  pruneAdjuncts(tempJuncIbGib) {
    let t = this, lc = `pruneAdjuncts(${tempJuncIbGib})`;
    // console.log(`${lc} starting...`)
    let prunedAdjunctIbGibs = [];
    t.graphData.nodes
      .filter(n => n.tempJuncIbGib === tempJuncIbGib) // get existing adj nodes
      .forEach(n => {
        // // Get the parent rel8n node
        // let parentRel8nNode = t.graphData.links.filter(l => l.target.id === n.id)[0];
        // Get the nodes adjunctNodes
        t.getChildren(n)
          .forEach(rel8nNode => {

            t.getChildren(rel8nNode)
              .filter(n => n.isAdjunct)
              .forEach(adjunctNode => {
                // For each adjunctNode, check to see if it's been assimilated
                // directly on node n. If it has, then it's no longer an adjunct,
                // but rather a directly rel8d node.
                if (Object.keys(n.ibGibJson.rel8ns)
                      .map(key => n.ibGibJson.rel8ns[key])
                      .some(rel8nIbGibs => rel8nIbGibs.includes(adjunctNode.ibGib))) {
                  adjunctNode.isAdjunct = false;
                  console.log(`${lc} updating adjunctNode. adjunctNode.ibGib: ${adjunctNode.ibGib}`)
                  t.swap(adjunctNode, adjunctNode, /*updateParentOrChild*/ true);
                  prunedAdjunctIbGibs.push(adjunctNode.tempJuncIbGib);
                }
              });

          })
      });

    // console.log(`${lc} complete. prunedAdjunctIbGibs: ${JSON.stringify(prunedAdjunctIbGibs)}`)

    return prunedAdjunctIbGibs;
  }
  pruneRel8nNodes(node, rel8nNames) {
    let t = this;
    t.getChildren(node)
      .filter(n => n.type === "rel8n")
      .filter(n => !rel8nNames.includes(n.rel8nName))
      .forEach(n => t.remove(n));

    return t.getChildren(node).filter(n => n.type === "rel8n");
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

  // add/remove functions ------------------------------------

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

    if (d.isAdjunct) {
      // t.addCmdVirtualNode(d, "help", /*fadeTimeoutMs*/ 0);
      t.addCmdVirtualNode(d, "huh", /*fadeTimeoutMs*/ 0);
      t._addCmdVirtualNodesIfAuthorized_Adjunct(d);
      if (d.ibGibJson) {
        if (ibHelper.isComment(d.ibGibJson) || ibHelper.isImage(d.ibGibJson)) {
          t.addCmdVirtualNode(d, "view", fadeTimeoutMs);
        }
      }
    } else if (d.isRoot) {
      t.addCmdVirtualNode(d, "huh", fadeTimeoutMs);
      // t.addCmdVirtualNode(d, "help", fadeTimeoutMs);
      t.addCmdVirtualNode(d, "query", fadeTimeoutMs);
      t.addCmdVirtualNode(d, "fork", fadeTimeoutMs);
      t.addCmdVirtualNode(d, "identemail", fadeTimeoutMs);
    } else {
      if (d.ibGibJson) {
        t.addCmdVirtualNode(d, "huh", fadeTimeoutMs);
        // t.addCmdVirtualNode(d, "help", fadeTimeoutMs);
        t.addCmdVirtualNode(d, "fork", fadeTimeoutMs);
        t._addCmdVirtualNodesIfAuthorized_Comment(d, fadeTimeoutMs);
        if (ibHelper.isComment(d.ibGibJson) || ibHelper.isImage(d.ibGibJson)) {
          t.addCmdVirtualNode(d, "view", fadeTimeoutMs);
        }
      } else {
        // not a loaded ibGibJson, so no virtual nodes to add.
        // So we are assuming this is a virtual node itself.
        if (!d.virtualId) { console.warn("addCmdVirtualNodes_Default on non-virtual node without ibGibJson"); }
      }
    }
  }
  addCmdVirtualNode(dSrc, cmdName, fadeTimeoutMs) {
    let t = this;
    let cmd = d3MenuCommands.filter(c => c.name === cmdName)[0];

    let node = t.addVirtualNode(t.getUniqueId(`${dSrc.id}_${cmdName}`), /*type*/ "cmd", `${cmdName}^gib`, /*srcNode*/ dSrc, "circle", /*autoZap*/ false, fadeTimeoutMs, cmd, /*title*/ null, /*label*/ null, /*startPos*/ {x: dSrc.x, y: dSrc.y}, /*isAdjunct*/ false);
    node.cmdTarget = dSrc;
  }
  /**
   * Add command nodes if the user is authorized.
   * This is for adding "Mut8 comment" command, which the user must be authzd
   * to do.
   */
  _addCmdVirtualNodesIfAuthorized_Comment(d, fadeTimeoutMs) {
    let t = this;
    t.ibGibProvider.getIbGibJson(d.ibGib, ibGibJson => {
      if (ibHelper.isComment(ibGibJson) && ibAuthz.isAuthorizedForMut8OrRel8(ibGibJson, t.currentIdentityIbGibs)) {
        t.addCmdVirtualNode(d, "mut8comment", fadeTimeoutMs)
      }
    });
  }
  _addCmdVirtualNodesIfAuthorized_Adjunct(d) {
    let t = this, lc = `_addCmdVirtualNodesIfAuthorized_Adjunct`;

    // Assume that d is an adjunct
    if (!d.isAdjunct) {
      console.error(`d is expected to be adjunct.`);
      return;
    }

    let adjunctInfo = t.ibGibProvider.getAdjunctInfo_ByAdjunctIbGib(d.ibGib);
    if (!adjunctInfo) {
      // Where's our adjunct info?
      console.error(`d is expected to be adjunct, but adjunctInfo is falsy?.`);
      return;
    }

    t.ibGibProvider.getIbGibJson(adjunctInfo.adjunctToTemporalJunction, adjunctTargetIbGibJson => {
      if (!adjunctTargetIbGibJson) {
        // This should be truthy
        // (I'm programming this function very defensively, gauntlet-style...)
        console.error(`d is expected to be adjunct, but adjunctInfo is falsy?.`);
        return;
      }

      if (ibAuthz.isAuthorizedForMut8OrRel8(adjunctTargetIbGibJson, t.currentIdentityIbGibs)) {
        t.addCmdVirtualNode(d, "ack", /*fadeTimeoutMs*/ 0)
      }
    });
  }
  addRel8nVirtualNode(dSrc, rel8nName, fadeTimeoutMs) {
    let t = this;

    let title = rel8nName in d3Rel8nIcons ? d3Rel8nIcons[rel8nName] : "";
    let node = t.addVirtualNode(t.getUniqueId(`${dSrc.id}_${rel8nName}`), /*type*/ "rel8n", `rel8n^gib`, /*srcNode*/ dSrc, "circle", /*autoZap*/ false, fadeTimeoutMs, /*cmd*/ null, title, /*label*/ rel8nName, /*startPos*/ {x: dSrc.x, y: dSrc.y}, /*isAdjunct*/ false);
    node.rel8nSrc = dSrc;

    return node;
  }
  /**
   * Adds "important" rel8ns that are not collapsed by default.
   * For example, adds "comment", "pic", etc. rel8ns, but not "dna", "past"
   */
  addSpiffyRel8ns(node) {
    let t = this;

    // Don't add for root node.
    if (node.ibGib === "ib^gib") { return; }

    // For checking existing rel8ns
    let childrenRel8nNames = t.getChildren_Rel8ns(node).map(child => child.rel8nName);

    let fadeTimeoutMs = t.config.other.rel8nFadeTimeoutMs_Spiffy;
    Object.keys(node.ibGibJson.rel8ns)
      .filter(rel8nName => !d3BoringRel8ns.includes(rel8nName))
      .filter(rel8nName => !childrenRel8nNames.includes(rel8nName))
      .forEach(rel8nName => t.addRel8nVirtualNode(node, rel8nName, fadeTimeoutMs));

    // Update children for next call (horribly non-optimized, but doesn't matter at this scale).
    childrenRel8nNames = t.getChildren_Rel8ns(node).map(child => child.rel8nName);
    // Add any rel8ns that should always be added.
    d3AlwaysRel8ns
      .filter(rel8nName => !childrenRel8nNames.includes(rel8nName))
      .forEach(rel8nName => {
        t.addRel8nVirtualNode(node, rel8nName, fadeTimeoutMs);
      });

    // Update children again
    childrenRel8nNames = t.getChildren_Rel8ns(node).map(child => child.rel8nName);
    d3AddableRel8ns
      .filter(rel8nName => !childrenRel8nNames.includes(rel8nName))
      .forEach(rel8nName => t.addRel8nVirtualNode(node, rel8nName, fadeTimeoutMs));
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
      .filter(rel8nName => d3BoringRel8ns.includes(rel8nName))
      .filter(rel8nName => !t.getChildren_Rel8ns(node)
                             .map(n => n.rel8nName)
                             .includes(rel8nName))
      .forEach(rel8nName => {
        // Don't add the ib^gib rel8n for the context node, because these
        // children are shown in the environment as free-floating ibGib.
        if (!(node.isContext && rel8nName === "ib^gib")) {
          t.addRel8nVirtualNode(node, rel8nName, fadeTimeoutMs);
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
  removeChildren(node, durationMs) {
    let t = this;

    if (durationMs) {

      let transition =
        d3.transition()
          .duration(durationMs)
          .ease(d3.easeLinear);

      t.getChildren(node).forEach(child => {
        let radius = t.getNodeShapeRadius(child);
        let cx = node.x - child.x - radius;
        let cy = node.y - child.y - radius;

        d3.select("#" + t.getNodeShapeId(child))
          .transition(transition)
          .attr("cx", cx)
          .attr("cy", cy)
          .attr("x", cx)
          .attr("y", cy)

        d3.select("#" + t.getNodeLabelId(child))
          .transition(transition)
          .attr("x", cx + "px")
          .attr("y", cy + "px")

        // if the node is a comment with a foreign object
        d3.select("#" + t.getUniqueId(child.id, "label", "foreignObject"))
          .transition(transition)
          .attr("x", cx + "px")
          .attr("y", cy + "px")

          // d3.select("#" + t.getNodeImageGroupId(child)),

        setTimeout(() => t.removeNodeAndChildren(child), durationMs);
      });
    } else {
      t.removeNodeAndChildren(child)
    }

  }
  removeNodeAndChildren(node) {
    let t = this;
    let children = t.getChildren(node);
    children.forEach(child => t.removeNodeAndChildren(child));
    t.remove(node, /*updateParentOrChild*/ true);
  }

  remove(dToRemove, updateParentOrChild) {
    let t = this;

    super.remove(dToRemove, updateParentOrChild);

    if (t.graphData.nodes.length === 0) {
      t.rootPulseTimer = setTimeout(() => {
        // if still no nodes
        if (t.graphData.nodes.length === 0) {
          t.addRootNode();
        }
      }, t.config.other.rootPulseMs);
    }
  }

  /** Adds the root */
  addRootNode() {
    let t = this;
    // console.log("addRootNode");

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
    } else {
      // There are other nodes, so don't pulse the root, just let it fade.
      autoZap = true;
      fadeTimeoutMs = t.config.other.rootFadeTimeoutMs;
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
    // console.log("fading out...");

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
  fadeOutChildlessRel8ns(fadeTimeoutMs) {
    let t = this;
    t.graphData.nodes
      .filter(n => n.type &&
                   n.type === "rel8n" &&
                   t.getChildrenCount_All(n) === 0)
      .forEach(n => {
        t.fadeOutNode(n, fadeTimeoutMs)
      });
  }
  removeVirtualNode(node, keepInGraph) {
    let t = this;
    delete t.virtualNodes[node.id];

    t.clearFadeTimeout(node);

    if (!keepInGraph) {
      if (t.graphData.nodes.some(n => n.id === node.id)) {
        if (node.busy) { t.clearBusy(node); }
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

  // Zap node functions

  zap(node, callback) {
    let t = this, lc = `zap`;

    t.clearFadeTimeout(node);

    if (node.virtualId) {
      t.zapVirtualNode(node, () => {
        if (node.isRoot) {
          // hack to auto-zap the root again
          setTimeout(() => {
            t.zap(node, callback);
          }, 400);
        } else {
          if (callback) { callback(); }
        }
      });
    } else {
      t.zapConcreteNode(node, callback);
    }
  }
  zapConcreteNode(node, callback) {
    let t = this;
    if (node.errored && node.emsg) {
      alert(node.emsg);
      if (node.clearAfterMsg) {
        t.clearErrored(node);
      }
    } else {
      t.removeVirtualCmdNodes();
      t.expandNode(node, callback);
    }
  }
  zapVirtualNode(virtualNode, callback) {
    let t = this;

    if (!virtualNode.virtualId || virtualNode.busy) {
      if (callback) { callback(); }
      return;
    }

    t.setBusy(virtualNode);

    t.animateNodeBorder(/*d*/ virtualNode, /*nodeShape*/ null);

    switch (virtualNode.type) {
      case "cmd":
        t.zapVirtualNode_Cmd(virtualNode, callback);
        break;

      case "ibGib":
        t.zapVirtualNode_IbGib(virtualNode, callback);
        break;

      case "rel8n":
        t.zapVirtualNode_Rel8n(virtualNode, callback);
        break;

      case "error":
        t.zapVirtualNode_Errored(virtualNode, callback);
        break;

      default:
        console.warn(`zapVirtualNode: Unknown node type: ${virtualNode.type}`);
        if (callback) { callback(); }
    }
  }
  zapVirtualNode_Cmd(node, callback) {
    let t = this;
    t.removeVirtualCmdNodes();
    t.commandMgr.exec(node.cmdTarget, node.cmd);
    // t.clearBusy(node);
    if (callback) { callback(); }
  }
  zapVirtualNode_IbGib(node, callback) {
    let t = this;

    t.clearFadeTimeout(node);

    if (t.rootPulseTimer) {
      clearTimeout(t.rootPulseTimer);
      delete t.rootPulseTimer;
    }

    if (node.errored && node.emsg) {
      alert(node.emsg);
      if (node.clearAfterMsg) {
        t.clearErrored(node);
      }
    } else {
      t.getIbGibJson(node.ibGib, ibGibJson => {
        // console.log(`got json: ${JSON.stringify(ibGibJson)}`);
        node.ibGibJson = ibGibJson;
        node.tempJuncIbGib = ibHelper.getTemporalJunctionIbGib(ibGibJson);

        t.updateRender(node);

        t.removeVirtualNode(node, /*keepInGraph*/ true);
        delete node.virtualId;
        t.swap(node, node, /*updateParentOrChild*/ true);

        if (node.ibGib !== "ib^gib") {
          t.connectToEventBus_IbGibNode(node)
        }

        t.clearBusy(node);
        t.animateNodeBorder(node, /*nodeShape*/ null);
        if (callback) { callback(); }
      });
    }
  }
  zapVirtualNode_Rel8n(rel8nNode, callback) {
    let t = this;

    t.clearFadeTimeout(rel8nNode);
    t.clearBusy(rel8nNode);
    t.removeVirtualNode(rel8nNode);
    delete rel8nNode.virtualId;
    t.add([rel8nNode], [{source: rel8nNode.rel8nSrc.id, target: rel8nNode.id}], /*updateParentOrChild*/ true);
    t.expandNode(rel8nNode, callback);
  }
  zapVirtualNode_Errored(node, callback) {
    let t = this, lc = `zapVirtualNode_Errored`;

    // let links = t.graphData.links.filter(l => l.source.id === virtualNode.id || l.target.id === virtualNode.id);

    if (node.notified) {
      // The user's already been notified, so remove the node.
      t.remove(node);
    } else {
      // Notify the user that something went wrong, re-add node to update
      // the label/tooltip.
      alert(node.errorMsg);
      node.notified = true;
      t.swap(node, node, /*updateParentOrChild*/ true);
    }

    t.clearBusy(node);
    if (callback) { callback(); }
  }

  /** Toggles the expand/collapse level for the node, showing/hiding rel8ns */
  expandNode(node, callback) {
    let t = this;
    node.expandLevel = node.expandLevel || 0;

    if (node.expandLevel && t.getChildrenCount_All(node) === 0) {
      node.expandLevel = 0;
    }

    t.removeVirtualCmdNodes();
    // t.removeAllVirtualNodes();

    if (node.ibGib === "ib^gib") {
      t._expandNode_Root(node, callback);
    } else if (node.type === "ibGib") {
      t._expandNode_IbGib(node, callback);
    } else if (node.type === "rel8n") {
      t._expandNode_Rel8n(node, callback);
    } else {
      console.warn("unknown node type for toggle expand collapse");
      if (callback) { callback(); }
    }
  }
  _expandNode_Root(node, callback) {
    let t = this;
    t.addCmdVirtualNodes_Default(node);
    if (callback) { callback(); }
  }
  _expandNode_IbGib(node, callback) {
    let t = this;

    if (node.expanding) {
      if (callback) { callback(); }
      return;
    } else {
      node.expanding = true;
    }

    if (node.isSource) { t.pin(node); }

    if (!node.expandLevel) {
      t.addSpiffyRel8ns(node);
      node.expandLevel = 1;
    } else {
      t.addBoringRel8ns(node);
      node.expandLevel = 0;
    }

    let autoExpandRel8ns = ["comment", "pic", "link", "result"];
    let children = t.getChildren_Rel8ns(node);

    // Do this whenever done (after zapping children if required).
    let finalize = () => {
      t.addCmdVirtualNodes_Default(node);
      delete node.expanding;
      if (callback) { callback(); }
    };

    if (children.some(c => autoExpandRel8ns.includes(c.rel8nName))) {
      // hack to execute after all callbacks execute (ick).
      t.expandIbGibCallbackAgg = t.expandIbGibCallbackAgg || {};

      if (!(node.id in t.expandIbGibCallbackAgg)) {
        t.expandIbGibCallbackAgg[node.id] = children.length;
        children
          .forEach(rel8n => {
            // hack
            if (autoExpandRel8ns.includes(rel8n.rel8nName)) {
              t.zap(rel8n, () => {
                // dec callback count after zap
                t.expandIbGibCallbackAgg[node.id] = t.expandIbGibCallbackAgg[node.id] - 1;
                if (t.expandIbGibCallbackAgg[node.id] === 0) {
                  delete t.expandIbGibCallbackAgg[node.id];
                  finalize();
                }
              });
            } else {
              // dec callback count immediately
              t.expandIbGibCallbackAgg[node.id] = t.expandIbGibCallbackAgg[node.id] - 1;
              if (t.expandIbGibCallbackAgg[node.id] === 0) {
                finalize();
              }
            }
          });
      } else {
        console.error(`node already in expand hack`)
        if (callback) { callback(); }
        // finalize();
      }
    } else {
      // no children to further auto-zap
      finalize();
    }
  }
  _expandNode_Rel8n(rel8nNode, callback) {
    let t = this;
    // add the Add cmd if it's an addable rel8n
    if (d3AddableRel8ns.includes(rel8nNode.rel8nName)) {
      t.addCmdVirtualNode(rel8nNode, "add", t.config.other.cmdFadeTimeoutMs_Specialized);
      rel8nNode.showingAdd = true;
      if (rel8nNode.toggleExpandTimer) {
        clearTimeout(rel8nNode.toggleExpandTimer);
      }
      rel8nNode.toggleExpandTimer = setTimeout(() => {
        // console.log("clearing rel8nNode.showingAdd")
        delete rel8nNode.showingAdd;
      }, t.config.other.cmdFadeTimeoutMs_Specialized);
    }

    let existingChildrenIbGibs =
      t.getChildren(rel8nNode)
        .filter(n => n.type && n.type === "ibGib")
        .map(n => n.ibGib);

    if (existingChildrenIbGibs.length > 0) {
      // Already expanded
      if (callback) { callback(); }
    } else {
      // Add the children ibGibs listed in the src rel8ns.
      let { rel8nName, rel8nSrc } = rel8nNode;
      let rel8dIbGibs = rel8nSrc.ibGibJson.rel8ns[rel8nName] || [];
      let rel8dIbGibNodes = [];
      rel8dIbGibs
        .forEach(rel8dIbGib => {
          let rel8dIbGibNode = t.addVirtualNode(/*id*/ null, /*type*/ "ibGib", /*nameOrIbGib*/ rel8dIbGib, /*srcNode*/ rel8nNode, /*shape*/ "circle", /*autoZap*/ true, /*fadeTimeoutMs*/ 0, /*cmd*/ null, /*title*/ "...", /*label*/ "", /*startPos*/ {x: rel8nNode.x, y: rel8nNode.y}, /*isAdjunct*/ false);
          rel8dIbGibNodes.push(rel8dIbGibNode);
        });

      if (d3PausedRel8ns.includes(rel8nNode.rel8nName)) {
        // Mark all children as paused.
        rel8dIbGibNodes.forEach(n => {
          n.isPaused = true;
        });
      } else {
        // Refresh children ibGibs.
        let ibGibsToRefresh = rel8dIbGibs.concat([rel8nSrc.ibGib]);
        t.refreshIbGibs(ibGibsToRefresh, () => {
          // Sync adjuncts, passing callback.
          t.syncAdjuncts(rel8nNode.rel8nSrc.tempJuncIbGib, () => {
            if (callback) { callback(); }
          });
          }, errorMsg => {
            console.error(`expandNode_Rel8n: refresh toRefresh failed. Error: ${JSON.stringify(errorMsg)}`)
            if (callback) { callback(); }
          });
      }
    }

    rel8nNode.expandLevel = 1;
  }
  _expandNodeFully(node, autoExpandRel8ns, callback, isCancelledFunc) {
    let t = this, lc = `_expandNodeFully(${node.id})`

    if (isCancelledFunc && isCancelledFunc()) {
      callback();
    } else {
      t.zap(node, () => {
        let nodeChildren =
          t.getChildren(node)
            .filter(n => n.type)
            .filter(n => n.type === "ibGib" ||
                         (n.type === "rel8n" && autoExpandRel8ns.includes(n.rel8nName)));
        let nodeChildCount = nodeChildren.length;
        if (nodeChildCount > 0) {
          // hack to know when all callbacks are done (depth-first)
          if (!t.nodeChildCountHack) { t.nodeChildCountHack = {}; }
          t.nodeChildCountHack[node.id] = nodeChildCount;

          nodeChildren
            .forEach(nodeChild => t._expandNodeFully(nodeChild, autoExpandRel8ns, () => {
              t.removeVirtualCmdNodes();
              let count = t.nodeChildCountHack[node.id] - 1;
              if (count === 0) {
                delete t.nodeChildCountHack[node.id];

                callback();
              } else {
                t.nodeChildCountHack[node.id] = count;
              }
            }, isCancelledFunc))
        } else {
          callback();
        }
      });
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

  // Node get functions -------------------------------------

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

    d.r = d3CircleRadius * multiplier;
    return d.r;
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
      // console.warn("getIbGibMultiplier assumes d.ibGibJson is truthy...");
      // This isn't loaded often when fully expanding automatically.
      return d3Scales["default"];
    }
  }
  getNodeShapeFill(d) {
    let t = this;

    switch (d.type) {
      case "ibGib":

        if (d.isContext) {
          return `url(#${t.svgGradientId_Context})`;
        } else if (d.ibGib === "ib^gib") {
          return `url(#${t.svgGradientId_Root})`;
        } else if (d.render && d.render === "text") {
          return `url(#${t.svgGradientId_Comment})`;
        } else if (d.render && d.render === "image") {
          return `url(#${t.svgGradientId_Image})`;
        } else if (d.render && d.render === "identity") {
          return "white";
        } else {
          return `url(#${t.svgGradientId_Default})`;
        }

      case "cmd":
        return d.cmd.color || `url(#${t.svgGradientId_Default})`;

      case "rel8n":
        return `url(#${t.svgGradientId_Rel8n})`;

      default:
        return `url(#${t.svgGradientId_Default})`;
    }

    return color;
  }
  getNodeImageBackgroundFill(d) { 
    let t = this;
    return `url(#${t.svgGradientId_Image})`;
  }
  getNodeBorderStroke(d) {
    // for some reason this doesn't work. It should, but it doesn't.
    // completely dumbfounded on this one. The animateNodeBorder call is
    // calling this but it just doesn't work. If I take out the
    // animateNodeBorder code which calls this function at the end of the
    // transition, then it displays properly. Probably some obscure
    // d3 bug or something or just my logic is horribly off. :-/
    // return d.isAdjunct ? "pink" : super.getNodeBorderStroke(d);
    return super.getNodeBorderStroke(d);
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
        if (d.render === "text" && d.ibGibJson.data.text) {
          return d.ibGibJson.data.text;
        } else if (d.render === "link" && d.ibGibJson.data.text) {
          let url = d.ibGibJson.data.text;
          return url;
        } else if (d.render === "image") {
          return "";
        } else if (d.render === "identity") {
          if (d.ibGibJson.data.type === "email" && d.ibGibJson.data.email_addr) {
            return d.ibGibJson.data.email_addr;
          } else if (d.ibGibJson.data.type === "session") {
            return d3Rel8nIcons["identity_session"];
          } else if (d.ibGibJson.rel8ns["instance_of"] &&
              d.ibGibJson.rel8ns["instance_of"][0] === "identity^gib") {
            // The owning identity of a session identity is actually the
            // same session identity's past identity. This past identity
            // is the past before it's mut8d to have
            // data.type = session. That's how this case comes to exist.
            return d3Rel8nIcons["identity_session"];
          } else {
            console.error(`Unknown identity type: ${d.ibGibJson.data.type}`);
            return d.ibGibJson.ib;
          }
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
  getNodeImageHref(d) {
    let t = this;
    let imageUrl =
      t.ibGibImageProvider.getThumbnailImageUrl(d.ibGib, d.ibGibJson);
    if (imageUrl) {
      return imageUrl;
    } else {
      return super.getNodeImageHref(d);
    }
  }
  getNodeShapeFromIb(ib) {
    return ib === "comment" ? "rect" : "circle";
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

  // Simulation get functions -------------------------------

  /** Overridden to remove the center force. Much more tolerable this way. */
  getForceCenter() { return null; }
  // getForceLink() {
  //   let t = this;
  //
  //   return super.getForceLink()
  //               .strength(l => t.getForceLinkStrength(l));
  // }
  getForceLinkDistance(l) {
    let t = this;
    if (l.source.type === "rel8n") {
      return t.config.simulation.linkDistance_Src_Rel8n;
    } else {
      return super.getForceLinkDistance(l);
    }
  }
  // getForceLinkStrength(l) {
  //   return 1;
  //   // if (l.source && l.source.isSource) {
  //   //   return 1;
  //   // } else {
  //   //   return 1/10;
  //   // }
  // } // returns default
  getForceCollideDistance(d) {
    if (d.type === "rel8n") {
      return super.getForceCollideDistance(d) * 1.3;
    } else {
      return super.getForceCollideDistance(d) * 1.1;
    }
  }
  getForceChargeStrength(d) {
    // return super.getForceChargeStrength(d);
    if (d.isSource || (d.type && d.type === "rel8n")) {
      return this.config.simulation.chargeStrength;
    } else {
      return 5 * this.config.simulation.chargeStrength;
    }
  }

  // Other get functions ------------------------------------

  getBackgroundFill() {
    let t = this;
    return `url(#${t.svgGradientId_Background})`;
    // return this.config.background.fill;
  }
  /**
   * The first init of adjunct infos will talk to the server and get all
   * of the adjuncts for the given `tempJuncIbGib`. Any subsequent
   * additional adjuncts will need to come down the event bus and be
   * added to the cache and added to the ibScape.
   */
  getAdjunctInfos(tempJuncIbGib, callback) {
    let t = this;

    let adjunctInfos = t.ibGibCache.getAdjunctInfos(tempJuncIbGib);
    if (adjunctInfos) {
      // console.log(`adjunctInfos gotten from cache: ${adjunctInfos.length}`);
      // console.log(`adjunctInfos gotten from cache: ${JSON.stringify(adjunctInfos)}`);
      callback(adjunctInfos);
    } else {
      // console.log(`No adjunctInfos in cache. Getting from server...`);

      let data = { ibGibs: [tempJuncIbGib] };
      let cmdGetAdjuncts = new commands.GetAdjunctsCommand(t, data, successMsg => {
        t.ibGibCache.clearAdjunctInfos(tempJuncIbGib);
        if (successMsg.data && successMsg.data.adjunct_ib_gibs) {
          let adjunctIbGibs = successMsg.data.adjunct_ib_gibs[tempJuncIbGib];
          t.getIbGibJsons(adjunctIbGibs, adjunctIbGibJsons => {
            Object.keys(adjunctIbGibJsons)
              .map(key => adjunctIbGibJsons[key])
              .forEach(adjunctIbGibJson => {
                let adjunctIbGib = ibHelper.getFull_ibGib(adjunctIbGibJson);
                t.ibGibCache.addAdjunctInfo(tempJuncIbGib, tempJuncIbGib, adjunctIbGib, adjunctIbGibJson);
              });
            adjunctInfos = t.ibGibCache.getAdjunctInfos(tempJuncIbGib);
            if (callback) {
              callback(adjunctInfos);
            } else {
              console.error(`Callback isn't defined?`);
            }
          });
        } else {
          // console.log(`GetAdjunctsCommand did not have successMsg.data && successMsg.data.adjunct_ib_gibs. Probably has no adjuncts.)`);
          if (callback) {
            callback([]);
          } else {
            console.error(`Callback isn't defined?`);
          }
        }
      }, errorMsg => {
        console.error(`getAdjuncts error: ${JSON.stringify(errorMsg)}`);
      });
      cmdGetAdjuncts.exec();
    }
  }
  /** wrapper that calls ibGibProvider (refactoring) */
  getIbGibJson(ibgib, callback) {
    let t = this;
    t.ibGibProvider.getIbGibJson(ibgib, callback);
  }
  /** wrapper that calls ibGibProvider (refactoring) */
  getIbGibJsons(ibGibs, callback) {
    let t = this;
    t.ibGibProvider.getIbGibJsons(ibGibs, callback);
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
      .filter(l => l.source.id === node.id && l.target.type === "rel8n")
      .map(l => l.target);
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
  getAllChildrenRecursively(node, childrenSoFar) {
    let t = this;
    let children = t.getChildren(node);
    if (children && children.length > 0) {
      childrenSoFar = childrenSoFar.concat(children);
      children.forEach(child => {
        childrenSoFar = t.getAllChildrenRecursively(child, childrenSoFar)
      })
    }
    return childrenSoFar;
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
    d.isSelected = true;
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

    // let trans =
    //   d3.transition()
    //     .duration(75)
    //     .ease(d3.easeLinear);

    t.rootNode.x = (event.clientX - transform.translateX) / transform.scaleX;
    t.rootNode.y = (event.clientY - transform.translateY) / transform.scaleY;
    t.rootNode.fx = t.rootNode.x;
    t.rootNode.fy = t.rootNode.y;
    t.rootPos.x = t.rootNode.x;
    t.rootPos.y = t.rootNode.y;
    t.swap(t.rootNode, t.rootNode, /*updateParentOrChild*/ true);

    t.animateNodeBorder(t.rootNode, /*nodeShape*/ null);
  }
  pin(node) {
    let t = this;
    if (!node.isPinned) {
      t.clearFreezeNodeTimer(node);
      node.fx = node.x;
      node.fy = node.y;
      node.isPinned = true;
    }
  }
  unpin(node) {
    if (node.isPinned) {
      if (node.fx) { delete node.fx; }
      if (node.fy) { delete node.fy; }
      node.isPinned = false;
    }
  }
  freezeNode(node, durationMs) {
    let t = this;
    t.clearFreezeNodeTimer(node);

    if (!node.fx && !node.fy) {
      node.fx = node.x;
      node.fy = node.y;
      node.frozen = true;

      node.freezeNodeTimer = setTimeout(() => {
        t.clearFreezeNodeTimer(node);
      }, durationMs);
    }
  }
  freezeNodes(durationMs) {
    let t = this;
    t.graphData.nodes.forEach(n => t.freezeNode(n));
  }
  clearFreezeNodeTimer(node) {
    if (node.freezeNodeTimer) {
      clearTimeout(node.freezeNodeTimer);
    }

    if (node.frozen) {
      if (!node.fixedBeforeFreeze) {
        delete node.fx;
        delete node.fy;
      }
      delete node.fixedBeforeFreeze;
      delete node.frozen;
    }
  }

  // handle functions ------------------------------------

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
    if (d.isPinned) {
      d.fx = d.x;
      d.fy = d.y;
    }
  }
  handleBackgroundClicked() {
    let t = this;
    if (t.selectedNode) {
      t.clearSelectedNode();
    } else {
      t.removeAllVirtualNodes();
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

    t.pin(d);
    // t.freezeNode(d, 1000);
    t.clearSelectedNode();
    t.animateNodeBorder(d, /*nodeShape*/ null);
    if (!d.isRoot) { t.fadeOutNode(t.rootNode, t.config.other.rootFadeTimeoutMs_Fast); }

    if (d.expanding) { delete d.expanding; }
    t.zap(d, () => {
      console.log(`zapped!`)
    })
  }
  handleNodeDblClicked(d) {
    let t = this;

    if (d.isRoot) {
      return;
    }

    let isCancelledFunc = () => {
      return !d.fullyExpanding;
    };

    if (d.fullyExpanding) {
      delete (d.fullyExpanding);
      if (d.expanding) { delete d.expanding; }
      t.clearBusy(d);
    } else if (t.getChildrenCount_All(d) > 0) {
      let durationMs = 150;
      t.removeChildren(d, durationMs);
      if (d.expanding) { delete d.expanding; }
      t.unpin(d);
    } else {
      t.pin(d);

      d.fullyExpanding = true;
      t.setBusy(d);
      t._expandNodeFully(d, ["pic", "comment"], () => {
        // t.fadeOutChildlessRel8ns(t.config.other.rel8nFadeTimeoutMs_Spiffy);
        t.removeVirtualCmdNodes();
        t.fadeOutChildlessRel8ns(4000);
        let allIbGibChildren =
          t.getAllChildrenRecursively(d, /*childrenSoFar*/ [])
          .filter(n => n.type && n.type === "ibGib" && n.ibGib);
        if (allIbGibChildren.length > 0) {
          allIbGibChildren
            .forEach(n => t.setBusy(n));
          t.refreshIbGibs(allIbGibChildren.map(n => n.ibGib), () => {
            allIbGibChildren
              .forEach(n => {
                // setTimeout => visual cue that the expansion is done.
                setTimeout(() => {
                  t.clearBusy(n);

                  // Calls this for each n - at this point I don't mind.
                  if (d.fullyExpanding) { delete d.fullyExpanding; }
                  t.clearBusy(d);
                }, 2000);
              });
          });
        } else {
          // no children, so we're done.
          if (d.fullyExpanding) { delete d.fullyExpanding; }
          t.clearBusy(d);
        }
      }, isCancelledFunc);
    }
  }
  handleNodeLongClicked(d) {
    let t = this;

    if (d.virtualId) {
      t.freezeNode(d, 1000);
      t.commandMgr.exec(d, d3MenuCommands.filter(c => c.name === "huh")[0]);
    } else if (d.type === "ibGib") {
      t.freezeNode(d, 1000);
      t.clearSelectedNode();
      t.selectNode(d);
    } else if (d.type === "rel8n") {
      if (d.isPinned) {
        t.unpin(d);
      } else {
        t.pin(d);
      }
    }
  }
  handleNodeContextMenu(d) {
    let t = this;
    super.handleNodeContextMenu(d);

    if (d.virtualId) {
      t.clearSelectedNode();
      t.selectNode(d);
      // t.commandMgr.exec(d, d3MenuCommands.filter(c => c.name === "huh")[0]);
    } else if (d.type === "ibGib") {
      t.clearSelectedNode();
      t.selectNode(d);
    } else if (d.type === "rel8n") {
      t._expandNode_Rel8n(d);
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

  // Event bus related -------------------------------------

  connectToEventBus_IbGibNode(node) {
    let t = this;
    let tempJuncIbGib = ibHelper.getTemporalJunctionIbGib(node.ibGibJson);

    t.ibGibEventBus.connect(/*connectionId*/ node.id, tempJuncIbGib, msg => {
      switch (msg.metadata.name) {
        case "update":
          t.handleEventBusMsg_Update(tempJuncIbGib, node.ibGib, msg);
          break;
        case "adjuncts":
          t.handleEventBusMsg_Adjuncts(tempJuncIbGib, node.ibGib, msg);
          break;
        case "new_adjunct":
          t.handleEventBusMsg_NewAdjunct(tempJuncIbGib, node.ibGib, msg);
          break;
        default:
          console.error(`Unhandled/invalid msg received on event bus. Msg: ${JSON.stringify(msg)}`)
      }
    });
  }
  connectToEventBus_Identity(identityIbGib) {
    let t = this;

    t.ibGibEventBus.connect(/*connectionId*/ identityIbGib, identityIbGib, msg => {
      t.handleEventBusMsg_Identity(identityIbGib, msg);
    });
  }

  handleEventBusMsg_Update(tempJuncIbGib, ibGib, msg) {
    let t = this;
    // console.log(`handleEventBusMsg_Update msg:\n${JSON.stringify(msg)}`)

    if (msg && msg.data &&
        // possibly redundant (unnecessary)
        msg.metadata.temp_junc_ib_gib === tempJuncIbGib &&
        msg.data.new_ib_gib) {
      t.graphData.nodes
        .filter(n => n.ibGib === ibGib)
        .forEach(n => {
          // console.log(`updating ibGib node`)
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
    console.log(`handleEventBusMsg_Adjuncts msg:\n${JSON.stringify(msg)}`)
    if (msg && msg.metadata && msg.metadata.temp_junc_ib_gib === tempJuncIbGib) {
      console.log(`handleEventBusMsg_Adjuncts: calling getIbGibJsons...`)
      t.getIbGibJsons(msg.data.adjunct_ib_gibs, adjunctIbGibJsons => {
        console.log(`handleEventBusMsg_Adjuncts: adjunctIbGibJsons: ${JSON.stringify(adjunctIbGibJsons)}`)

        msg.data.adjunct_ib_gibs
          .forEach(adjunctIbGib => {
            let adjunctIbGibJson = adjunctIbGibJsons[adjunctIbGib];
            t.ibGibCache.addAdjunctInfo(tempJuncIbGib, ibGib, adjunctIbGib, adjunctIbGibJson);
          });
        // At this point, we have loaded all adjunctInfos and are ready to sync
        // the tempJuncIbGib
        console.log(`handleEventBusMsg_Adjuncts: calling syncAdjuncts...`)
        t.syncAdjuncts(tempJuncIbGib, /*callback*/ () => {
          console.log(`handleEventBusMsg_Adjuncts: completed syncAdjuncts.`)
        });
      });
    } else {
      console.warn(`Unused msg(?): ${JSON.stringify(msg)}`);
    }
  }
  handleEventBusMsg_NewAdjunct(tempJuncIbGib, ibGib, msg) {
    let t = this; let lc = `handleEventBusMsg_NewAdjunct(${tempJuncIbGib})`;
    console.log(`${lc} msg:\n${JSON.stringify(msg)}`)
    if (msg && msg.metadata && msg.metadata.temp_junc_ib_gib === tempJuncIbGib) {
      let adjunctIbGib = msg.data.adjunct_ib_gib;
      console.log(`${lc} calling getIbGibJson...`)
      t.getIbGibJson(adjunctIbGib, adjunctIbGibJson => {
        console.log(`${lc} adjunctIbGibJson: ${JSON.stringify(adjunctIbGibJson)}`)

        t.ibGibCache.addAdjunctInfo(tempJuncIbGib, ibGib, adjunctIbGib, adjunctIbGibJson);
        console.log(`${lc} calling syncAdjuncts...`);
        t.syncAdjuncts(tempJuncIbGib, /*callback*/ () => {
          console.log(`${lc} completed syncAdjuncts.`);
        });
      });
    } else {
      console.warn(`${lc} Invalid msg(?): ${JSON.stringify(msg)}`);
    }
  }
  handleEventBusMsg_Identity(identityIbGib, msg) {
    let t = this, lc = `handleEventBusMsg_Identity(${identityIbGib})`;

    if (!t.currentIdentityIbGibs.includes(identityIbGib)) {
      console.log(`Adding identityIbGib to currentIdentityIbGibs`);
      t.currentIdentityIbGibs.push(identityIbGib);
    }

    // Thanks SO! http://stackoverflow.com/a/28171425/4275029
    setTimeout(() => window.location.reload());
  }
}