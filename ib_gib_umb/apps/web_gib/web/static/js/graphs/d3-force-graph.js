import * as d3 from 'd3';

export class D3ForceGraph {
  constructor(graphDiv, svgId) {
    let t = this;

    t.graphDiv = graphDiv;
    t.svgId = svgId;

    t.initResize();
    t.graphData = { "nodes": [], "links": [] };
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
    t.graphNodeImages = null;
    t.graphImageDefs = null;

    t.drag = null;
    t.zoom = null;

    d3.select(`#${t.svgId}`).remove();
    t.svg = null;

    d3.select(t.background).remove();
    t.background = null;
  }

  initResize() {
    let t = this;

    window.onresize = () => {
      const debounceMs = 250;

      if (t.resizeTimer) { clearTimeout(t.resizeTimer); }

      t.resizeTimer = setTimeout(() => {
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
      }, debounceMs);
    };
  }

  init() {
    let t = this;

    t.rect = t.graphDiv.getBoundingClientRect();
    t.width = t.graphDiv.scrollWidth;
    t.height = t.graphDiv.scrollHeight;
    t.parentWidth = t.graphDiv.parentNode.scrollWidth;
    t.parentHeight = t.graphDiv.parentNode.scrollHeight;
    t.center = {x: t.width / 2, y: t.height / 2};

    // graph area
    let svg = d3.select(t.graphDiv)
      .append("svg")
      .attr('id', t.svgId)
      .attr('width', t.width)
      .attr('height', t.height);
    t.svg = svg;

    // Needs to be second, just after the svg itself.
    t.background = t.initBackground(t, svg);

    // Holds child components (nodes, links), i.e. all but the background
    let svgGroup = svg
        .append('svg:g')
          .attr("id", "svgGroup");
    t.svgGroup = svgGroup;

    let graphLinksGroup =
      svgGroup
        .append("g")
        .attr("id", () => t.getGraphLinksGroupId())
        .attr("class", "links");
    t.graphLinksGroup = graphLinksGroup;

    let graphNodesGroup =
      svgGroup
        .append("g")
        .attr("id", () => t.getGraphNodesGroupId())
        .attr("class", "nodes");
    t.graphNodesGroup = graphNodesGroup;

    t.zoom =
      d3.zoom()
        .on("zoom", () => t.handleZoom(svgGroup));
    t.background.call(t.zoom);

    let simulation = t.initSimulation();
    t.simulation = simulation;

    t.update();
  }

  initBackground(t, svg) {
    let result = svg
      .append("rect")
      .attr("fill", () => t.getBackgroundFill())
      .attr("class", "view")
      .attr("x", 0.5)
      .attr("y", 0.5)
      .attr("width", t.width - 1)
      .attr("height", t.height - 1)
      .on("click", () => t.handleBackgroundClicked());

    return result;
  }

  initSimulation() {
    let t = this;

    let result =
      d3.forceSimulation()
        .velocityDecay(t.getVelocityDecay())
        .force("link", t.getForceLink())
        .force("charge", t.getForceCharge())
        .force("collide", t.getForceCollide())
        .force("center", t.getForceCenter());

    return result;
  }

  update() {
    let t = this;

    let nodes = t.graphData.nodes;
    let links = t.graphData.links;

    t.drag =
      d3.drag()
        .on("start", d => t.handleDragStarted(d, t.simulation))
        .on("drag", d => t.handleDragged(d))
        .on("end", d => t.handleDragEnded(d, t.simulation));

    // nodes
    t.graphNodesData =
      t.graphNodesGroup
        .selectAll("g")
        .data(nodes, d => t.nodeKeyFunction(d));
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

    t.graphNodeShapes = t.initGraphNodeShapes();

    t.graphNodeLabels =
      t.graphNodesEnter
        .append("text")
        .attr("id", d => "label_" + d.id)
        .attr("font-size", `10px`)
        .attr("text-anchor", "middle")
        .text(d => `${d.id}`);

    t.graphImageDefs =
      t.graphNodesEnter
        .append("defs")
        .attr("id", d => t.getImageDefId(d));


    // links
    t.graphLinksData =
      t.graphLinksGroup
        .selectAll("line")
        .data(links);
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


    // Attach the nodes and links to the simulation.
    t.simulation
      .nodes(nodes)
      .on("tick", () => t.handleTicked())
      .on("end", () => t.handleEnd());
    t.simulation
      .force("link")
      .links(links);
  }


