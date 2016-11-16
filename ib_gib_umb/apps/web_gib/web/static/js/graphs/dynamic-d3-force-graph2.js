import * as d3 from 'd3';
import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';

export class DynamicD3ForceGraph2 extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId) {
    super(graphDiv, svgId);
  }


  getBackgroundFill() { return "pink"; }

  getVelocityDecay() { return 0.15; }
  getForceLinkDistance(d) { return Math.random() * 600; }

  getNodeShapeRadius(d) {
    // console.log("getNodeShapeRadius");
    const min = 15;
    const max = 65;
    let x = Math.abs(50000 - (d.id || 1)) / 50000;
    let r = Math.trunc(x * 100);
    if (r < min) r = min;
    if (r > max) r = max;

    d.r = r;

    return r;
  }

  getNodeShapeFill(d) { return "lightblue"; }
  getNodeBorderStroke(d) { return "darkblue"; }
  getNodeBorderStrokeWidth(d) { return "2.5px"; }
}
