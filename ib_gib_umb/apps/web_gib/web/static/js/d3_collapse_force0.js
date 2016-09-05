import * as d3 from "d3";

export class IbScape {
  constructor(graphDiv, graphCanvas) {
    this.graphDiv = graphDiv;
    this.graphCanvas = graphCanvas;


    window.onresize = () => {
      const debounceMs = 250;

      if (this.resizeTimer) { clearTimeout(this.resizeTimer); }

      this.resizeTimer = setTimeout(() => {

        console.log("resized yo");
        this.destroyStuff();
        this.init();

      }, debounceMs);
    };
  }

  init(data) {
    let t = this;
    t.width = t.graphDiv.scrollWidth;
    t.height = t.graphDiv.scrollHeight;

    t.graphCanvas.setAttribute('width', t.width);
    t.graphCanvas.setAttribute('height', t.height);

    t.context = t.graphCanvas.getContext("2d");

    t.simulation = d3.forceSimulation()
        .force("link", d3.forceLink().id(function(d) { return d.id; }))
        .force("charge", d3.forceManyBody())
        .force("center", d3.forceCenter(t.width / 2, t.height / 2));

    // d3.json("images/miserables.json", function(error, graph) {
    d3.json(data, function(error, graph) {
      if (error) throw error;

      t.simulation
          .nodes(graph.nodes)
          .on("tick", ticked);

      t.simulation.force("link")
          .links(graph.links);

      d3.select(t.graphCanvas)
          .call(d3.drag()
              .container(t.graphCanvas)
              .subject(dragsubject)
              .on("start", dragstarted)
              .on("drag", dragged)
              .on("end", dragended));

      function ticked() {
        t.context.clearRect(0, 0, t.width, t.height);

        t.context.beginPath();
        graph.links.forEach(drawLink);
        t.context.strokeStyle = "#aaa";
        t.context.stroke();

        t.context.beginPath();
        graph.nodes.forEach(drawNode);
        t.context.fill();
        t.context.strokeStyle = "#fff";
        t.context.stroke();
      }

      function drawLink(d) {
        t.context.moveTo(d.source.x, d.source.y);
        t.context.lineTo(d.target.x, d.target.y);
      }

      function drawNode(d) {
        t.context.moveTo(d.x + 3, d.y);
        t.context.arc(d.x, d.y, 25, 0, 2 * Math.PI);
        // t.context.arc(d.x, d.y, 3, 0, 2 * Math.PI);
      }
    });

    function dragsubject() {
      return t.simulation.find(d3.event.x, d3.event.y);
    }

    function dragstarted() {
      if (!d3.event.active) t.simulation.alphaTarget(0.3).restart();
      d3.event.subject.fx = d3.event.subject.x;
      d3.event.subject.fy = d3.event.subject.y;
    }

    function dragged() {
      d3.event.subject.fx = d3.event.x;
      d3.event.subject.fy = d3.event.y;
    }

    function dragended() {
      if (!d3.event.active) t.simulation.alphaTarget(0);
      d3.event.subject.fx = null;
      d3.event.subject.fy = null;
    }
  }

  destroyStuff() {
    delete(this.simulation);
    delete(this.context);
    delete(this.height);
    delete(this.width);
  }


  // {
  //   "rel8ns": {
  //     "result":["ib^gib"],
  //     "query":["query^EBF6C1403C60DCE7B0DD59719A742BE81C55101CA27EDCEABB03AEB126B92EBE"],
  //     "dna":["ib^gib","query^EBF6C1403C60DCE7B0DD59719A742BE81C55101CA27EDCEABB03AEB126B92EBE"],
  //     "ancestor":["query_result^gib"]
  //   },
  //
  //   "ib":"query_result",
  //   "gib":"642E17932EBD7BB5135B0550E1260DF1D3EC9A821E675EA416F75BD5F38D0F82",
  //   "data":{"result_count":"1"}
  // }
}
