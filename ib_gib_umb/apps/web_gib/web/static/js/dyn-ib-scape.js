import { IbD3ForceGraph } from './graphs/ib-d3-force-graph';

export class IbScape {
  constructor(graphDiv) {
    this.graphDiv = graphDiv;
  }

  setGraphType(type) {
    let t = this;

    if (t.ibGraph) {
      t.ibGraph.destroy();
      delete t.ibGraph;
    }

    if (type === "d3force") {
      t.svgId = "testSvgId";
      t.ibGraph = new IbD3ForceGraph(t.graphDiv, null, t.svgId);
      t.ibGraph.init();
    } else {
      console.error(`unknown type: ${type}`);
    }
  }

  addTestData() {
    let t = this;

    let infos = [
      { id: 0, srcId: 0, fx: 0, fy: 0 },
      { id: 1, srcId: 0, fx: 0, fy: 0 },
      { id: 2, srcId: 0, fx: 0, fy: 0 },
      { id: 311, srcId: 1, fx: 0, fy: 0 },
      { id: 3221, srcId: 2, fx: 0, fy: 0 },
      { id: 23512351, srcId: 0, fx: 0, fy: 0 },
      { id: 223, srcId: 0, fx: 0, fy: 0 },
      { id: 12351, srcId: 1, fx: 0, fy: 0 },
      { id: 2511, srcId: 2, fx: 0, fy: 0 },
      { id: 571, srcId: 0, fx: 0, fy: 0 },
      { id: 7542, srcId: 0, fx: 0, fy: 0 },
      { id: 15861, srcId: 1, fx: 0, fy: 0 },
      { id: 275471, srcId: 2, fx: 0, fy: 0 },
      { id: 3641, srcId: 0, fx: 0, fy: 0 },
      { id: 2223463, srcId: 0, fx: 0, fy: 0 },
      { id: 123541, srcId: 1, fx: 0, fy: 0 },
      { id: 245721, srcId: 2, fx: 0, fy: 0 },
      { id: 24574571, srcId: 0, fx: 0, fy: 0 },
      { id: 23452, srcId: 0, fx: 0, fy: 0 },
      { id: 112341, srcId: 1, fx: 0, fy: 0 },
      { id: 212341, srcId: 2, fx: 0, fy: 0 },
      { id: 274571, srcId: 0, fx: 0, fy: 0 },
      { id: 4574352, srcId: 0, fx: 0, fy: 0 }
    ];

    t.ibGraph.beginUpdate();

    infos.forEach(info => {
      t.ibGraph.add(info);
    })

    t.ibGraph.endUpdate(true);
  }
}
