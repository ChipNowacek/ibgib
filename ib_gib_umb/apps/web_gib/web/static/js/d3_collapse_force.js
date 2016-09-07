import * as d3 from 'd3';
import { d3CircleRadius, d3Scales, d3Colors } from './d3params';

export class IbScape {
  constructor(graphDiv) {
    this.graphDiv = graphDiv;

    this.circleRadius = 10;

    window.onresize = () => {
      const debounceMs = 250;

      if (this.resizeTimer) { clearTimeout(this.resizeTimer); }

      this.resizeTimer = setTimeout(() => {
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
    t.center = {x: t.width / 2, y: t.height / 2};

    // graph area
    let svg = d3.select("#ib-d3-graph-div")
        .append("svg")
        .attr('id', "ib-d3-graph-area")
        .attr('width', t.width)
        .attr('height', t.height);
    t.svg = svg;

    // background
    let view = svg.append("rect")
        .attr("fill", "#E4F7DC")
        .attr("class", "view")
        .attr("x", 0.5)
        .attr("y", 0.5)
        .attr("width", t.width - 1)
        .attr("height", t.height - 1)
        .on("click", backgroundClicked);
    t.view = view;

    // Holds child components (nodes, links)
    // Need this for zooming.
    let vis = svg
        .append('svg:g');
    t.vis = vis;

    let zoom = d3.zoom().on("zoom", () => {
      vis.attr("transform",
        `translate(${d3.event.transform.x}, ${d3.event.transform.y})` + " " +
        `scale(${d3.event.transform.k})`);
    });
    view.call(zoom);

    let simulation = d3.forceSimulation()
        .velocityDecay(0.55)
        .force("link", d3.forceLink().id(function(d) { return d.id; }))
        .force("charge", d3.forceManyBody().distanceMin(25))
        .force("collide", d3.forceCollide(3.5 * d3CircleRadius))
        .force("center", d3.forceCenter(t.width / 2, t.height / 2));
    t.simulation = simulation;

    // Initialize the d3 chart with our data given.
    d3.json(data, function(error, graph) {
      if (error) throw error;

      let link = vis.append("g")
          .attr("class", "links")
        .selectAll("line")
        .data(graph.links)
        .enter().append("line")
          .attr("stroke-width", function(d) { return Math.sqrt(d.value); });

      let node = vis.append("g")
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

    this.initMenu();

    /** Gets the radius of the circle, depending on the data category. */
    function getRadius(d) {
      let scale = 1;
      let multiplier = d3Scales[d.cat];
      if (multiplier || multiplier === 0) {
        scale *= multiplier
      }
      return scale * d3CircleRadius;
    }

    /**
     * Gets the color of the circle, depending mostly on the category with
     * some special exceptions (ibGib, ib).
     */
    function getColor(d) {
      let index = d.cat;
      if (d.ibgib === "ib^gib") {
        index = "ibGib";
      } else if (d.cat === "rel8n") {
        index = d.id;
      }
      return d3Colors[index] || d3Colors["default"];
    }

    function backgroundClicked(d) {
      console.log("background clicked");

      d3.select("#ib-d3-graph-menu-div")
        .style("left", t.center.x + "px")
        .style("top", t.center.y + "px")
        .style("visibility", "hidden")
        .attr("z-index", -1);

      d3.event.preventDefault();
    }

    function clicked(d) {
      console.log(`clicked: ${JSON.stringify(d)}`);
      // I apologize for poor naming.
      // let divIbGibData = document.querySelector("#ibgib-data");
      // let openPath = divIbGibData.getAttribute("data-open-path");
      // if (d.cat !== "rel8n" && d.ibgib !== "ib^gib" && d.cat !== "ib") {
      //   console.log(`clicked ibgib: ${d.ibgib}`)
      //   location.href = openPath + d.ibgib;
      // }


      let transition =
        d3.transition()
          .duration(150)
          .ease(d3.easeLinear);

      // let position = d3.mouse(this);
      let position = d3.mouse(view.node());
      d3.select("#ib-d3-graph-menu-div")
        .transition(transition)
          .style("left", position[0] + "px")
          .style("top", position[1] + "px")
          .style("visibility", null)
          .attr("z-index", 1000);

      d3.event.preventDefault();
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
    d3.select("#ib-d3-graph-menu-div").remove();

    delete(this.svg);
    delete(this.view);
    delete(this.vis);
    delete(this.simulation);
    delete(this.height);
    delete(this.width);
  }

  initMenu() {
    this.menu =
      d3.select("#ib-d3-graph-div")
        .append('div')
        		.attr("id", "ib-d3-graph-menu-div")
        		.style('position','absolute')
            .style("top", 200 + "px")
            .style("left", 200 + "px")
            // .style("display", "block")
            .style("visibility", "hidden")
            // .style("class", "ib-hidden")
            .attr("z-index", 100)
        		.style('width', 150 + "px")
        		.style('height', 150 + "px")
        		.style('background-color', "pink")
        		// add mouseover effect to change background color to black
        		.on('mouseover', function() {
        			d3.select("#ib-d3-graph-menu-div")
        			.style('background-color','black')
        		})
        		.on('mouseout', function () {
        			d3.select("#ib-d3-graph-menu-div")
        			.style('background-color', "pink")
        		})

    //   // graph area
    // var svg = d3.select("#ib-d3-graph-menu-div")
    //     .append("svg")
    //     .attr('id', "ib-d3-graph-menu-area")
    //     .attr('width', t.width)
    //     .attr('height', t.height);
  }

}
