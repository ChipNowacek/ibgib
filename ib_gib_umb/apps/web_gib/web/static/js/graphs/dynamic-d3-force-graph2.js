import * as d3 from 'd3';
import { DynamicD3ForceGraph } from './dynamic-d3-force-graph';

export class DynamicD3ForceGraph2 extends DynamicD3ForceGraph {
  constructor(graphDiv, svgId, config) {
    super(graphDiv, svgId, {});
    let t = this;

    let defaults = {
      background: {
        fill: "pink",
        opacity: 0.7,
        shape: "rect"
      },
      mouse: {
        dblClickMs: 250,
        longPressMs: 900
      },
      simulation: {
        velocityDecay: 0.15,
        chargeStrength: -250,
        chargeDistanceMin: 100,
        chargeDistanceMax: 10000,
        linkDistance: 1000,
      },
      node: {
        cursorType: "crosshair",
        baseRadiusSize: 35,
        defShapeFill: "lightblue",
        defBorderStroke: "darkgreen",
        defBorderStrokeWidth: "5px",
        label: {
          fontFamily: "Arial",
          fontStroke: "pink",
          fontFill: "red",
          fontSize: "12px",
          fontOffset: 8
        },
        image: {
          backgroundFill: "purple"
        }
      }
    }
    t.config = $.extend({}, defaults, config || {});
  }

  getForceLinkDistance(d) {
    return Math.random() * this.config.simulation.linkDistance;
  }

  getNodeShapeRadius(d) {
    // console.log("getNodeShapeRadius");
    const min = 15;
    const max = 75;
    let x = Math.abs(50000 - (d.id || 1)) / 50000;
    let r = Math.trunc(x * 100);
    if (r < min) r = min;
    if (r > max) r = max;

    d.r = r;

    return r;
  }
}
