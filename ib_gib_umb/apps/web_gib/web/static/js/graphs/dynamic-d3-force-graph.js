import * as d3 from 'd3';

export class DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config) {
    let t = this;

    t.graphDiv = graphDiv;
    t.svgId = svgId;

    t.graphData = { "nodes": [], "links": [] };
    t.children = [];

    // My current implementation for overriding config with defaults doesn't
    // work. That's why I'm duplicating the entire structure on all descendants.
    let defaults = {
      background: {
        fill: "#F2F7F0",
        opacity: 1,
        shape: "rect"
      },
      mouse: {
        dblClickMs: 250,
        longPressMs: 900
      },
      simulation: {
        velocityDecay: 0.55,
        chargeStrength: -25,
        chargeDistanceMin: 100,
        chargeDistanceMax: 10000,
        linkDistance: 50
      },
      node: {
        cursorType: "pointer",
        baseRadiusSize: 15,
        defShapeFill: "lightgreen",
        defBorderStroke: "#ED6DCD",
        defBorderStrokeWidth: "0.5px",
        label: {
          fontFamily: "Arial",
          fontStroke: "pink",
          fontFill: "red",
          fontSize: "12px",
          fontOffset: 0
        },
        image: {
          backgroundFill: "transparent"
        }
      }
    }
    t.config = $.extend({}, defaults, config || {});
  }

  destroy() {
    let t = this;

    if (t.simulation) {
      t.simulation.stop();
      t.simulation = null;

      t.graphNodesGroup = null;
      t.graphLinksGroup = null;
      t.graphLinksData = null;
      t.graphLinksEnter = null;
      t.graphLinksExit = null;
      t.graphNodesData = null;
      t.graphNodesEnter = null;
      t.graphNodesExit = null;
      t.graphNodeShapes = null;
      t.graphNodeCircles = null;
      t.graphNodeRects = null;
      t.graphNodeLabels = null;

      t.graphNodeImagePatternImage = null;
      t.graphNodeImages = null;
      t.graphImageDefs = null;

      t.drag = null;
      t.zoom = null;

      d3.select(`#${t.svgId}`).remove();
      t.svg = null;

      d3.select(t.background).remove();
      t.background = null;
    }
  }

  /**
   * Initializes the graph using `this.graphDiv`. This includes building the
   * root `svg` element, the background, the simulation, and some other
   * fundamental pieces.
   */
  init() {
    let t = this;

    t.initGraphDiv();
    t.initSvg();
    // Needs to be just after the svg itself.
    t.initBackground();
    // Holds child components (nodes, links), i.e. all but the background
    t.initSvgGroup();
    t.initBackgroundZoom();
    t.initGraphLinksGroup();
    t.initGraphNodesGroup(); // Must init **after** links, so nodes on top
    t.initSimulation();
    t.initNodeDrag();

    t.update();
  }
  initGraphDiv() {
    let t = this;

    t.rect = t.graphDiv.getBoundingClientRect();
    t.width = t.graphDiv.offsetWidth;
    t.height = t.graphDiv.offsetHeight;
    t.parentWidth = t.graphDiv.parentNode.offsetWidth;
    t.parentHeight = t.graphDiv.parentNode.offsetHeight;
    t.center = {x: t.width / 2, y: t.height / 2};
  }
  initSvg() {
    let t = this;

    // graph area
    t.svg = d3.select(t.graphDiv)
      .append("svg")
      .attr('id', t.svgId)
      .attr("width", "100%")
      .attr("height", "100%")
      // .attr('width', t.width)
      // .attr('height', t.height);
  }
  initBackground(svg) {
    let t = this;

    if (t.getBackgroundShape() === "circle") {
      let radius = Math.trunc(t.width / 2);
      t.background = t.svg
        .append("circle")
        .attr("id", () => t.getUniqueId(/*id*/ "background"))
        .attr("fill", () => t.getBackgroundFill())
        .attr("opacity", () => t.getBackgroundOpacity())
        // .attr("class", "view")
        .attr("x", radius)
        .attr("y", radius)
        .attr("cx", radius)
        .attr("cy", radius)
        .attr("r", radius)
        .on("click", () => t.handleBackgroundClicked())
        .on("contextmenu", () => t.handleBackgroundContextMenu());
    } else {
      t.background = t.svg
        .append("rect")
        .attr("id", () => t.getUniqueId(/*id*/ "background"))
        .attr("fill", () => t.getBackgroundFill())
        .attr("opacity", () => t.getBackgroundOpacity())
        // .attr("class", "view")
        .attr("x", 0)
        .attr("y", 0)
        .attr("width", "100%")
        .attr("height", "100%")
        // .attr("width", t.width)
        // .attr("height", t.height)
        .attr("border-style", "solid")
        .attr("border-width", "1px")
        .attr("stroke", "pink")
        .attr("stroke-width", "3px")
        // .attr("x", 0.5)
        // .attr("y", 0.5)
        // .attr("width", t.width - 1)
        // .attr("height", t.height - 1)
        .on("click", () => t.handleBackgroundClicked())
        .on("contextmenu", () => t.handleBackgroundContextMenu());
    }
  }
  initSvgGroup() {
    let t = this;

    t.svgGroup = t.svg
        .append('svg:g')
          .attr("id", t.getUniqueId("svgGroup"));
  }
  initGraphLinksGroup() {
    let t = this;

    t.graphLinksGroup =
      t.svgGroup
        .append("g")
        .attr("id", () => t.getGraphLinksGroupId())
        .attr("class", "links");
  }
  initGraphNodesGroup() {
    let t = this;

    t.graphNodesGroup =
      t.svgGroup
        .append("g")
        .attr("id", () => t.getGraphNodesGroupId())
        .attr("class", "nodes");
  }
  initBackgroundZoom() {
    let t = this;

    t.zoom =
      d3.zoom()
        .on("zoom", () => t.handleZoom(t.svgGroup));
    t.background.call(t.zoom);
  }
  initSimulation() {
    let t = this;

    t.simulation =
        d3.forceSimulation()
          .velocityDecay(t.getVelocityDecay())
          .alphaTarget(0.1)
          .force("link", t.getForceLink())
          .force("charge", t.getForceCharge())
          .force("collide", t.getForceCollide())
          .force("center", t.getForceCenter());
  }
  initNodeDrag() {
    let t = this;

    t.drag =
      t.isChild && t.shareDataReference ?
        t.parent.drag :
        d3.drag()
          .on("start", d => t.handleDragStarted(d))
          .on("drag", d => t.handleDragged(d))
          .on("end", d => t.handleDragEnded(d));
  }

  /**
   * Updates the d3 graph after a change to the underlying data, i.e. when
   * a datapoint is added/removed.
   */
  update() {
    let t = this;

    t.updateNodeDataJoins();
    t.updateNodeShapes();
    t.updateNodeLabels();
    t.updateNodeImages();
    t.updateNodeHyperlinks();
    t.updateLinkDataJoins();
    t.updateSimulation();
  }
  updateNodeDataJoins(nodes) {
    let t = this;
    var menu = [
        {
            title: 'Item #1',
            action: function(elm, d, i) {
                console.log('Item #1 clicked!');
                console.log('The data for this circle is: ' + d);
            },
            disabled: false // optional, defaults to false
        },
        {
            title: 'Item #2',
            action: function(elm, d, i) {
                console.log('You have clicked the second item!');
                console.log('The data for this circle is: ' + d);
            }
        }
    ]

    t.graphNodesData =
      t.graphNodesGroup
        .selectAll("g")
        .data(t.graphData.nodes, d => t.nodeKeyFunction(d));
    t.graphNodesEnter =
      t.graphNodesData
        .enter()
          .append("g")
          .attr("id", d => t.nodeKeyFunction(d))
          .attr("cursor", d => t.getNodeCursor(d))
          .on("contextmenu", d  => t.handleNodeContextMenu(d))
          .on("mousedown", d => t.handleNodeRawMouseDown(d))
          .on("mouseover", d=> t.handleNodeRawMouseOver(d))
          .on("mouseout", d => t.handleNodeRawMouseOut(d))
          // Using "click" event because mouseup event doesn't fire
          .on("click", d => t.handleNodeRawMouseUp(d))
          .on("touchstart", d => t.handleNodeRawTouchStart(d))
          .on("touchend", d => t.handleNodeRawTouchEnd(d))
          .call(t.drag);
    t.graphNodesExit =
      t.graphNodesData
        .exit()
        .remove();
    // merge the enter with the update
    t.graphNodesData =
      t.graphNodesEnter.merge(t.graphNodesData);
  }
  updateNodeShapes() {
    let t = this;

    t.graphNodeCircles =
      t.graphNodesEnter
        .filter(d => t.getNodeShape(d) === "circle")
        .append("circle")
        .attr("id", d => t.getNodeShapeId(d))
        .attr("r", d => t.getNodeShapeRadius(d))
        .attr("fill", d => t.getNodeShapeFill(d))
        .attr("stroke", d => t.getNodeBorderStroke(d))
        .attr("stroke-width", d => t.getNodeBorderStrokeWidth(d))
        .attr("stroke-dasharray", d => t.getNodeBorderStrokeDashArray(d))
        .attr("opacity", d => t.getNodeShapeOpacity(d));

    t.graphNodeRects =
      t.graphNodesEnter
        .filter(d => t.getNodeShape(d) === "rect")
        .append("rect")
        .attr("id", d => t.getNodeShapeId(d))
        .attr("width", d => t.getNodeShapeWidth(d))
        .attr("height", d => t.getNodeShapeHeight(d))
        .attr("x", d => Math.trunc(-1/2 * t.getNodeShapeWidth(d)))
        .attr("y", d => Math.trunc(-1/2 * t.getNodeShapeHeight(d)))
        .attr("fill", d => t.getNodeShapeFill(d))
        .attr("stroke", d => t.getNodeBorderStroke(d))
        .attr("stroke-width", d => t.getNodeBorderStrokeWidth(d))
        .attr("stroke-dasharray", d => t.getNodeBorderStrokeDashArray(d))
        .attr("opacity", d => t.getNodeShapeOpacity(d));

    t.graphNodeShapes = t.graphNodeCircles.merge(t.graphNodeRects);

    t.graphNodeShapes
      .append("title")
      .text(d => t.getNodeTitle(d));
  }
  updateNodeLabels() {
    let t = this;

    t.graphNodeLabels =
      t.graphNodesEnter
        .append("text")
        .attr("id", d => t.getNodeLabelId(d))
        .attr("font-size", d => t.getNodeLabelFontSize(d))
        .attr("font-family", d => t.getNodeLabelFontFamily(d))
        // .attr("stroke", "green")
        .attr("stroke", d => t.getNodeLabelStroke(d))
        .attr("fill", d => t.getNodeLabelFill(d))
        .attr("text-anchor", "middle")
        .attr("y", d => t.getNodeLabelFontOffset(d))
        .text(d => t.getNodeLabelText(d));
    t.graphNodeLabels
      .append("title")
      .text(d => t.getNodeTitle(d));
  }
  updateNodeImages() {
    let t = this;

    t.graphNodesEnter_Images =
      t.graphNodesEnter
        .filter(d => {
          return t.getNodeRenderType(d) === "image";
        });

    t.graphImageDefs =
      t.graphNodesEnter_Images
        .append("defs")
        .attr("id", d => {
          return t.getNodeImageDefId(d);
        });

    t.graphImagePatterns =
      t.graphImageDefs
        .append("pattern")
        .attr("id", d => t.getNodeImagePatternId(d))
        .attr("height", d => t.getNodeImagePatternHeight(d))
        .attr("width", d => t.getNodeImagePatternWidth(d))
        .attr("x", 0)
        .attr("y", 0);

    t.imagePatternBackgrounds_Circle =
      t.graphImagePatterns
        .filter(d => t.getNodeShape(d) === "circle")
        .append("circle")
        .attr("r", d => t.getNodeShapeRadius(d))
        .attr("cx", d => t.getNodeShapeRadius(d))
        .attr("cy", d => t.getNodeShapeRadius(d))
        .attr("fill", d => t.getNodeImageBackgroundFill(d));

    t.imagePatternBackground_Rect =
      t.graphImagePatterns
        .filter(d => t.getNodeShape(d) === "rect")
        .append("rect")
        .attr("width", d => t.getNodeShapeWidth(d))
        .attr("height", d => t.getNodeShapeHeight(d))
        .attr("cx", d => Math.trunc(t.getNodeShapeWidth(d) / 2))
        .attr("cy", d => Math.trunc(t.getNodeShapeHeight(d) / 2))
        .attr("fill", d => t.getNodeImageBackgroundFill(d));

    t.graphNodesEnter_Images
      .data()
      .map(d => {
        // console.log(`updating pattern: ${t.getNodeShapeId(d)} in graph ${t.svgId}`)
        d3.select("#" + t.getNodeShapeId(d))
          .attr("fill", `url(#${t.getNodeImagePatternId(d)})`)
          .append("title")
            .text(d => t.getNodeTitle(d));
      });

    t.graphNodeImagePatternImage =
      t.graphImagePatterns
        .append("image")
        .attr("id", d => t.getNodeImageId(d))
        .attr("opacity", 1)
        .attr("height", d => t.getNodeImageMagicSize(d))
        .attr("width", d => t.getNodeImageMagicSize(d))
        .attr("x", d => t.getNodeImageMagicOffset(d))
        .attr("y", d => t.getNodeImageMagicOffset(d))
        .attr("xlink:href", d => t.getNodeImageHref(d));
  }
  updateNodeHyperlinks() {
    let t = this;

    t.graphNodesEnter_Hyperlinks =
      t.graphNodesEnter
        .append("foreignObject")
        .attr("name", "graphNodeLink")
        .attr("width", 1)
        .attr("height", 1)
        .html('<a href="#"></a>');
  }
  updateLinkDataJoins() {
    let t = this;

    // links
    t.graphLinksData =
      t.graphLinksGroup
        .selectAll("line")
        .data(t.graphData.links);
    t.graphLinksEnter =
       t.graphLinksData
        .enter()
          .append("line");
    t.graphLinksExit =
      t.graphLinksData
        .exit()
        .remove();
    // merge the enter with the update
    t.graphLinksData =
      t.graphLinksEnter.merge(t.graphLinksData);
  }
  updateSimulation() {
    let t = this;

    // Attach the nodes and links to the simulation.
    t.simulation
      .nodes(t.graphData.nodes)
      .on("tick", () => t.handleTicked())
      .on("end", () => t.handleSimulationEnd());
    t.simulation
      .force("link")
      .links(t.graphData.links);
  }

  handleDragStarted(d) {
    let t = this;
    // console.log("drag started")

    if (!d3.event.active) {
      t.simulation.alphaTarget(0.1).restart();
      t.children.filter(child => child.shareDataReference === true).forEach(child => child.simulation.alphaTarget(0.1).restart());
      if (t.isChild && t.parent && t.shareDataReference) {
        t.parent.simulation.alphaTarget(0.1).restart();
      }
    }


    // Fixes the position of the node to the event (mouse/touch pos)
    if (d.fx || d.fy) {
      d.fixedBeforeDragStarted = true;
    } else {
      delete d.fixedBeforeDragStarted;
    }

    d.fx = d.x;
    d.fy = d.y;

    t.x0 = d3.event.x;
    t.y0 = d3.event.y;

    // console.log(`drag started d.fx: ${d.fx}`)
  }
  handleDragged(d) {
    let t = this;

    // Fixes the position of the node to the event (mouse/touch pos)
    d.fx = d3.event.x;
    d.fy = d3.event.y;

    // If we're dragging, then cancel any long press. The distance thing is to
    // avoid jitter of a person's finger/mouse when long pressing.
    let dist = Math.sqrt(Math.pow(t.x0 - d.fx, 2) + Math.pow(t.y0 - d.fy, 2));
    // console.log(`dist: ${dist}`)
    if (dist > 25) {
      t.dragging = true;
      if (t.longPressTimeout) {
        clearTimeout(t.longPressTimeout);
        delete t.longPressTimeout;
      }

      delete t.lastMouseDownTime;
      delete t.mouseDownCounter;
    }
  }
  handleDragEnded(d) {
    let t = this;
    // console.log("handleDragEnded")

    t.handleNodeRawMouseUp(d);

    if (!d3.event.active) {
      t.simulation.alphaTarget(0);
      t.children.filter(child => child.shareDataReference).forEach(child => child.simulation.alphaTarget(0));
      if (t.isChild && t.parent && t.shareDataReference) {
        t.parent.simulation.alphaTarget(0);
      }
    }

    delete t.dragging;

    let dist = Math.sqrt(Math.pow(t.x0 - d.fx, 2) + Math.pow(t.y0 - d.fy, 2));

    d.x = d.fx;
    d.y = d.fy;

    if (!d.fixedBeforeDragStarted) {
      // console.log("clearing d.fx and d.fy")
      d.fx = undefined;
      d.fy = undefined;
    }

    t.x0 = null;
    t.y0 = null;

    t.animateNodeBorder(d);
  }
  handleBackgroundClicked() {
    // console.log(`background clicked in numero 2`);
  }
  handleBackgroundContextMenu() {
    // console.log(`background context`)
    d3.event.preventDefault();
  }
  handleZoom(svgGroup) {
    svgGroup
      .attr("transform",
      `translate(${d3.event.transform.x}, ${d3.event.transform.y})` + " " +
      `scale(${d3.event.transform.k})`);
  }
  handleTicked() {
    let t = this;
    // console.log('ticked')

    try {
      // Update the link Positions
      t.graphLinksData
        .attr("x1", d => {
          // hack b/c of freezing nodes change causes NaN errors...not sure how to diag
          // see commit https://github.com/ibgib/ibgib/commit/7a4b37b642356e099089af350287812ff0aa2f57
          if (isNaN(d.source.x)) {
            d.source.x = d.source.lastX ? d.source.lastX : 0;
          } else {
            d.source.lastX = d.source.x;
          }
          return d.source.x;
        })
        .attr("y1", d => {
          // hack b/c of freezing nodes change causes NaN errors...not sure how to diag
          // see commit https://github.com/ibgib/ibgib/commit/7a4b37b642356e099089af350287812ff0aa2f57
          if (isNaN(d.source.y)) {
            d.source.y = d.source.lastY ? d.source.lastY : 0;
          } else {
            d.source.lastY = d.source.y;
          }
          return d.source.y;
        })
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);

      // Translate the node groups
      t.graphNodesData
          .attr("transform", d => {
            let x = isNaN(d.x) ? (d.lastX || 0) : d.x;
            let y = isNaN(d.y) ? (d.lastY || 0) : d.y;

            return 'translate(' + [x, y] + ')';
          });
    } catch (e) {
      console.log("errored tick")
    }
  }
  handleNodeContextMenu(d) {
    d3.event.preventDefault();
    // let t = this;
    // to show how to use it
    // t.remove(d, /*updateParentOrChild*/ true);
  }
  handleSimulationEnd() {
    console.log("end yo");
  }
  handleResize() {
    let t = this;

    // For some reason, when resizing vertically, it doesn't always trigger
    // the graph itself to change sizes. So we're checking the parent.
    let nowWidth = t.graphDiv.parentNode.scrollWidth;
    let nowHeight = t.graphDiv.parentNode.scrollHeight;
    if (nowWidth !== t.parentWidth || nowHeight !== t.parentHeight) {
      // Completely restart the graph
      // I can't figure out how to cache/restore the zoom transform.
      t.destroy();
      t.init();
    }
  }
  // Actual Click handlers (not raw)
  handleNodeNormalClicked(d) {
    console.log(`node clicked: ${JSON.stringify(d)}`);

    let t = this;
    let newId = Math.trunc(Math.random() * 100000);
    let newNode = {
      id: newId,
      name: "server 22",
      shape: Math.random() > 0.5 ? "circle" : "rect",
      render: "image",
      x: d.x,
      y: d.y
    };
    let newNodes = [newNode];
    let newLinks = [{source: d.id, target: newNode.id}]

    t.add(newNodes, newLinks, /*updateParentOrChild*/ true);

    t.animateNodeBorder(d, /*nodeShape*/ null);
    t.animateNodeBorder(newNode, /*nodeShape*/ null);
  }
  handleNodeLongClicked(d) {
    console.log(`node longclicked. d: ${JSON.stringify(d)}`);
  }
  handleNodeDblClicked(d) {
    let t = this;
    console.log(`node doubleclicked. d: ${JSON.stringify(d)}`);

    // delete t.lastMouseDownTime;
    // delete t.beforeLastMouseDownTime;
  }
  handleNodeRawMouseDownOrTouchstart(d) {
    let t = this;

    t.mouseDownCounter = t.mouseDownCounter || 1;

    if (t.longPressTimeout) {
      clearTimeout(t.longPressTimeout);
      delete t.longPressTimeout;
    }

    if (t.dblClickTimeout) {
      // we're clicking again within the dblClickMs
      clearTimeout(t.dblClickTimeout);
      delete t.dblClickTimeout;
      t.mouseDownCounter += 1;
      t.handleNodeDblClicked(d);
    } else {
      t.dblClickTimeout = setTimeout(() => {
        delete t.dblClickTimeout;
      }, t.config.mouse.dblClickMs);

      t.longPressTimeout = setTimeout(() => {
        if (t.longPressTimeout) {
          t.longClicked = true;
          clearTimeout(t.longPressTimeout);
          delete t.longPressTimeout;
          delete t.mouseDownCounter;
          t.handleNodeLongClicked(d);
        }
      }, t.config.mouse.longPressMs);
    }

    t.animateNodeBorder(d, /*nodeShape*/ null);
  }
  handleNodeRawMouseUpOrTouchEnd(d) {
    let t = this;

    if (t.dragging) {
      delete t.dragging;
      return;
    }

    t.lastMouseUpTime = new Date();
    delete t.lastMouseDownTime;

    if (t.longPressTimeout) {
      clearTimeout(t.longPressTimeout);
      delete t.longPressTimeout;
    }

    if (t.longClicked) {
      delete t.longClicked;
      // do nothing
    } else {
      // either we've just clicked a single click, the first click of a double-click or the second click of a double-click.
      // If it's a single click, then if we wait the double-click amount of
      // time and the mouse down counter is 1.
      // If it's a double-click part 1, then if we wait the double-click time
      // then the mouse down counter will be > 1.
      // If it's a double-click part 2, then if we wait the double-click time
      // then the mouse down counter will be > 1.

      setTimeout(() => {
        if (t.mouseDownCounter && t.mouseDownCounter === 1) {
          delete t.mouseDownCounter;
          t.handleNodeNormalClicked(d);
        } else {
          // some kind of double-clicking going on, so do nothing.
          delete t.mouseDownCounter;
        }
      }, t.config.mouse.dblClickMs);
    }
  }
  handleNodeRawMouseDown(d) {
    let t = this;

    if (d3.event.button === 0) {
      t.isTouch = false;
      t.mouseOrTouchPosition = d3.mouse(t.background.node());
      t.lastMouseDownEvent = d3.event;
      t.targetNode = t.lastMouseDownEvent.target;
        t.handleNodeRawMouseDownOrTouchstart(d);
      d3.event.preventDefault();
    }
  }
  handleNodeRawMouseOver(d) {
    // do nothing by default
  }
  handleNodeRawMouseOut(d) {
    let t = this;
    if (t.longClicked) { delete t.longClicked; }
  }
  handleNodeRawMouseUp(d) {
    // console.log("handleNodeRawMouseUp")
    this.handleNodeRawMouseUpOrTouchEnd(d);
  }
  handleNodeRawTouchStart(d) {
    let t = this;

    t.isTouch = true;
    t.lastTouchStart = d3.event;
    t.targetNode = d3.event.target;
    t.mouseOrTouchPosition = [
      t.lastTouchStart.touches[0].clientX,
      t.lastTouchStart.touches[0].clientY
    ];
    t.handleNodeRawMouseDownOrTouchstart(d);
    d3.event.preventDefault();
  }
  handleNodeRawTouchEnd(d) {
    this.handleNodeRawMouseUpOrTouchEnd(d);
  }

  // Dynamic add/remove nodes/links
  /*
   * Adds node(s) and link(s) to the graph and updates the simulation.
   *
   * @param `updateParentOrChild` is for use with avoid recursion with parent/child graphs. (So probably going forward, set this to true.)
   */
  add(nodesToAdd, linksToAdd, updateParentOrChild) {
    let t = this;

    if (nodesToAdd) {
      nodesToAdd.forEach(n => t.graphData.nodes.push(n));
    }
    if (linksToAdd) {
      linksToAdd.forEach(l => t.graphData.links.push(l));
    }

    t.update();
    t.simulation.restart();
    t.simulation.alpha(1);

    if (updateParentOrChild) {
      if (t.isChild) {
        if (t.shareDataReference) {
          // child sharing data, just update
          t.updateParent();
        } else {
          // child not sharing data passing clones to parent

          // If we don't share a data reference then we must actually duplicate
          // this call on the parent with duplicate json.
          let nodesToAddClone = nodesToAdd.map(n => t.cloneJson(n));
          let srcNodes = nodesToAddClone.concat(t.graphData.nodes);
          let linksToAddClone = linksToAdd.map(l => {
            let newSource = srcNodes.filter(n => t.nodeKeyFunction(n) === t.nodeKeyFunction(l.source))[0];
            let newTarget = srcNodes.filter(n => t.nodeKeyFunction(n) === t.nodeKeyFunction(l.target))[0];

            return { source: newSource.id, target: newTarget.id };
          });

          t.parent.add(nodesToAddClone, linksToAddClone, /*updateParentOrChild*/ false);
        }
      } else {
        // If we don't share a data reference then we must actually duplicate
        // this call on the parent with duplicate json.
        let nodesToAddClone = nodesToAdd.map(n => t.cloneJson(n));
        let srcNodes = nodesToAdd.concat(t.graphData.nodes);
        let linksToAddClone = linksToAdd.map(l => {
          let newSource = srcNodes.filter(n => t.nodeKeyFunction(n) === t.nodeKeyFunction(l.source))[0];
          let newTarget = srcNodes.filter(n => t.nodeKeyFunction(n) === t.nodeKeyFunction(l.target))[0];

          return { source: newSource.id, target: newTarget.id };
        });

        // For children that do not share data
        t.children
          .filter(child => !child.shareDataReference)
          .map(child => child.add(nodesToAddClone, linksToAddClone, /*updateParentOrChild*/ false));

        // Update children that do share data
        t.updateChildrenYo(/*onlyChildrenSharingData*/ true);
      }
    }
  }
  /**
   * Removes node (and any links) from graph.
   *
   * @param `updateParentOrChild` is for use with avoid recursion with parent/child graphs. (So probably going forward, set this to true.)
   */
  remove(dToRemove, updateParentOrChild) {
    // console.log(`dToRemove: ${JSON.stringify(dToRemove)}`)

    let t = this;
    let currentNodes = t.graphData.nodes;
    let currentLinks = t.graphData.links;
    let toRemoveRef = currentNodes.filter(n => t.nodeKeyFunction(n) === t.nodeKeyFunction(dToRemove))[0];
    let nIndex = currentNodes.indexOf(toRemoveRef);
    if (nIndex > -1) {
      currentNodes.splice(nIndex, 1);
    } else {
      console.warn("remove not found")
    }

    let toRemoveLinks = currentLinks.filter(l => {
      return t.nodeKeyFunction(l.source) === t.nodeKeyFunction(dToRemove) ||
        t.nodeKeyFunction(l.target) === t.nodeKeyFunction(dToRemove);
    });
    toRemoveLinks.forEach(l => {
      let lIndex = currentLinks.indexOf(l);
      currentLinks.splice(lIndex, 1);
    })

    t.update();
    t.simulation.restart();
    t.simulation.alpha(1);

    if (updateParentOrChild && t.isChild) {
      if (t.shareDataReference) {
        // We are sharing a reference to the same data object in memory, so
        // we only need to update the parent.
        t.updateParent();
      } else {
        // We're not sharing the data, so duplicate the call
        t.parent.remove(dToRemove, /*updateParentOrChild*/ false);
      }
    } else if (updateParentOrChild && !t.isChild) {
      // For children that do not share data
      t.children
        .filter(child => !child.shareDataReference)
        .map(child => child.remove(dToRemove, /*updateParentOrChild*/ false));

      // Update children that do share data
      t.updateChildrenYo(/*onlyChildrenSharingData*/ true);
    }
  }
  /** Untested. I ended up not using this...but keeping it here for now */
  swap(existingNode, newNode, updateParentOrChild) {
    let t = this;

    // find links to existing node
    let linksA = t.graphData.links
      .filter(l => l.source.id === existingNode.id)
      .map(l => { return {source: newNode.id, target: l.target.id}; });
    let linksB = t.graphData.links
      .filter(l => l.target.id === existingNode.id)
      .map(l => { return {source: l.source.id, target: newNode.id}; });
    let newLinks = linksA.concat(linksB);

    // remove the old node and add the new one with the adjusted links.
    let x = existingNode.x;
    let y = existingNode.y;
    t.remove(existingNode, updateParentOrChild);
    newNode.x = x;
    newNode.y = y;
    t.add([newNode], newLinks, updateParentOrChild);
  }
  addChildGraph(child, shareDataReference) {
    let t = this;
    t.children.push(child);
    child.isChild = true;
    child.parent = t;
    child.shareDataReference = shareDataReference;

    child.graphData = shareDataReference ? t.graphData : t.copyGraphData();

    child.init();
    t.updateChildrenYo(/*onlyChildrenSharingData*/ false);
  }
  destroyChildGraph(childGraph) {
    let index = this.children.indexOf(childGraph);
    if (index > -1) {
      this.children.splice(index, 1);
      childGraph.destroy();
    } else {
      console.warn("Tried to remove child from d3 force graph but it wasn't found.");
    }
  }

  // Child/parent graph helper methods
  cloneJson(jsonSrc) { return JSON.parse(JSON.stringify(jsonSrc)); }
  updateChildrenYo(onlyChildrenSharingData) {
    let t = this;

    let toUpdate =
      onlyChildrenSharingData ?
        t.children.filter(child => child.shareDataReference) :
        t.children;

    toUpdate
      .forEach(child => {
        child.update();
        child.simulation.restart();
        child.simulation.alpha(1);
      });
  }
  updateParent() {
    let t = this;
    t.parent.update();
    t.parent.simulation.restart();
    t.parent.simulation.alpha(1);
  }
  copyGraphData() {
    return {
      nodes: this.graphData.nodes.splice(0),
      links: this.graphData.links.splice(0)
    };
  }

  // Other ?
  toggleFullScreen() {
    let elementJquerySelector = `#${this.graphDiv.id}`
    let selection = d3.select(elementJquerySelector);
    let node = selection.node();
    let isFullscreen = selection.classed("ib-fullscreen");
    let body = d3.select("body").node();

    if (isFullscreen) {
      // return from fullscreen
      body.removeChild(node);
      this.currentParent.appendChild(node);
      selection
        .classed("ib-fullscreen", false);
    } else {
      // go fullscreen
      this.currentParent = node.parentNode;
      this.currentParent.removeChild(node)
      body.appendChild(node);
      selection
        .classed("ib-fullscreen", true);
    }

    this.destroy();
    this.init();
  }
  getUniqueId(id, prefix, suffix) {
    let result = this.svgId;
    if (prefix) { result += `_${prefix}`; }
    if (id) {
      if (id.replace) {
        result += `_${id.replace("^", "-")}`;
      } else {
        result += `_${id}`;
      }
    }
    if (suffix) { result += `_${suffix}`; }
    return result;
  }

  // Svg Framing (svg, svgGroup, links group, nodes group, background)
  getGraphLinksGroupId() { return `${this.svgId}_linksGroup`; }
  getGraphNodesGroupId() { return `${this.svgId}_nodesGroup`; }
  getBackgroundFill() { return this.config.background.fill; }
  getBackgroundOpacity() { return this.config.background.opacity; }
  getBackgroundShape() { return this.config.background.shape; }

  // Force Simulation Config
  getVelocityDecay() { return this.config.simulation.velocityDecay; }
  getForceLink() {
    let t = this;

    return d3.forceLink()
             .distance(d => t.getForceLinkDistance(d))
             .id(d => t.getForceLinkId(d));
  }
  getForceLinkId(d) { return this.nodeKeyFunction(d); }
  getForceLinkDistance(d) { return this.config.simulation.linkDistance; }
  getForceCharge() {
    let t = this;
    return d3.forceManyBody()
      .strength(d => t.getForceChargeStrength(d))
      .distanceMin(this.config.simulation.chargeDistanceMin)
      .distanceMax(this.config.simulation.chargeDistanceMax);
  }
  getForceChargeStrength(d) { return this.config.simulation.chargeStrength; }
  getForceCollide() {
    return d3.forceCollide(d => this.getForceCollideDistance(d));
  }
  getForceCollideDistance(d) {
    let radius = this.getNodeShapeRadius(d);
    // 1.4142 is square root of 2
    let result = d.shape && d.shape === "rect" ? radius * 1.4142 : radius;

    return result;
  }
  getForceCenter() { return d3.forceCenter(this.center.x, this.center.y); }

  // Nodes functions
  nodeKeyFunction(d) { return d.id; }
  // getNodeLabelId(d) { return this.svgId + "_label_" + d.id; }
  getNodeLabelId(d) { return this.getUniqueId(d.id, /*prefix*/ "label"); }
  getNodeLabelFontSize(d) { return this.config.node.label.fontSize; }
  getNodeLabelFontFamily(d) {
    return d.fontFamily ? d.fontFamily : this.config.node.label.fontFamily;
  }
  getNodeLabelFontOffset(d) {
    return d.fontOffset ? d.fontOffset : this.config.node.label.fontOffset;
  }
  getNodeLabelStroke(d) { return this.config.node.label.fontStroke; }
  getNodeLabelFill(d) { return this.config.node.label.fontFill; }
  getNodeRenderType(d) { return d.render ? d.render : "default"; }
  getNodeShapeId(d) {
    if (!d || !d.id) {
      return null;
    }
    return this.getUniqueId(d.id, /*prefix*/ "shape");
  }
  getNodeCursor(d) { return this.config.node.cursorType; }
  getNodeTitle(d) { return d.title || d.id || ""; }
  getNodeLabelText(d) { return d.label || d.title || d.id; }
  getNodeShape(d) {
    return d.shape && (d.shape === "circle" || d.shape === "rect") ? d.shape : "circle";
  }
  getNodeShapeRadius(d) {
    let t = this;
    // console.log("getNodeShapeRadius");
    const min = 1 * t.config.node.baseRadiusSize;
    const max = 3 * t.config.node.baseRadiusSize;
    let x = Math.abs(50000 - (d.id || 1)) / 50000;
    let r = Math.trunc(x * 50);
    if (r < min) r = min;
    if (r > max) r = max;

    d.r = r;

    return r;
  }
  getNodeShapeHeight(d) { return (2 * this.getNodeShapeRadius(d)); }
  getNodeShapeWidth(d) { return (2 * this.getNodeShapeRadius(d)); }
  getNodeShapeFill(d) { return this.config.node.defShapeFill; }
  getNodeBorderStroke(d) { return this.config.node.defBorderStroke; }
  getNodeBorderStrokeWidth(d) { return this.config.node.defBorderStrokeWidth; }
  getNodeBorderStrokeDashArray(d) { return null; }
  getNodeShapeOpacity(d) { return 1; }

  // Node image
  getNodeImageGroupId(d) {
    console.log("getNodeImageGroupId")
    return this.svgId + "_imgGroup_" + d.id;
  }
  getNodeImageDefId(d) { return this.svgId + "_imgDefs_" + d.id; }
  getNodeImagePatternId(d) { return this.svgId + "_imgPattern_" + d.id; }
  getNodeImagePatternHeight(d) { return 1; }
  getNodeImagePatternWidth(d) { return 1; }
  getNodeImageId(d) { return this.svgId + "_img_" + d.id; }
  getNodeImageHref(d) { return d.imageHref || "/android-chrome-512x512.png"; }
  getNodeImageBackgroundFill(d) { return this.config.node.image.backgroundFill; }
  /** Magic formula to get the node image/background positioning correct. */
  getNodeImageMagicSize(d) { return 55 * (d.r / 25); }
  /** Magic formula to get the node image/background positioning correct. */
  getNodeImageMagicOffset(d) { return -2.5 * (d.r / 25); }

  /**
   * Applies super-fun border transition effect to `nodeShape`.
   * If `nodeShape` is not given, then will selected it from `d.id`.
   * @param type is color transition type. If `type` is not given, defaults to "rainbow". Possible values = "rainbow", "error"
   */
  animateNodeBorder(d, nodeShape, type) {
    let t = this;

    nodeShape = nodeShape ? nodeShape : d3.select("#" + t.getNodeShapeId(d));

    let colorTransitions = t.getColorTransitions(type);

    var transition =
      d3.transition()
        .duration(75)
        .ease(d3.easeLinear);

    nodeShape
      .transition(transition)
      .attr("stroke", colorTransitions[0])
      .attr("stroke-width", "5px")
      .transition(transition)
      .attr("stroke", colorTransitions[1])
      .attr("stroke-width", "10px")
      .transition(transition)
      .attr("stroke", colorTransitions[2])
      .attr("stroke-width", "15px")
      .transition(transition)
      .attr("stroke", colorTransitions[3])
      .attr("stroke-width", "16px")
      .transition(transition)
      .attr("stroke", colorTransitions[4])
      .attr("stroke-width", "15px")
      .transition(transition)
      .attr("stroke", colorTransitions[5])
      .attr("stroke-width", "10px")
      .transition(transition)
      .attr("stroke", colorTransitions[6])
      .attr("stroke-width", "5px")
      .transition(transition)
      .attr("stroke", d => t.getNodeBorderStroke(nodeShape.data()))
      .attr("stroke-width", t.getNodeBorderStrokeWidth(nodeShape.data()));
  }


  getColorTransitions(type) {
    let rainbow = [
      "red", "orange", "yellow", "green", "blue", "indigo", "violet"
    ]
    let error = [
      "red", "red", "red", "red", "red", "red", "red"
    ]

    switch (type || "") {
      case "rainbow": return rainbow;
      case "error": return error;
      default: return rainbow;
    }
  }

  setBusy(d) {
    let t = this;

    if (d.busy) {
      return;
    } else {
      d.busy = true;
      d.busyInterval = setInterval(() => {
        if (d.busy) {
          t.animateNodeBorder(d, /*nodeShape*/ null);
        }
      }, 1000);
    }
  }
  clearBusy(d) {
    if (d.busy) { delete d.busy; }
    if (d.busyInterval) {
      clearInterval(d.busyInterval);
      delete d.busyInterval;
    }
  }

  setErrored(d, clearAfterMsg, emsg) {
    let t = this;

    if (d.errored) {
      return;
    } else {
      d.errored = true;
      d.clearAfterMsg = clearAfterMsg;
      d.emsg = emsg;
      d.erroredInterval = setInterval(() => {
        if (d.errored) {
          t.animateNodeBorder(d, /*nodeShape*/ null, "error");
        }
      }, 1000);
    }
  }
  clearErrored(d) {
    if (d.errored) { delete d.errored; }
    if (d.clearAfterMsg) { delete d.clearAfterMsg; }
    if (d.emsg) { delete d.emsg; }
    if (d.erroredInterval) {
      clearInterval(d.erroredInterval);
      delete d.erroredInterval;
    }
  }

  highlightNode(d, type, durationMs) {
    let t = this;
    let start = Date.now();
    let interval = setInterval(() => {
      let elapsed = Date.now() - start;
      if (elapsed >= durationMs) { clearInterval(interval); }
      t.animateNodeBorder(d, /*nodeShape*/ null, type);
    }, 1000);
  }
}
