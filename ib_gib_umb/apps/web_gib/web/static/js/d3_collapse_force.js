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
        .attr("fill", "#E7F0E4")
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
        .append('svg:g')
          .attr("id", "d3vis");
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
          .attr("id", d => d.js_id || null)
          .attr("cursor", "pointer")
          .attr("r", getRadius)
          .attr("fill", getColor)
          .on("click", nodeClicked)
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

      t.clearSelectedNode();

      d3.select("#ib-d3-graph-menu-div")
        .style("left", t.center.x + "px")
        .style("top", t.center.y + "px")
        .style("visibility", "hidden")
        .attr("z-index", -1);

      d3.event.preventDefault();
    }

    function nodeClicked(d) {
      console.log(`nodeClicked: ${JSON.stringify(d)}`);
      // I apologize for poor naming.
      // let divIbGibData = document.querySelector("#ibgib-data");
      // let openPath = divIbGibData.getAttribute("data-open-path");
      // if (d.cat !== "rel8n" && d.ibgib !== "ib^gib" && d.cat !== "ib") {
      //   console.log(`clicked ibgib: ${d.ibgib}`)
      //   location.href = openPath + d.ibgib;
      // }

      if (t.selectedDatum && t.selectedDatum.js_id == d.js_id) {
        t.clearSelectedNode();
      } else {
        t.clearSelectedNode();
        t.selectNode(d);
      }

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

  clearSelectedNode() {
    d3.select("#d3vis")
      .selectAll("circle")
        .style("opacity", 1);

    if (this.selectedNode) {
      this.tearDownMenu();
      delete this.selectedNode;
      delete this.selectedDatum;
    }
  }

  selectNode(d) {
    d3.select("#d3vis")
      .selectAll("circle")
        .style("opacity", 0.3);

    this.buildMenu();

    this.selectedDatum = d;
    this.selectedNode = d3.select("#" + d.js_id);
    let top =
      d3.select("#" + d.js_id)
          .style("opacity", 1)
          .attr("stroke", "yellow")
          .attr("stroke-width", "10px")
          ;

    let transition =
      d3.transition()
        .duration(150)
        .ease(d3.easeLinear);

    let mousePosition = d3.mouse(this.view.node());
    let targetNode = d3.event.target;
    let position = this.getMenuPosition(mousePosition, targetNode);
    d3.select("#ib-d3-graph-menu-div")
      .transition(transition)
        .style("left", position.x + "px")
        .style("top", position.y + "px")
        .style("visibility", null)
        .attr("z-index", 1000);
  }

  buildMenu() {
    let t = this;
    t.menuButtonRadius = 22;

    t.menuDiv = d3.select("#ib-d3-graph-menu-div");

    t.menuArea =
      t.menuDiv
        .append("svg")
          .attr("id", "ib-d3-graph-menu-area")
          .style("width", this.menuDiam)
          .style("height", this.menuDiam);

    t.menuView =
      t.menuArea.append("circle")
        .attr("width", this.menuDiam)
        .attr("height", this.menuDiam)
        .style("fill", "blue");
        // .style("background-color", "transparent");

    t.menuVis = t.menuArea
      .append("svg:g")
        .attr("id", "d3menuvis");

    t.menuSimulation = d3.forceSimulation()
        .velocityDecay(0.07)
        .force("x", d3.forceX().strength(0.02))
        .force("y", d3.forceY().strength(0.02))
        .force("center", d3.forceCenter(t.menuRadius, t.menuRadius))
        .force("collide",
               d3.forceCollide().radius(t.menuButtonRadius).iterations(2));

    // If i put the json file in another folder, it won't get loaded.
    // Maybe something to do with brunch, I don't know.
    d3.json("../images/d3Menu.json", function(error, graph) {

      let nodeGroup =
        t.menuVis.append("g")
          .attr("class", "nodes")
          .selectAll("circle")
          .data(graph.nodes)
          .enter();

      let nodeCircles =
        nodeGroup
          .append("circle")
          .attr("id", d => d.id)
          .attr("r", t.menuButtonRadius)
          .attr("cursor", "pointer")
          .on("click", menuNodeClicked)
          .attr("fill", d => d.color);

      nodeCircles
          .append("title")
          .text(d => d.text);

      let nodeTextsGroup =
        t.menuVis.append("g")
          .attr("class", "nodeTexts")
          .selectAll("text")
          .data(graph.nodes)
          .enter();

      let nodeTexts =
        nodeTextsGroup
          .append("text")
          .attr("font-size", "20px")
          .attr("fill", "darkgreen")
          .attr("text-anchor", "middle")
          .attr("cursor", "pointer")
          .attr("class", "ib-noselect")
          .on("click", menuNodeClicked)
          .text(d => d.text)
          .attr('dominant-baseline', 'central')
          .attr('font-family', 'FontAwesome')
          .text(d => d.icon);

      nodeTexts
          .append("title")
          .text(d => d.text);

      let nodes = graph.nodes;

      t.menuSimulation
          .nodes(graph.nodes)
          .on("tick", tickedMenu);

      function tickedMenu() {
        nodeCircles
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });

        let posTweak = 5;
        nodeTexts
          .attr("x", d => d.x)
          .attr("y", d => d.y);
      }

      function menuNodeClicked(d) {
        console.log(`menu node clicked. d: ${JSON.stringify(d)}`);

        let transition =
          d3.transition()
            .duration(150)
            .ease(d3.easeLinear);

        d3.select(`#${d.id}`)
          .transition(transition)
            .attr("r", 1.2 * t.menuButtonRadius)
          .transition()
            .attr("r", t.menuButtonRadius);
      }
    });

  }

  tearDownMenu() {
    if (this.menuArea) { d3.select("#ib-d3-graph-menu-area").remove();
      delete this.menuArea;
    }

    d3.select("#ib-d3-graph-menu-div")
      .style("visibility", "hidden");
  }

  getMenuPosition(mousePosition, targetNode) {
    // Start our position away from right where we click.

    // let bufferAwayFromClickPoint = this.menuRadius;
    let bufferAwayFromClickPoint = 30; //magic number :-/
    let $graphDivPos = $(`#${this.graphDiv.id}`).position();

    let mousePosIsOnLeftSide = mousePosition[0] < this.width/2;
    let x = mousePosIsOnLeftSide ?
            $graphDivPos.left + mousePosition[0] + bufferAwayFromClickPoint :
            $graphDivPos.left + mousePosition[0] - this.menuDiam;
    if (x < $graphDivPos.left) { x = $graphDivPos.left; }
    if (x > $graphDivPos.left + this.width - this.menuDiam) {
      x = $graphDivPos.left + this.width - this.menuDiam;
    }

    let mousePosIsInTopHalf = mousePosition[1] < (this.height/2);
    let y = mousePosIsInTopHalf ?
            $graphDivPos.top + mousePosition[1] + bufferAwayFromClickPoint :
            $graphDivPos.top + mousePosition[1] - this.menuDiam;
    if (y < $graphDivPos.top) { y = $graphDivPos.top; }
    if (y > $graphDivPos.top + this.height - this.menuDiam) {
      y = $graphDivPos.top + this.height - this.menuDiam;
    }

    return {
      x: x,
      y: y
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
    let t = this;
    this.menuRadius = 120;
    this.menuDiam = 2 * this.menuRadius;
    this.menuDivSize = this.menuDiam;
    this.menuBackgroundColor = "#2B572E";
    this.menuOpacity = 0.7;

    d3.select("#ib-d3-graph-div")
      .append('div')
        .attr("id", "ib-d3-graph-menu-div")
        .style('position','absolute')
        .style("top", 200 + "px")
        .style("left", 200 + "px")
        .style("visibility", "hidden")
        .style("opacity", this.menuOpacity)
        .attr("z-index", 100)
        .style('width', `${this.menuDivSize}px`)
        .style('height', `${this.menuDivSize}px`)
        .style('background-color', this.menuBackgroundColor)
        .style("border-radius", "50%")
        .on('mouseover', () => {
          d3.select("#ib-d3-graph-menu-div")
          .style('background-color',this.menuBackgroundColor)
          .style("opacity", 1);
        })
        .on('mouseout', () => {
          d3.select("#ib-d3-graph-menu-div")
          .style('background-color', "transparent")
          .style("opacity", this.menuOpacity);
        });
  }
}
