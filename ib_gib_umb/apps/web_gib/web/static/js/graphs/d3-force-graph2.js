import { D3ForceGraph } from './d3-force-graph';

export class D3ForceGraph2 extends D3ForceGraph {
  constructor(graphDiv, svgId) {
    super(graphDiv, svgId);
  }

  getRadius(d) {
    const min = 5;
    const max = 25;
    let x = Math.abs(50000 - (d.id || 1)) / 50000;
    let r = Math.trunc(x * max);
    if (r < min) r = min;
    if (r > max) r = max;

    return r;
  }
  getColor(d) { return "lightblue"; }
}
