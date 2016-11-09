import { D3ForceGraphBase } from './d3-force-graph-base';

export class IbD3ForceGraph extends D3ForceGraphBase {
  constructor(graphDiv, colorsJson, svgId) {
    super(graphDiv, colorsJson, svgId);
  }
}
