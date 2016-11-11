import * as d3 from 'd3';

export class D3ForceGraph {
  constructor(graphDiv, svgId) {
    let t = this;

    t.graphDiv = graphDiv;
    t.svgId = svgId;

    t.initResize();
    t.graphData = { "nodes": [], "links": [] };
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
    let background = t.initBackground(t, svg);
    t.background = background;
    // background

    // Holds child components (nodes, links), i.e. all but the background
    let svgGroup = svg
        .append('svg:g')
          .attr("id", "svgGroup");
    t.svgGroup = svgGroup;

    let graphLinksGroup =
      svgGroup
        .append("g")
        .attr("id", `links_${t.svgId}`)
        .attr("class", "links");
    t.graphLinksGroup = graphLinksGroup;

    let graphNodesGroup =
      svgGroup
        .append("g")
        .attr("id", `nodes_${t.svgId}`)
        .attr("class", "nodes");
    t.graphNodesGroup = graphNodesGroup;

    t.zoom =
      d3.zoom()
        .on("zoom", () => t.handleZoom(svgGroup));
    background.call(t.zoom);

    let simulation = t.initSimulation();
    t.simulation = simulation;

    t.update();
  }

  initBackground(t, svg) {
    let result = svg
      .append("rect")
      .attr("fill", "#F2F7F0")
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

    let result = d3.forceSimulation()
      .velocityDecay(0.55)
      // .alphaDecay(0.1)
      .force("link", d3.forceLink()
                       .distance(100)
                       .id(d => d.id))
      .force("charge", d3.forceManyBody().strength(-100).distanceMin(10000))
      .force("collide", d3.forceCollide(25))
      .force("center", d3.forceCenter(t.center.x, t.center.y));

    return result;
  }

  getRadius(d) {
    const min = 5;
    const max = 50;
    let x = Math.abs(50000 - (d.id || 1)) / 50000;
    let r = Math.trunc(x * 100);
    if (r < min) r = min;
    if (r > max) r = max;

    return r;
  }
  getColor(d) { return "lightgreen"; }

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

  update() {
    let t = this;

    let nodes = t.graphData.nodes;
    let links = t.graphData.links;

    // t.initDrag();
    let drag =
      d3.drag()
        .on("start", d => t.handleDragStarted(d, t.simulation))
        .on("drag", d => t.handleDragged(d))
        .on("end", d => t.handleDragEnded(d, t.simulation));

    // nodes
    let graphNodesData =
      t.graphNodesGroup
        .selectAll("g")
        .data(nodes, d => d.id);
    let graphNodesEnter =
      graphNodesData
        .enter()
          .append("g")
          .attr("id", d => d.id || null)
          .on("contextmenu", (d, i)  => {
             t.remove(d);
             d3.event.preventDefault();
          })
          .on("mouseover", d => console.log(`d.id: ${d.id}`))
          .on("click", d => t.handleNodeClicked(d))
          .call(drag);
    let graphNodesExit =
      graphNodesData
        .exit()
        // .call((s) => console.log(`selection exiting. s: ${JSON.stringify(s)}`))
        .remove();

    let graphNodeCircles =
      graphNodesEnter
        .append("circle")
        .classed('node', true)
        .attr("cursor", "pointer")
        .attr("r", d => t.getRadius(d))
        .attr("fill", d => t.getColor(d))
        .call((d) => {
          // console.log(`graphNodesEnter.append. d: ${JSON.stringify(d)}`);
        });

    let graphNodeLabels =
      graphNodesEnter
        .append("text")
        .attr("id", d => "label_" + d.id)
        .attr("font-size", `10px`)
        .attr("text-anchor", "middle")
        .text(d => `${d.id}`);

    // merge
    graphNodesData =
      graphNodesEnter.merge(graphNodesData);
    t.graphNodesData = graphNodesData;

    // links
    let graphLinksData =
      t.graphLinksGroup
        .selectAll("line")
        .data(links);
    let graphLinksEnter =
       graphLinksData
        .enter()
          .append("line");
    let graphLinksExit =
      graphLinksData
        .exit()
        .remove();
    // merge
    graphLinksData =
      graphLinksEnter.merge(graphLinksData);
    t.graphLinksData = graphLinksData;

    t.simulation
      .nodes(nodes)
      .on("tick", () => t.handleTicked())
      .on("end", () => t.handleEnd());

    t.simulation
      .force("link")
      .links(links);
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
    let newNodes = [newNode];
    let newLinks = [{source: d.id, target: newNode.id}]

    t.add(newNodes, newLinks);
  }

  handleEnd() {
    console.log("end yo");
  }

  // getForceVelocityDecay(d) { return 0.25; }
  // getForceLinkDistance(d) { return 55; }
  // getForceStrength(d) { return 0.8; }
  // getForceChargeStrength(d) { return -25; }

  destroy() {
    let t = this;

    t.simulation.stop();
    t.simulation = null;
    t.graphNodesGroup = null;
    t.graphLinksGroup = null;
    t.graphLinksData = null;
    t.graphNodesData = null;
    t.zoom = null;

    d3.select(`#${t.svgId}`).remove();
    t.svg = null;

    d3.select(t.background).remove();
    t.background = null;
    // t.graphData = null;
  }
}
