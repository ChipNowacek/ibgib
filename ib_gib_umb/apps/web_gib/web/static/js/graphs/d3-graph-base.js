import * as d3 from 'd3';
import { GraphBase } from './graph-base';

export class D3GraphBase extends GraphBase {
  constructor(graphDiv, svgId) {
    if (new.target === D3GraphBase) {
      throw new TypeError("Cannot construct D3GraphBase instances directly");
    }

    super(graphDiv);
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

    // graph area
    let svg = d3.select(t.graphDiv)
      .append("svg")
      .attr('id', t.svgId)
      .attr('width', t.width)
      .attr('height', t.height);
    t.svg = svg;

    // background
    let background = svg
      .append("rect")
      .attr("fill", "#F2F7F0")
      .attr("class", "view")
      .attr("x", 0.5)
      .attr("y", 0.5)
      .attr("width", t.width - 1)
      .attr("height", t.height - 1)
      .on("click", t.handleBackgroundClicked);
    t.background = background;

    // Holds child components (nodes, links)
    let svgGroup = svg
        .append('svg:g')
          .attr("id", "svgGroup");
    t.svgGroup = svgGroup;

    t.initZoom();
  }

  beginUpdate() {
    // console.log(`begin...updateRefCount: ${this.updateRefCount}`)
    this.updateRefCount += 1;
  }

  endUpdate(full) {
    // console.log(`end...updateRefCount: ${this.updateRefCount}`)

    this.updateRefCount -= 1;
    if (this.updateRefCount === 0) {
      this.refresh(full);
    }
  }

  add(info) {
    let t = this;

    let isValid = t.validate(info);
    if (isValid) {
      let d = t.buildDatum(info);
      if (t.existsInGraph(d)) {
        return null; // already exists
      } else {
        let result;
        this.beginUpdate();
        try {
          t.addToGraph(d);
          result = d; // added
        } catch (e) {
          console.error(JSON.stringify(e));
          result = null;
        } finally {
          this.endUpdate(/*full*/ false);
        }
        return result;
      }
    } else {
      return null; // invalid
    }
  }

  remove(d) {
    throw new TypeError("remove must be implemented.");
  }

  addToGraph(d) {
    throw new TypeError("addToGraph must be implemented.");
  }

  existsInGraph(d) {
    throw new TypeError("existsInGraph must be implemented.");
  }

  validate(info) {
    if (info.id || info.id === 0) {
      return true;
    } else {
      console.error("info.id does not exist");
      return false;
    }
  }

  buildDatum(info) {
    return info;
  }

  refresh(full) {
    throw new TypeError("refresh must be implemented");
  }

  destroy() {
    let t = this;

    t.zoom = null;
    t.svgGroup = null;
    t.background = null;
    t.svg = null;
  }

  initZoom() {
    let t = this;

    let zoom =
      d3.zoom()
        .on("zoom", () => t.handleZoom());
    t.background.call(zoom);
    t.zoom = zoom;
  }

  handleZoom() {
    let t = this;

    t.svgGroup
      .attr("transform",
      `translate(${d3.event.transform.x}, ${d3.event.transform.y})` + " " +
      `scale(${d3.event.transform.k})`);
  }

  handleBackgroundClicked(d) {
    console.log("background clicked");
  }
}
