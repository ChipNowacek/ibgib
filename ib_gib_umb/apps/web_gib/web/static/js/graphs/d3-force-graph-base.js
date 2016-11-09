import * as d3 from 'd3';
import { D3GraphBase } from './d3-graph-base';

export class D3ForceGraphBase extends D3GraphBase {
  constructor(graphDiv, colorsJson, svgId) {
    super(graphDiv, colorsJson, svgId);

    if (new.target === D3ForceGraphBase) {
      throw new TypeError("Cannot construct D3ForceGraphBase instances directly");
    }
  }

  init() {
    super.init();
    let t = this;

    t.graphData = { "nodes": [], "links": [] };

    t.initForceSimulation();
  }

  add(info) {
    let t = this;

    let result;
    this.beginUpdate();
    try {
      let d = super.add(info);

      if (d) {
        let link = t.buildLink(d);
        if (link) {
          t.graphData.links.push(link);
        }
        result = d;
      } else {
        result = null;
      }
    } catch (e) {
      console.error(JSON.stringify(e));
      result = false;
    } finally {
      this.endUpdate(/*full*/ false);
    }
    return result;
  }

  remove(d) {
    throw new TypeError("remove must be implemented.");
  }

  validate(info) {
    let superIsValid = super.validate(info);
    let isValid = null;
    if (info.srcId || info.srcId === 0) {
      isValid = true;
    } else {
      console.error("info.srcId does not exist");
      isValid = false;
    }

    return superIsValid && isValid;
  }

  addToGraph(d) {
    this.graphData.nodes.push(d);
  }

  existsInGraph(d) {
    return this.graphData.nodes.some(n => n.id === d.id);
  }

  // buildNode(d) { return super.buildNode(d); }

  buildLink(d) {
    if (d.id === d.srcId) {
      return null;
    } else {
      return { "source": d.srcId, "target": d.id, "value": 1 }
    }
  }

  refresh(full) {
    let t = this;

    let nodes = t.graphData.nodes;
    let links = t.graphData.links;
    t.initGraphNodesAndLinks(nodes, links);

    t.simulation.restart();
  }

  initGraphNodesAndLinks(nodes, links) {
    let t = this;

    t.graphLinks/*Data*/ =
      t.svgGroup
        .append("g")
        .attr("class", "links")
        .selectAll("line")
        .data(links)//;
    // t.graphLinksEnter =
    //   t.graphLinksData
        .enter()
          .append("line")
          .attr("stroke-width", "2px");//t.getLinkWidth); // necessary?
    // t.graphLinksExit =
    //   t.graphLinksData
    //     .exit()
    //     .remove();
    // t.graphLinksData =
    //   t.graphLinksEnter.merge(t.graphLinksData);
    // t.graphLinksData =
    //   t.graphLinksExit.merge(t.graphLinksData);

    t.graphNodesGroup = //Data =
      t.svgGroup
        .selectAll("g.gnode")
        .data(nodes)//;
    // t.graphNodesGroupEnter =
      // t.graphNodesGroupData
        .enter()
          .append("g")
          .on("click", e => { console.log("graphNodesGroup clicked") })
          .call(d3.drag()
              .on("start", d => t.handleDragStarted(d))
              .on("drag", d => t.handleDragged(d))
              .on("end", d => t.handleDragEnded(d)));
    // t.graphNodesGroupExit =
    //   t.graphNodesGroupData
    //     .exit()
    //     .remove();
    // t.graphNodesGroupData =
    //   t.graphNodesGroupEnter.merge(t.graphNodesGroupData);
    // t.graphNodesGroupData =
    //   t.graphNodesGroupExit.merge(t.graphNodesGroupData);

    // graphNodes is g, includes circles, imageDefs, labels, images
    t.graphNodes =
      t.graphNodesGroup//Enter
        .append("g")
        .classed('gnode', true)
        .on("click", t.handleNodeClicked)
        // .on("mousedown", handleNodeMouseDown)
        // .on("touchstart", handleNodeTouchStart)
        // .on("touchend", handleNodeTouchEnd)
        .attr("cursor", "pointer")
        .on("contextmenu", (d, i)  => { d3.event.preventDefault(); });

    t.graphNodeCircles =
      t.graphNodes
        .append("circle")
        .attr("class", "nodes")
        .attr("id", d => d.id || null)
        .attr("cursor", "pointer")
        .attr("r", t.getRadius)
        .attr("fill", t.getColor)
        .attr("stroke", t.getBorderStroke)
        .attr("stroke-width", t.getBorderStrokeWidth);

    t.simulation
      .nodes(t.graphData.nodes)
      .on("tick", t.handleTicked(t.graphLinks/*Data*/, t.graphNodesGroup/*Data*/));

    t.simulation
      .force("link")
      .links(t.graphData.links);
  }

