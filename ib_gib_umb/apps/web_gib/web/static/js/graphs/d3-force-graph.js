import * as d3 from 'd3';

export class D3ForceGraph {
  constructor(graphDiv, svgId) {
    let t = this;

    t.graphDiv = graphDiv;
    t.rect = t.graphDiv.getBoundingClientRect();
    t.width = t.graphDiv.scrollWidth;
    t.height = t.graphDiv.scrollHeight;
    t.center = {x: t.width / 2, y: t.height / 2};

    t.svgId = svgId;
    t.updateRefCount = 0;
  }

  init() {
    let t = this;

    let nodes = [
      {"id": 1, "name": "server 1"},
      {"id": 2, "name": "server 2"},
      {"id": 3, "name": "server 3"},
      {"id": 4, "name": "server 4"},
      {"id": 5, "name": "server 5"},
      {"id": 6, "name": "server 6"},
      {"id": 7, "name": "server 7"},
      {"id": 8, "name": "server 8"},
      {"id": 9, "name": "server 9"}
    ]

    let links = [
      {source: 1, target: 2},
      {source: 1, target: 3},
      {source: 1, target: 4},
      {source: 2, target: 5},
      {source: 2, target: 6},
      {source: 3, target: 7},
      {source: 5, target: 8},
      {source: 6, target: 9},
    ]

    t.graphData = { "nodes": nodes, "links": links };

    // t.scaffoldGraph()
    // graph area
    let svg = d3.select(t.graphDiv)
      .append("svg")
      .attr('id', t.svgId)
      .attr('width', t.width)
      .attr('height', t.height);

    // background
    let background = svg
      .append("rect")
      .attr("fill", "#F2F7F0")
      .attr("class", "view")
      .attr("x", 0.5)
      .attr("y", 0.5)
      .attr("width", t.width - 1)
      .attr("height", t.height - 1)
      .on("click", handleBackgroundClicked);

    // Holds child components (nodes, links), i.e. all but the background
    let svgGroup = svg
        .append('svg:g')
          .attr("id", "svgGroup");

    function handleBackgroundClicked(d) {
      console.log("background clicked");
    }


    // t.initZoom();
    let zoom =
      d3.zoom()
        .on("zoom", handleZoom);
    background.call(zoom);

    function handleZoom() {
      svgGroup
        .attr("transform",
        `translate(${d3.event.transform.x}, ${d3.event.transform.y})` + " " +
        `scale(${d3.event.transform.k})`);
    }



    // t.initForceSimulation();

    let simulation =
      d3.forceSimulation()
        .velocityDecay(0.55)
        .force("link", d3.forceLink().id(function(d) { return d.id; }))
        .force("charge", d3.forceManyBody().strength(-25))
        .force("collide", d3.forceCollide(25))
        .force("center", d3.forceCenter(t.center.x, t.center.y));

    // t.initDrag();
    let drag =
      d3.drag()
        .on("start", handleDragStarted)
        .on("drag", handleDragged)
        .on("end", handleDragEnded);

    function handleDragStarted(d) {
      if (!d3.event.active) simulation.alphaTarget(0.3).restart();

      d.fx = d.x;
      d.fy = d.y;

      // t.x0 = d3.event.x;
      // t.y0 = d3.event.y;
      console.log(`drag started d.fx: ${d.fx}`)
    }
    function handleDragged(d) {
      // console.log(`dragged d.fx: ${d.fx}`)

      d.fx = d3.event.x;
      d.fy = d3.event.y;
    }
    function handleDragEnded(d) {
      console.log("handleDragEnded")
      if (!d3.event.active) simulation.alphaTarget(0);

      d.fx = d3.event.x;
      d.fy = d3.event.y;

      d.fx = null;
      d.fy = null;
    }

    // t.update();
    update();

    function update() {
      let nodes = t.graphData.nodes;
      let links = t.graphData.links;

      let graphLinksData =
        svgGroup
          .append("g")
          .attr("class", "links")
          .selectAll("line")
          .data(links);
      let graphLinksEnter =
         graphLinksData
          .enter()
            .append("line")
            .attr("stroke-width", "2px");//t.getLinkWidth); // necessary?
      let graphLinksExit =
        graphLinksData
          .exit()
          .remove();
      graphLinksData =
        graphLinksExit.merge(graphLinksData);

      let graphNodesGroupData =
        svgGroup
          .selectAll("g.gnode")
          .data(nodes);
      let graphNodesGroupEnter =
        graphNodesGroupData
          .enter()
            .append("g")
            .on("click", e => { console.log("graphNodesGroup clicked") })
            .call(drag);
      // t.graphNodesGroupExit =
      //   t.graphNodesGroupData
      //     .exit()
      //     .remove();
      // t.graphNodesGroupData =
      //   t.graphNodesGroupExit.merge(t.graphNodesGroupData);

      // graphNodes is g, includes circles, imageDefs, labels, images
      let graphNodes =
        graphNodesGroupEnter
          .append("g")
          .classed('gnode', true)
          .on("click", handleNodeClicked)
          // .on("mousedown", handleNodeMouseDown)
          // .on("touchstart", handleNodeTouchStart)
          // .on("touchend", handleNodeTouchEnd)
          .attr("cursor", "pointer")
          .on("contextmenu", (d, i)  => { d3.event.preventDefault(); });

      let graphNodeCircles =
        graphNodes
          .append("circle")
          .attr("class", "nodes")
          .attr("id", d => d.id || null)
          .attr("cursor", "pointer")
          .attr("r", getRadius)
          .attr("fill", getColor)
          .attr("stroke", getBorderStroke)
          .attr("stroke-width", getBorderStrokeWidth);

      // merge
      graphLinksData =
        graphLinksEnter.merge(graphLinksData);
      graphNodesGroupData =
        graphNodesGroupEnter.merge(graphNodesGroupData);

      simulation
        .nodes(t.graphData.nodes)
        .on("tick", handleTicked)
        .on("end", handleEnd);

      simulation
        .force("link")
        .links(t.graphData.links);

      function handleTicked() {
        // let t = this;
        // console.log('ticked')

        graphLinksData
          .attr("x1", d => d.source.x)
          .attr("y1", d => d.source.y)
          .attr("x2", d => d.target.x)
          .attr("y2", d => d.target.y);

        // Translate the groups
        graphNodesGroupData
            .attr("transform", d => {
              // console.log(`d.x: ${d.x}`)
              return 'translate(' + [d.x, d.y] + ')';
            });
      }
    }

    function getForceVelocityDecay(d) { return 0.55; }
    function getForceLinkDistance(d) { return 55; }
    function getForceStrength(d) { return 0.8; }
    function getForceChargeStrength(d) { return -25; }

    function getRadius(d) { return 15; }
    function getColor(d) { return "green"; }
    function getBorderStroke(d) { return "pink"; }
    function getBorderStrokeWidth(d) { return "0.5px"; }
    function getLinkWidth(d) { return 1; }

    function handleNodeClicked(d) {
      console.log(`node clicked: ${JSON.stringify(d)}`);
      // d.fx = 0;
      // d.fy = 0;

      let newId = Math.trunc(Math.random() * 1000);
      let newNode = {"id": newId, "name": "server 22"};
      let newNodes = [newNode];
      let newLinks = [{source: d, target: newNode}]

      add(newNodes, newLinks);
    }

    function handleEnd() {
      console.log("end yo");
    }

    function add(nodesToAdd, linksToAdd) {
      if (nodesToAdd) {
        nodesToAdd.forEach(n => t.graphData.nodes.push(n));
      }
      if (linksToAdd) {
        linksToAdd.forEach(l => t.graphData.links.push(l));
      }

      update();
    }
  }
}
