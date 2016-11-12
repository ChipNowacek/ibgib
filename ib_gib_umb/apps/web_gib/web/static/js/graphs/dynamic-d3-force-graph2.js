import * as d3 from 'd3';
import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';

export class DynamicD3ForceGraph2 extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId) {
    super(graphDiv, svgId);
  }


  getBackgroundFill() { return "pink"; }

  getVelocityDecay() { return 0.15; }
  getForceLink() {
    return d3.forceLink()
             .distance(500)
             .id(d => d.id);
  }

  getNodeShapeFill(d) { return "darkblue"; }
}
