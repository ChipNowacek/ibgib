import * as d3 from 'd3';
import { d3Scales, d3Colors } from './d3params';

export class IbScape {
  // constructor(graphDiv, graphElement) {
  constructor(graphDiv) {
    this.graphDiv = graphDiv;

    this.circleRadius = 10;

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
    // t.graphElement = document.createElement('svg');
    // t.graphDiv.appendChild(t.graphElement);
    // t.graphElement.style.width = `${t.width}px`;
    // t.graphElement.style.height = `${t.height}px`;
    // t.graphElement.setAttribute('id', "ib-d3-graph-area");
    // // t.graphElement.setAttribute('width', t.width);
    // // t.graphElement.setAttribute('height', t.height);
    // t.graphElement.setAttribute("viewBox", `0 0 ${t.width} ${t.height}`);

    var svg = d3.select("#ib-d3-graph-div")
        .append("svg")
        .attr('id', "ib-d3-graph-area")
        .attr('width', t.width)
        .attr('height', t.height);

    let width = t.width;
    let height = t.height;

    var color = d3.scaleOrdinal(d3.schemeCategory20);

    var simulation = d3.forceSimulation()
        .velocityDecay(0.55)
        .force("link", d3.forceLink().id(function(d) { return d.id; }))
        .force("charge", d3.forceManyBody().distanceMin(5))
        .force("collide", d3.forceCollide(4 * t.circleRadius))
        .force("center", d3.forceCenter(width / 2, height / 2));
    t.simulation = simulation;

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
          .attr("r", getRadius)
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
      let color = d3Colors[d.cat];
      if (!color) {
        color = "green";
      }
      return color;
    }

    function getRadius(d) {
      let scale = 1;
      let multiplier = d3Scales[d.cat];
      if (multiplier || multiplier === 0) {
        scale *= multiplier
      }
      return scale * t.circleRadius;
      // switch (d.cat) {
      //   case "rel8n":
      //     scale *= 1.5;
      //     break;
      //   case "dna":
      //   scale *= 1;
      //     break;
      //   case "ancestor":
      //   scale *= 1;
      //     break;
      //   case "past":
      //   // scale *= 1;
      //     break;
      //   case "ib":
      //   scale *= 3;
      //     break;
      //   case "ibGib":
      //   scale *= 2;
      //     break;
      //   case "result":
      //   scale *= 2;
      //     break;
      //   default:
      //   // scale *= 1;
      //     break;
      // }

      return scale * t.circleRadius;
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
    d3.select("#ib-d3-graph-area").remove();

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
