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

    t.graphData = { "nodes": [], "links": [] };

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

    function handleBackgroundClicked(d) {
      console.log("background clicked");
    }


    // Holds child components (nodes, links), i.e. all but the background
    let svgGroup = svg
        .append('svg:g')
          .attr("id", "svgGroup");

    let graphLinksGroup =
      svgGroup
        .append("g")
        .attr("id", `links_${t.svgId}`)
        .attr("class", "links");

    let graphNodesGroup =
      svgGroup
        .append("g")
        .attr("id", `nodes_${t.svgId}`)
        .attr("class", "nodes");

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

    let simulation =
      d3.forceSimulation()
        .velocityDecay(0.55)
        // .alphaTarget(0.01)
        // .alphaDecay(0.1)
        .force("link", d3.forceLink()
                         .distance(100)
                         .id(function(d) { return d.id; }))
        .force("charge", d3.forceManyBody().strength(-100).distanceMin(10000))
        .force("collide", d3.forceCollide(25))
        .force("center", d3.forceCenter(t.center.x, t.center.y));

    update();


    function update() {
      let nodes = t.graphData.nodes;
      let links = t.graphData.links;

      // t.initDrag();
      let drag =
        d3.drag()
          .on("start", handleDragStarted)
          .on("drag", handleDragged)
          .on("end", handleDragEnded);

      // nodes
      let graphNodesData =
        graphNodesGroup
          .selectAll("g")
          .data(nodes, d => d.id);
      let graphNodesEnter =
        graphNodesData
          .enter()
            .append("g")
            .attr("id", d => d.id || null)
            .on("contextmenu", (d, i)  => {
               remove(d);
               d3.event.preventDefault();
            })
            .on("mouseover", d => console.log(`d.id: ${d.id}`))
            .on("click", handleNodeClicked)
            .call(drag);
      let graphNodesExit =
        graphNodesData
          .exit()
          .call((s) => console.log(`selection exiting. s: ${JSON.stringify(s)}`))
          .remove();

      let graphNodeCircles =
        graphNodesEnter
          .append("circle")
          .classed('node', true)
          .attr("cursor", "pointer")
          .attr("r", getRadius)
          .attr("fill", getColor)
          .attr("stroke", getBorderStroke)
          .attr("stroke-width", getBorderStrokeWidth)
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

      // links
      let graphLinksData =
        graphLinksGroup
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

      simulation
        .nodes(nodes)
        .on("tick", handleTicked)
        .on("end", handleEnd);

      simulation
        .force("link")
        .links(links);

      function handleTicked() {
        // let t = this;
        // console.log('ticked')

        graphLinksData
          .attr("x1", d => d.source.x)
          .attr("y1", d => d.source.y)
          .attr("x2", d => d.target.x)
          .attr("y2", d => d.target.y);

        // Translate the groups
        graphNodesData
            .attr("transform", d => {
              // console.log(`d.x: ${d.x}`)
              return 'translate(' + [d.x, d.y] + ')';
            });
      }



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

        d.fx = undefined;
        d.fy = undefined;
      }

    }

    function getForceVelocityDecay(d) { return 0.25; }
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

      let newId = Math.trunc(Math.random() * 1000);
      let newNode = {"id": newId, "name": "server 22", x: d.x, y: d.y};
      let newNodes = [newNode];
      let newLinks = [{source: d.id, target: newNode.id}]

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
      simulation.restart();
      simulation.alpha(1);
    }

    t.add = (a, b) => add(a, b);

    function remove(dToRemove) {
      console.log(`dToRemove: ${JSON.stringify(dToRemove)}`)
      // debugger;
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

      update();
      simulation.restart();
      simulation.alpha(1);
    }
  }
}
