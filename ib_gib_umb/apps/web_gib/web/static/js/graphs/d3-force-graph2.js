import { D3ForceGraph } from './d3-force-graph';

export class D3ForceGraph2 extends D3ForceGraph {
  constructor(graphDiv, svgId) {
    super(graphDiv, svgId);
  }

  getRadius(d) {
    const min = 5;
    const max = 35;
    let r = Math.trunc(5000 / (d.id || 1));
    if (r < min) r = min;
    if (r > max) r = max;

    return r;
  }
  getColor(d) { return "lightblue"; }
}
