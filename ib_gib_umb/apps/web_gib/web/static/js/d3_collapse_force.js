import * as d3 from "d3";

export class IbScape {
  constructor(graphDiv, graphCanvas) {
    this.graphDiv = graphDiv;
    this.graphCanvas = graphCanvas;

    this.circleRadius = 20;

    window.onresize = () => {
      const debounceMs = 250;

      if (this.resizeTimer) { clearTimeout(this.resizeTimer); }

      this.resizeTimer = setTimeout(() => {

        console.log("resized yo");
        this.destroyStuff();
        this.init(this.data);

      }, debounceMs);
    };
  }

  init(data) {
    let t = this;
    t.data = data;
    t.width = t.graphDiv.scrollWidth;
    t.height = t.graphDiv.scrollHeight;
    // t.center = {x: t.width / 2, y: t.height / 2}

    if (t.graphCanvas.getAttribute('width')) {
      t.graphCanvas.setAttribute('width', t.width);
      t.graphCanvas.setAttribute('height', t.height);
    } else if (t.graphCanvas.viewBox) {
      t.graphCanvas.setAttribute("viewBox", `0 0 ${t.width} ${t.height}`);
    }

    // var svg = d3.select("svg"),
    // let svg = t.graphCanvas;
    var svg = d3.select("#ib-d3-graph-canvas");
    let width = t.width; //svg.attr("width");
    let height = t.height; //svg.attr("height");

    var color = d3.scaleOrdinal(d3.schemeCategory20);

    var simulation = d3.forceSimulation()
        .velocityDecay(0.55)
        .force("link", d3.forceLink().id(function(d) { return d.id; }))
        .force("charge", d3.forceManyBody().distanceMin(5))
        .force("collide", d3.forceCollide(2 * t.circleRadius))
        .force("center", d3.forceCenter(width / 2, height / 2));
    this.simulation = simulation;

    d3.json(data, function(error, graph) {
      if (error) throw error;

      var link = svg.append("g")
          .attr("class", "links")
        .selectAll("line")
        .data(graph.links)
        .enter().append("line")
          .attr("stroke-width", function(d) { return Math.sqrt(d.value); });

      var node = svg.append("g")
          .attr("class", "nodes")
        .selectAll("circle")
        .data(graph.nodes)
        .enter().append("circle")
          .attr("r", t.circleRadius)
          // .attr("fill", function(d) { return color(d.group); })
          .attr("fill", getColor)
          .on("click", clicked)
          .call(d3.drag()
              .on("start", dragstarted)
              .on("drag", dragged)
              .on("end", dragended));

      node.append("title")
          .text(function(d) { return d.id; });

      simulation
          .nodes(graph.nodes)
          .on("tick", ticked);

      simulation
          .force("link")
          .links(graph.links);

      function ticked() {
        link
            .attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });

        node
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });
      }
    });

    function getColor(d) {
      console.log(`getColor: ${JSON.stringify(d)}`);
      console.log(`cat: ${d.cat}`)
      if (d.cat === "rel8n") {
        return color(3);
      } else if (d.cat === "ib") {
        return color(4);
      } else if (d.cat === "ibGib") {
        console.warn("whaaa")
        return color(9);
      } else {
        return color(2);
      }
    }

    function clicked(d) {
      console.log(`clicked: ${JSON.stringify(d)}`);
    }

    function dragstarted(d) {
      if (!d3.event.active) simulation.alphaTarget(0.3).restart();
      d.fx = d.x;
      d.fy = d.y;
    }

    function dragged(d) {
      d.fx = d3.event.x;
      d.fy = d3.event.y;
    }

    function dragended(d) {
      if (!d3.event.active) simulation.alphaTarget(0);
      d.fx = null;
      d.fy = null;
    }
  }

  destroyStuff() {
    delete(this.simulation);
    delete(this.context);
    delete(this.height);
    delete(this.width);
  }


  // {
  //   "rel8ns": {
  //     "result":["ib^gib"],
  //     "query":["query^EBF6C1403C60DCE7B0DD59719A742BE81C55101CA27EDCEABB03AEB126B92EBE"],
  //     "dna":["ib^gib","query^EBF6C1403C60DCE7B0DD59719A742BE81C55101CA27EDCEABB03AEB126B92EBE"],
  //     "ancestor":["query_result^gib"]
  //   },
  //
  //   "ib":"query_result",
  //   "gib":"642E17932EBD7BB5135B0550E1260DF1D3EC9A821E675EA416F75BD5F38D0F82",
  //   "data":{"result_count":"1"}
  // }

}