  initGraphNodeShapes() {
    let t = this;

    let graphNodeCircles =
      t.graphNodesEnter
        .filter(d => t.getNodeShape(d) === "circle")
        .append("circle")
        .attr("r", d => t.getNodeShapeRadius(d))
        .attr("fill", d => t.getNodeShapeFill(d));

    let graphNodeRects =
      t.graphNodesEnter
        .filter(d => t.getNodeShape(d) === "rect")
        .append("rect")
        .attr("width", d => t.getNodeShapeWidth(d))
        .attr("height", d => t.getNodeShapeHeight(d))
        .attr("x", d => Math.trunc(-1/2 * t.getNodeShapeWidth(d)))
        .attr("y", d => Math.trunc(-1/2 * t.getNodeShapeHeight(d)))
        .attr("fill", d => t.getNodeShapeFill(d));

    return graphNodeCircles.merge(graphNodeRects);
  }

  handleDragStarted(d, simulation) {
    if (!d3.event.active) simulation.alphaTarget(0.3).restart();

    d.fx = d.x;
    d.fy = d.y;

    // t.x0 = d3.event.x;
    // t.y0 = d3.event.y;
    console.log(`drag started d.fx: ${d.fx}`)
  }
  handleDragged(d) {
    // console.log(`dragged d.fx: ${d.fx}`)

    d.fx = d3.event.x;
    d.fy = d3.event.y;
  }
  handleDragEnded(d, simulation) {
    console.log("handleDragEnded")
    if (!d3.event.active) simulation.alphaTarget(0);

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

  add(nodesToAdd, linksToAdd) {
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
  }

  remove(dToRemove) {
    console.log(`dToRemove: ${JSON.stringify(dToRemove)}`)

    let t = this;
    let currentNodes = t.graphData.nodes;
    let currentLinks = t.graphData.links;
    let nIndex = currentNodes.indexOf(dToRemove);
    if (nIndex > -1) {
      currentNodes.splice(nIndex, 1);
    }

    let toRemoveLinks = currentLinks.filter(l => {
      return l.source.id === dToRemove.id || l.target.id === dToRemove.id;
    });
    toRemoveLinks.forEach(l => {
      let lIndex = currentLinks.indexOf(l);
      currentLinks.splice(lIndex, 1);
    })

    t.update();
    t.simulation.restart();
    t.simulation.alpha(1);
  }

  handleNodeClicked(d) {
    console.log(`node clicked: ${JSON.stringify(d)}`);

    let t = this;
    let newId = Math.trunc(Math.random() * 100000);
    let newNode = {"id": newId, "name": "server 22", x: d.x, y: d.y};
    newNode.shape = Math.random() > 0.5 ? "circle" : "rect";
    let newNodes = [newNode];
    let newLinks = [{source: d.id, target: newNode.id}]

    t.add(newNodes, newLinks);
  }

  handleNodeContextMenu(d) {
    let t = this;
    t.remove(d);
    d3.event.preventDefault();
  }

  handleNodeMouseover(d) {
    console.log(`d.id: ${d.id}`);
  }

  handleEnd() {
    console.log("end yo");
  }

  // getForceVelocityDecay(d) { return 0.25; }
  // getForceLinkDistance(d) { return 55; }
  // getForceStrength(d) { return 0.8; }
  // getForceChargeStrength(d) { return -25; }

  // Svg Framing (svg, svgGroup, links group, nodes group, background)
  getGraphLinksGroupId() { return `links_${this.svgId}`; }
  getGraphNodesGroupId() { return `nodes_${this.svgId}`; }
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
  getImageDefId(d) { return "imgDefs_" + d.id; }
  getNodeCursor(d) { return "pointer"; }
  getNodeShape(d) {
    return d.shape && (d.shape === "circle" || d.shape === "rect") ? d.shape : "circle";
  }
  getNodeShapeRadius(d) {
    // console.log("getNodeShapeRadius");
    const min = 2;
    const max = 25;
    let x = Math.abs(50000 - (d.id || 1)) / 50000;
    let r = Math.trunc(x * 100);
    if (r < min) r = min;
    if (r > max) r = max;

    return r;
  }
  getNodeShapeHeight(d) { return (2 * this.getNodeShapeRadius(d)); }
  getNodeShapeWidth(d) { return (2 * this.getNodeShapeRadius(d)); }
  getNodeShapeFill(d) { return "lightgreen"; }
}