  destroy() {
    super.destroy();

    let t = this;

    t.simulation = null;
  }

  initForceSimulation() {
    let t = this;

    let simulation = d3.forceSimulation()
        .velocityDecay(0.35)//t.getForceVelocityDecay)
        .force("link",
               d3.forceLink()
                 .distance(150)//t.getForceLinkDistance)
                 .strength(0.8)//t.getForceStrength)
                 .id(d => d.id))
        .force("charge", d3.forceManyBody().strength(-25))//t.getForceChargeStrength))
        .force("collide", d3.forceCollide(25))//t.getCollideDistance))
        .force("center", d3.forceCenter(t.center.x, t.center.y));
    t.simulation = simulation;
  }

  getForceVelocityDecay(d) { return 0.55; }
  getForceLinkDistance(d) { return 55; }
  getForceStrength(d) { return 0.8; }
  getForceChargeStrength(d) { return -25; }

  getRadius(d) { return 5; }
  getColor(d) { return "green"; }
  getBorderStroke(d) { return "pink"; }
  getBorderStrokeWidth(d) { return "0.5px"; }


  getLinkWidth(d) {
    return 1;
    // return Math.sqrt(d.value);
  }

  handleDragStarted(d) {
    let t = this;

    if (!d3.event.active) t.simulation.alphaTarget(0.3).restart();

    d.fx = d.x || 0;
    d.fy = d.y || 0

    t.x0 = d3.event.x;
    t.y0 = d3.event.y;
    console.log(`drag started d.fx: ${d.fx}`)
  }

  handleDragged(d) {
    let t = this;

    console.log(`dragged d.fx: ${d.fx}`)

    d.fx = d3.event.x;
    d.fy = d3.event.y;

    let dist = Math.sqrt(Math.pow(t.x0 - d.fx, 2) + Math.pow(t.y0 - d.fy, 2));
    if (dist > 2.5) {
      // alert(`dist: ${dist}`)
      delete t.lastMouseDownTime;
      t.x0 = null;
      t.y0 = null;
    }
  }

  handleDragEnded(d) {
    let t = this;

    console.log("handleDragEnded")
    if (!d3.event.active) t.simulation.alphaTarget(0);

    let dist = Math.sqrt(Math.pow(t.x0 - d.fx, 2) + Math.pow(t.y0 - d.fy, 2));

    d.fx = d3.event.x;
    d.fy = d3.event.y;

    d.fx = null;
    d.fy = null;
    t.x0 = null;
    t.y0 = null;
  }

  handleNodeClicked(d) {
    console.log(`node clicked: ${JSON.stringify(d)}`);
    d.fx = 0;
    d.fy = 0;
  }

  handleTicked(graphLinks/*Data*/, graphNodesGroup/*Data*/) {
    // let t = this;
    console.log('ticked')

    graphLinks//Data
      .attr("x1", d => {
        return d.source.x || 0;
      })
      .attr("y1", d => d.source.y || 0)
      .attr("x2", d => d.target.x || 0)
      .attr("y2", d => d.target.y || 0);

    // Translate the groups
    graphNodesGroup//Data
        .attr("transform", d => {
          console.log(`d.x: ${d.x}`)
          return 'translate(' + [d.x, d.y] + ')';
        });
  }

}
