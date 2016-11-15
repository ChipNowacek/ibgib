import * as d3 from 'd3';

export class DynamicD3ForceGraph {
  constructor(graphDiv, svgId) {
    let t = this;

    t.graphDiv = graphDiv;
    t.svgId = svgId;

    t.graphData = { "nodes": [], "links": [] };
    t.children = [];
  }

  destroy() {
    let t = this;

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
    t.width = t.graphDiv.scrollWidth;
    t.height = t.graphDiv.scrollHeight;
    t.parentWidth = t.graphDiv.parentNode.scrollWidth;
    t.parentHeight = t.graphDiv.parentNode.scrollHeight;
    t.center = {x: t.width / 2, y: t.height / 2};
  }
  initSvg() {
    let t = this;

    // graph area
    t.svg = d3.select(t.graphDiv)
      .append("svg")
      .attr('id', t.svgId)
      .attr('width', t.width)
      .attr('height', t.height);
  }
  initBackground(svg) {
    let t = this;

    t.background = t.svg
      .append("rect")
      .attr("fill", () => t.getBackgroundFill())
      // .attr("class", "view")
      .attr("x", 0.5)
      .attr("y", 0.5)
      .attr("width", t.width - 1)
      .attr("height", t.height - 1)
      .on("click", () => t.handleBackgroundClicked());
  }
  initSvgGroup() {
    let t = this;

    t.svgGroup = t.svg
        .append('svg:g')
          .attr("id", "svgGroup");
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

    t.updateLinkDataJoins();
    t.updateSimulation();
  }
  updateNodeDataJoins(nodes) {
    let t = this;

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
          .on("mouseover", d => t.handleNodeMouseover(d))
          .on("click", d => t.handleNodeClicked(d))
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
        .attr("stroke-width", d => t.getNodeBorderStrokeWidth(d));

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
        .attr("stroke-width", d => t.getNodeBorderStrokeWidth(d));

    t.graphNodeShapes = t.graphNodeCircles.merge(t.graphNodeRects);
  }
  updateNodeLabels() {
    let t = this;

    t.graphNodeLabels =
      t.graphNodesEnter
        .append("text")
        .attr("id", d => t.getNodeLabelId(d))
        .attr("font-size", `10px`)
        .attr("text-anchor", "middle")
        .text(d => `${d.id}`);
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
        console.log(`updating pattern: ${t.getNodeShapeId(d)} in graph ${t.svgId}`)
        d3.select("#" + t.getNodeShapeId(d))
          .attr("fill", `url(#${t.getNodeImagePatternId(d)})`)
          .append("title")
            .text(d => t.getNodeTitle(d));
      });

    //

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
    // t.graphNodeImagePatternTitle =
    //   t.graphImagePatterns
    //     .append("title")
    //     .text(d => d.id);
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
      .on("end", () => t.handleEnd());
    t.simulation
      .force("link")
      .links(t.graphData.links);
  }

  handleDragStarted(d) {
    if (!d3.event.active) {
      this.simulation.alphaTarget(0.1).restart();
      this.children.filter(child => child.shareDataReference === true).forEach(child => child.simulation.alphaTarget(0.1).restart());
      if (this.isChild && this.parent && this.shareDataReference) {
        this.parent.simulation.alphaTarget(0.1).restart();
      }
    }

    d.fx = d.x;
    d.fy = d.y;

    console.log(`drag started d.fx: ${d.fx}`)
  }
  handleDragged(d) {
    // console.log(`dragged d.fx: ${d.fx}`)

    d.fx = d3.event.x;
    d.fy = d3.event.y;
  }
  handleDragEnded(d) {
    console.log("handleDragEnded")
    if (!d3.event.active) {
      this.simulation.alphaTarget(0);
      this.children.filter(child => child.shareDataReference).forEach(child => child.simulation.alphaTarget(0));
      if (this.isChild && this.parent && this.shareDataReference) {
        this.parent.simulation.alphaTarget(0);
      }
    }

    d.fx = d3.event.x;
    d.fy = d3.event.y;

    d.fx = undefined;
    d.fy = undefined;
  }
  handleBackgroundClicked() {
    console.log(`background clicked in numero 2`);
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
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);

      // Translate the node groups
      t.graphNodesData
          .attr("transform", d => {
              return 'translate(' + [d.x, d.y] + ')';
          });
    } catch (e) {
      console.log("errored tick")
    }
  }
  handleNodeClicked(d) {
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

    t.add(newNodes, newLinks, /*updateParent*/ true, /*updateChildren*/ true);
  }
  handleNodeContextMenu(d) {
    let t = this;
    d3.event.preventDefault();
    t.remove(d, /*updateParent*/ true, /*updateChildren*/ true);
  }
  handleNodeMouseover(d) {
    console.log(`d.id: ${d.id}`);
  }
  handleEnd() {
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

  add(nodesToAdd, linksToAdd, updateParent, updateChildren) {
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

    if (updateParent || updateChildren) {
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

          t.parent.add(nodesToAddClone, linksToAddClone, /*updateParent*/ false, /*updateChildren*/ false);
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
          .map(child => child.add(nodesToAddClone, linksToAddClone, /*updateParent*/ false, /*updateChildren*/ false));

        // Update children that do share data
        t.updateChildrenYo(/*onlyShareData*/ true);
      }
    }
  }
  remove(dToRemove, updateParent, updateChildren) {
    console.log(`dToRemove: ${JSON.stringify(dToRemove)}`)

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

    if (updateParent && t.isChild) {
      if (t.shareDataReference) {
        // We are sharing a reference to the same data object in memory, so
        // we only need to update the parent.
        t.updateParent();
      } else {
        // We're not sharing the data, so duplicate the call
        t.parent.remove(dToRemove, /*updateParent*/ false, /*updateChildren*/ false);
      }
    } else if (updateChildren && !t.isChild) {
      // For children that do not share data
      t.children
        .filter(child => !child.shareDataReference)
        .map(child => child.remove(dToRemove, /*updateParent*/ false, /*updateChildren*/ false));

      // Update children that do share data
      t.updateChildrenYo(/*onlyShareData*/ true);
    }
  }
  addChildGraph(child, shareDataReference) {
    let t = this;
    t.children.push(child);
    child.isChild = true;
    child.parent = t;
    child.shareDataReference = shareDataReference;

    child.graphData = shareDataReference ? t.graphData : t.copyGraphData();

    child.init();
    t.updateChildrenYo(/*onlyShareData*/ false);
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

  cloneJson(jsonSrc) { return JSON.parse(JSON.stringify(jsonSrc)); }
  updateChildrenYo(onlyShareData) {
    let t = this;

    let toUpdate =
      onlyShareData ?
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


  // getForceVelocityDecay(d) { return 0.25; }
  // getForceLinkDistance(d) { return 55; }
  // getForceStrength(d) { return 0.8; }
  // getForceChargeStrength(d) { return -25; }

  // Svg Framing (svg, svgGroup, links group, nodes group, background)
  getGraphLinksGroupId() { return `${this.svgId}_links_${this.svgId}`; }
  getGraphNodesGroupId() { return `${this.svgId}_nodes_${this.svgId}`; }
  // getBackgroundFill() { return "#F2F7F0"; }
  getBackgroundFill() { return "#F2F7F0"; }

  // Force Simulation Config
  getVelocityDecay() { return 0.55; }
  getForceLink() {
    return d3.forceLink()
             .distance(100)
             .id(d => d.id);
  }
  getForceCharge() {
    return d3.forceManyBody().strength(-100).distanceMin(10000);
  }
  getForceCollide() { return d3.forceCollide(25); }
  getForceCenter() { return d3.forceCenter(this.center.x, this.center.y); }

  // Nodes functions
  nodeKeyFunction(d) { return d.id; }
  getNodeLabelId(d) { return this.svgId + "_label_" + d.id; }
  getNodeRenderType(d) { return d.render ? d.render : "default"; }
  getNodeShapeId(d) { return this.svgId + "_shape_" + d.id; }
  getNodeCursor(d) { return "pointer"; }
  getNodeTitle(d) { return d.id; }
  getNodeShape(d) {
    return d.shape && (d.shape === "circle" || d.shape === "rect") ? d.shape : "circle";
  }
  getNodeShapeRadius(d) {
    // console.log("getNodeShapeRadius");
    const min = 15;
    const max = 35;
    let x = Math.abs(50000 - (d.id || 1)) / 50000;
    let r = Math.trunc(x * 50);
    if (r < min) r = min;
    if (r > max) r = max;

    d.r = r;

    return r;
  }
  getNodeShapeHeight(d) { return (2 * this.getNodeShapeRadius(d)); }
  getNodeShapeWidth(d) { return (2 * this.getNodeShapeRadius(d)); }
  getNodeShapeFill(d) { return "lightgreen"; }
  getNodeBorderStroke(d) { return "#ED6DCD"; }
  getNodeBorderStrokeWidth(d) { return "0.5px"; }

  getNodeImageGroupId(d) {
    console.log("getNodeImageGroupId")
    return this.svgId + "_imgGroup_" + d.id;
  }
  getNodeImageDefId(d) { return this.svgId + "_imgDefs_" + d.id; }
  getNodeImagePatternId(d) { return this.svgId + "_imgPattern_" + d.id; }
  getNodeImagePatternHeight(d) { return 1; }
  getNodeImagePatternWidth(d) { return 1; }
  getNodeImageId(d) { return this.svgId + "_img_" + d.id; }
  getNodeImageHref(d) {
    d.imageHref =
      "/android-chrome-512x512.png";
      // "https://www.ibgib.com/files/85C337DD86DB82A67DDA0364C0DF2561E1B3BF1ED04BBB135A3020F3EF75A0A1.jpg";
    return d.imageHref;
  }
  getNodeImageBackgroundFill(d) { return "transparent"; }
  getNodeImageMagicSize(d) { return 55 * (d.r / 25); }
  getNodeImageMagicOffset(d) { return -2.5 * (d.r / 25); }
}
