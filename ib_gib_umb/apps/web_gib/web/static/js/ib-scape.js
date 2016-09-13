import * as d3 from 'd3';
import { d3CircleRadius, d3Scales, d3Colors, d3MenuCommands } from './d3params';
// import { nerdAlert } from './text-helpers';

export class IbScape {
  constructor(graphDiv, ibEngine) {
    this.ibEngine = ibEngine;
    this.graphDiv = graphDiv;

    this.circleRadius = 10;

    window.onresize = () => {
      const debounceMs = 250;

      if (this.resizeTimer) { clearTimeout(this.resizeTimer); }

      this.resizeTimer = setTimeout(() => {
        this.destroyStuff();
        this.update(null);
      }, debounceMs);
    };
  }

  update(data) {
    let t = this;
    if (data) {
      t.data = data;
    } else {
      data = t.data;
    }
    t.rect = t.graphDiv.getBoundingClientRect();
    t.width = t.graphDiv.scrollWidth;
    t.height = t.graphDiv.scrollHeight;
    t.center = {x: t.width / 2, y: t.height / 2};

    // graph area
    let svg = d3.select("#ib-d3-graph-div")
        .append("svg")
        .attr('id', "ib-d3-graph-area")
        .attr('width', t.width)
        .attr('height', t.height);
    t.svg = svg;

    // background
    let view = svg.append("rect")
        .attr("fill", "#F2F7F0")
        .attr("class", "view")
        .attr("x", 0.5)
        .attr("y", 0.5)
        .attr("width", t.width - 1)
        .attr("height", t.height - 1)
        .on("click", backgroundClicked);
    t.view = view;

    // Holds child components (nodes, links)
    // Need this for zooming.
    let vis = svg
        .append('svg:g')
          .attr("id", "d3vis");
    t.vis = vis;

    let zoom = d3.zoom().on("zoom", () => {
      vis.attr("transform",
        `translate(${d3.event.transform.x}, ${d3.event.transform.y})` + " " +
        `scale(${d3.event.transform.k})`);
    });
    view.call(zoom);

    let simulation = d3.forceSimulation()
        .velocityDecay(0.55)
        // .force("link", d3.forceLink(links).distance(20).strength(1))
        .force("link", d3.forceLink().distance(20).strength(.8).id(function(d) { return d.id; }))
        .force("charge", d3.forceManyBody().strength(25))
        .force("collide", d3.forceCollide(3 * d3CircleRadius))
        .force("center", d3.forceCenter(t.width / 2, t.height / 2));
    t.simulation = simulation;

    // Initialize the d3 chart with our data given.
    // graph is the json with {"nodes": ..., "links": ...}
    d3.json(data, function(error, graph) {
      if (error) throw error;

      // This is a hack, but I don't want to trudge through cleaning up this
      // messy javascript code at the moment. The "workingData" is the
      // json, but modified with local settings. So the actual call to the
      // `d3.json` is superfluous if this is already set. Anyway, I'm doing
      // initialize stuff to enable collapsing of categories.
      // Obviously, this is horrifically non-optimized.
      t.rawData = graph;
      if (!t.workingData) {
        let collapsed = ["ancestor", "past", "dna", "query", "rel8d"]
        let hiddenNodeIds = [];
        graph.nodes.forEach(n => {
          if (collapsed.some(c => c === n.cat)) {
            n.visible = false;
            n.collapsed = false;
            hiddenNodeIds.push(n.id);
          } else if (collapsed.some(c => c === n.id)) {
            n.visible = true;
            n.collapsed = true;
          } else {
            n.visible = true;
            n.collapsed = false;
          }
        });
        graph.links.forEach(l => {
          if (hiddenNodeIds.some(nid => l.source === nid || l.target === nid)) {
            l.active = false;
          } else {
            l.active = true;
          }
        });


        t.workingData = graph;
      }

      graph = t.workingData;

      // modified nodes
      // hidden means that the node's rel8n is collapsed.
      let modifiedNodes = graph.nodes.filter(n => n.visible);
      // inactive means one of the link's endpoints is hidden.
      let modifiedLinks = graph.links.filter(l => l.active);

      let link = vis.append("g")
          .attr("class", "links")
        .selectAll("line")
        .data(modifiedLinks)
        .enter().append("line")
          .attr("stroke-width", function(d) { return Math.sqrt(d.value); });

      let node = vis.append("g")
          .attr("class", "nodes")
        .selectAll("circle")
        .data(modifiedNodes)
        .enter().append("circle")
          .attr("id", d => d.js_id || null)
          .attr("cursor", "pointer")
          .attr("r", getRadius)
          .attr("fill", getColor)
          .on("click", nodeClicked)
          .on("dblclick", nodeDblClicked)
          .call(d3.drag()
              .on("start", dragstarted)
              .on("drag", dragged)
              .on("end", dragended));

      node.append("title")
          .text(function(d) { return d.id; });

      simulation
          .nodes(graph.nodes)
          .on("tick", ticked);

      simulation
          .force("link")
          .links(graph.links);

      function ticked() {
        link
            .attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });

        node
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });
      }
    });

    this.initMenu();

    /** Gets the radius of the circle, depending on the data category. */
    function getRadius(d) {
      let multiplier = d3Scales[d.cat] || d3Scales["default"];
      return d3CircleRadius * multiplier;
    }

    /**
     * Gets the color of the circle, depending mostly on the category with
     * some special exceptions (ibGib, ib).
     */
    function getColor(d) {
      let index = d.cat;
      if (d.ibgib === "ib^gib") {
        index = "ibGib";
      } else if (d.cat === "rel8n") {
        index = d.id;
      }
      return d3Colors[index] || d3Colors["default"];
    }

    function backgroundClicked(d) {
      console.log("background clicked");

      t.clearSelectedNode();

      d3.select("#ib-d3-graph-menu-div")
        .style("left", t.center.x + "px")
        .style("top", t.center.y + "px")
        .style("visibility", "hidden")
        .attr("z-index", -1);

      d3.event.preventDefault();
    }

    function nodeClicked(d) {
      console.log(`nodeClicked: ${JSON.stringify(d)}`);

      // Only handle the click if it's not a double-click.
      if (t.maybeDoubleClicking) {
        // we're double-clicking
        delete t.maybeDoubleClicking;
        delete t.mousePosition;
        delete t.targetNode;
      } else {
        t.maybeDoubleClicking = true;
        t.mousePosition = d3.mouse(t.view.node());
        t.targetNode = d3.event.target;

        setTimeout(() => {
          if (t.maybeDoubleClicking) {
            // It's still set after the timeout, so we didn't do a double-click.
            // I apologize for poor naming.
            // let divIbGibData = document.querySelector("#ibgib-data");
            // let openPath = divIbGibData.getAttribute("data-open-path");
            // if (d.cat !== "rel8n" && d.ibgib !== "ib^gib" && d.cat !== "ib") {
            //   console.log(`clicked ibgib: ${d.ibgib}`)
            //   location.href = openPath + d.ibgib;
            // }

            if (t.selectedDatum && t.selectedDatum.js_id == d.js_id) {
              t.clearSelectedNode();
            } else {
              t.clearSelectedNode();
              t.selectNode(d);
            }

            delete t.maybeDoubleClicking;
          }
        }, 300);
      }

      d3.event.preventDefault();
    }

    function nodeDblClicked(d) {
      // We toggle expanding if the node is double clicked.
      if (d.cat === "rel8n") {
        // HACK: ib-scape nodeDblClicked Hide the menu that pops up on node clicked.
        t.clearSelectedNode();

        t.toggleExpandNode(d);
        t.destroyStuff();
        t.update(null);
      }
    }

    function dragstarted(d) {
      if (!d3.event.active) simulation.alphaTarget(0.3).restart();
      d.fx = d.x;
      d.fy = d.y;
    }

    function dragged(d) {
      d.fx = d3.event.x;
      d.fy = d3.event.y;
    }

    function dragended(d) {
      if (!d3.event.active) simulation.alphaTarget(0);
      d.fx = null;
      d.fy = null;
    }
  }

  clearSelectedNode() {
    d3.select("#d3vis")
      .selectAll("circle")
        .style("opacity", 1);

    if (this.selectedNode) {
      this.tearDownMenu(/*cancelDetails*/ true);

      delete this.selectedNode;
      delete this.selectedDatum;
    }
  }

  selectNode(d) {
    d3.select("#d3vis")
      .selectAll("circle")
        .style("opacity", 0.3);

    this.buildMenu(d);

    this.selectedDatum = d;
    this.selectedNode = d3.select("#" + d.js_id);
    let top =
      d3.select("#" + d.js_id)
          .style("opacity", 1)
          .attr("stroke", "yellow")
          .attr("stroke-width", "10px")
          ;

    let transition =
      d3.transition()
        .duration(150)
        .ease(d3.easeLinear);

    // let mousePosition = d3.mouse(this.view.node());
    // let targetNode = d3.event.target;
    let position = this.getMenuPosition(this.mousePosition, this.targetNode);
    d3.select("#ib-d3-graph-menu-div")
      .transition(transition)
        .style("left", position.x + "px")
        .style("top", position.y + "px")
        .style("visibility", null)
        .attr("z-index", 1000);
  }

  buildMenu(d) {
    let t = this;
    t.menuButtonRadius = 22;

    t.menuDiv = d3.select("#ib-d3-graph-menu-div");

    t.menuArea =
      t.menuDiv
        .append("svg")
          .attr("id", "ib-d3-graph-menu-area")
          .style("width", this.menuDiam)
          .style("height", this.menuDiam);

    t.menuView =
      t.menuArea.append("circle")
        .attr("width", this.menuDiam)
        .attr("height", this.menuDiam)
        .style("fill", "blue");
        // .style("background-color", "transparent");

    t.menuVis = t.menuArea
      .append("svg:g")
        .attr("id", "d3menuvis");

    t.menuSimulation = d3.forceSimulation()
        .velocityDecay(0.07)
        .force("x", d3.forceX().strength(0.02))
        .force("y", d3.forceY().strength(0.02))
        .force("center", d3.forceCenter(t.menuRadius, t.menuRadius))
        .force("collide",
               d3.forceCollide().radius(t.menuButtonRadius).iterations(2));

    // If i put the json file in another folder, it won't get loaded.
    // Maybe something to do with brunch, I don't know.
    // d3.json("../images/d3Menu.json", function(error, graph) {
    let graph = t.getJson(d);

    let nodeGroup =
      t.menuVis.append("g")
        .attr("class", "nodes")
        .selectAll("circle")
        .data(graph.nodes)
        .enter();

    let nodeCircles =
      nodeGroup
        .append("circle")
        .attr("id", d => d.id)
        .attr("r", t.menuButtonRadius)
        .attr("cursor", "pointer")
        .on("click", menuNodeClicked)
        .attr("fill", d => d.color);

    nodeCircles
        .append("title")
        .text(d => d.text);

    let nodeTextsGroup =
      t.menuVis.append("g")
        .attr("class", "nodeTexts")
        .selectAll("text")
        .data(graph.nodes)
        .enter();

    let nodeTexts =
      nodeTextsGroup
        .append("text")
        .attr("font-size", "30px")
        .attr("fill", "#4F6627")
        .attr("text-anchor", "middle")
        .attr("cursor", "pointer")
        .attr("class", "ib-noselect")
        .on("click", menuNodeClicked)
        .text(d => d.text)
        .attr('dominant-baseline', 'central')
        .attr('font-family', 'FontAwesome')
        .text(d => d.icon);

    nodeTexts
        .append("title")
        .text(d => `${d.text}: ${d.description}`);

    let nodes = graph.nodes;

    t.menuSimulation
        .nodes(graph.nodes)
        .on("tick", tickedMenu);

    function tickedMenu() {
      nodeCircles
          .attr("cx", function(d) { return d.x; })
          .attr("cy", function(d) { return d.y; });

      let posTweak = 5;
      nodeTexts
        .attr("x", d => d.x)
        .attr("y", d => d.y);
    }

    function menuNodeClicked(d) {
      console.log(`menu node clicked. d: ${JSON.stringify(d)}`);

      let transition =
        d3.transition()
          .duration(150)
          .ease(d3.easeLinear);

      d3.select(`#${d.id}`)
        .transition(transition)
          .attr("r", 1.2 * t.menuButtonRadius)
        .transition()
          .attr("r", t.menuButtonRadius);

      t.executeMenuCommand(t.selectedDatum, d);
    }
  }

  executeMenuCommand(dIbGib, dCommand) {
    if ((dCommand.name === "view" || dCommand.name === "hide") &&
         dIbGib.cat === "rel8n") {
      this.toggleExpandNode(dIbGib);
      this.destroyStuff();
      this.update(null);
    } else if (dCommand.name == "fork") {
      // this.ibEngine.fork(dIbGib.ibgib);
      this.execFork(dIbGib)
    } else if (dCommand.name == "goto") {
      this.execGoto(dIbGib);
    } else if (dCommand.name == "help") {
      this.execHelp(dIbGib);
    } else if (dCommand.name == "comment") {
      this.execComment(dIbGib);
    }
  }

  execComment(dIbGib) {
    let init = () => {
      d3.select("#comment_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("comment", init);
  }

  execHelp(dIbGib) {

    let init = () => {
      console.log("initializing help...");
      let text = "Hrmmm...you shouldn't be seeing this! This means that I " +
        "haven't included help for this yet. Let me know please :-O";

      if (dIbGib.ibgib === "ib^gib") {
        text = `The green ibGib is a special ibGib called the 'root'. It is the Alpha and the Omega. It is always the first ancestor, the first dna, the first query result. It is its own ancestor and past.`;
      } else if (dIbGib.cat === "ib") {
        text = `The yellow ibGib is your current ibGib. Click the information button to get more details about it. You can expand / collapse any children, fork it, merge it, add comments, pictures, links, and more.`;
      } else if (dIbGib.cat === "ancestor") {
        text = `This is an 'ancestor' ibGib. Each 'new' ibGib is created by forking an existing one. Ancestors are how we keep track of which ibGib we've forked to produce the current incarnation.`
      } else if (dIbGib.cat === "past") {
        text = `This is a 'past' version of your current ibGib. You can think of past ibGib kinda like when you 'undo' a text document. Each time you mut8 an ibGib, either by adding/removing a comment or image, changing a comment, etc., you create a 'new' version in time. ibGib retains all histories of all changes of all ibGib!`
      } else if (dIbGib.cat === "dna") {
        text = `Just like a living organism, each ibGib is produced by an internal "dna" code. Each building block is itself an ibGib that you can look at.`;
      } else if (dIbGib.cat === "rel8n") {
        text = `This is the '${dIbGib.name}' rel8n node. All of its children are rel8ed to the current ibGib by this rel8n. One ibGib can have multiple rel8ns to any other ibGib. You can expand / collapse the rel8n to show / hide its children by either double-clicking or clicking and selecting the "view" button.`
      } else {
        text = `This is one of the related ibGib. Click the information button to get more details about it. You can also navigate to it, expand / collapse any children, fork it, merge it, add comments, pictures, links, and more.`;
      }

      $("#ib-help-details-text").text(text);
    };

    this.showDetails("help", init);
  }

  execGoto(dIbGib) {
    location.href = `/ibgib/${dIbGib.ibgib}`
  }

  /**
   * This uses a convention that each details div is named
   * `#ib-${cmdName}-details`. It shows the details div, initializes the
   * specifics to the given cmdName and pops it up. This also takes care of
   * cancelling, which is effected when the user just clicks somewhere else.
   */
  showDetails(cmdName, initFunction) {
    this.ibScapeDetails =
      d3.select("#ib-scape-details")
        // .attr("class", null)
        .attr("class", "ib-pos-abs ib-info-border");

    this.details =
      d3.select(`#ib-${cmdName}-details`)
        .attr("class", "ib-details-on");

    // Position the details based on its size.
    let ibScapeDetailsDiv = this.ibScapeDetails.node();
    let detailsRect = ibScapeDetailsDiv.getBoundingClientRect();
    ibScapeDetailsDiv.style.position = "absolute";

    // Relative to top left corner of the graph, move up and left half
    // of the details height/width.
    ibScapeDetailsDiv.style.left = (this.rect.left + this.center.x - (detailsRect.width / 2)) + "px";
    ibScapeDetailsDiv.style.top = (this.rect.top + this.center.y - (detailsRect.height / 2)) + "px";

    // Initialize details specific to given cmd
    initFunction();

    // console.log(`src_ib_gib: ${dIbGib.ibgib}`);

    // d3.select("#ib-scape-details-close-btn")
    //   .on("click", this.cancelDetails);

    this.tearDownMenu(/*cancelDetails*/ false);
  }

  execFork(dIbGib) {
    let init = () => {
      d3.select("#fork_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("fork", init);
  }

  cancelDetails() {
    if (this.details) {
      console.log("cancelled.");
      d3.select("#ib-scape-details")
        .attr("class", "ib-pos-abs ib-details-off");

      this.details
        .attr("class", "ib-details-off");

      delete this.details;
    }
  }

  toggleExpandNode(dRel8n) {
    if (dRel8n.collapsed) {
      // expand
      dRel8n.collapsed = false;

      // show hidden nodes
      this.workingData.nodes.forEach(n => {
        if (n.cat === dRel8n.id) {
          n.visible = true;
        }
      });

      // activate links
      this.workingData.links.forEach(l => {
        if (l.source.js_id === dRel8n.js_id || l.target.js_id === dRel8n.js_id) {
          l.active = true;
        }
      });
    } else {
      // collapse
      dRel8n.collapsed = true;

      // show hidden nodes
      this.workingData.nodes.forEach(n => {
        if (n.cat === dRel8n.id) {
          n.visible = false;
        }
      });

      // activate links
      this.workingData.links.forEach(l => {
        if (l.source.js_id === dRel8n.js_id) {
          l.active = false;
        }
      });
    }
  }

  tearDownMenu(cancelDetails) {
    if (this.menuArea) { d3.select("#ib-d3-graph-menu-area").remove();
      delete this.menuArea;
    }
    if (this.menuVis) { d3.select("#d3menuvis").remove();
      delete this.menuVis;
    }

    if (cancelDetails) {
      this.cancelDetails();
    }

    d3.select("#ib-d3-graph-menu-div")
      .style("visibility", "hidden");
  }

  getMenuPosition(mousePosition, targetNode) {
    // Start our position away from right where we click.

    // let bufferAwayFromClickPoint = this.menuRadius;
    let bufferAwayFromClickPoint = 30; //magic number :-/
    let $graphDivPos = $(`#${this.graphDiv.id}`).position();

    let mousePosIsOnLeftSide = mousePosition[0] < this.width/2;
    let x = mousePosIsOnLeftSide ?
            $graphDivPos.left + mousePosition[0] + bufferAwayFromClickPoint :
            $graphDivPos.left + mousePosition[0] - this.menuDiam;
    if (x < $graphDivPos.left) { x = $graphDivPos.left; }
    if (x > $graphDivPos.left + this.width - this.menuDiam) {
      x = $graphDivPos.left + this.width - this.menuDiam;
    }

    let mousePosIsInTopHalf = mousePosition[1] < (this.height/2);
    let y = mousePosIsInTopHalf ?
            $graphDivPos.top + mousePosition[1] + bufferAwayFromClickPoint :
            $graphDivPos.top + mousePosition[1] - this.menuDiam;
    if (y < $graphDivPos.top) { y = $graphDivPos.top; }
    if (y > $graphDivPos.top + this.height - this.menuDiam) {
      y = $graphDivPos.top + this.height - this.menuDiam;
    }

    return {
      x: x,
      y: y
    }
  }

  destroyStuff() {
    d3.select("#ib-d3-graph-area").remove();
    d3.select("#ib-d3-graph-menu-div").remove();

    delete(this.svg);
    delete(this.view);
    delete(this.vis);
    delete(this.simulation);
    delete(this.height);
    delete(this.width);
  }

  initMenu() {
    let t = this;
    this.menuRadius = 120;
    this.menuDiam = 2 * this.menuRadius;
    this.menuDivSize = this.menuDiam;
    this.menuBackgroundColor = "#2B572E";
    this.menuOpacity = 0.7;

    d3.select("#ib-d3-graph-div")
      .append('div')
        .attr("id", "ib-d3-graph-menu-div")
        .style('position','absolute')
        .style("top", 200 + "px")
        .style("left", 200 + "px")
        .style("visibility", "hidden")
        .style("opacity", this.menuOpacity)
        .attr("z-index", 100)
        .style('width', `${this.menuDivSize}px`)
        .style('height', `${this.menuDivSize}px`)
        .style('background-color', this.menuBackgroundColor)
        .style("border-radius", "50%")
        .on('mouseover', () => {
          d3.select("#ib-d3-graph-menu-div")
          .style('background-color',this.menuBackgroundColor)
          .style("opacity", 1);
        })
        .on('mouseout', () => {
          d3.select("#ib-d3-graph-menu-div")
          .style('background-color', "transparent")
          .style("opacity", this.menuOpacity);
        });
  }

  /**
   * Builds the json that d3 requires for showing the menu to the user.
   * This menu is what shows the commands for the user to do, e.g. "fork",
   * "merge", etc.
   */
  getJson(d) {
    // TODO: ib-scape.js getJson: When we have client-side dynamicism (prefs, whatever), then we need to change this to take that into account when building the popup menu.
    let commands = [];

    if (d.cat === "rel8n") {
      commands = ["help", "view"];
    } else if (d.ibgib && d.ibgib === "ib^gib") {
      // commands = ["help", "fork", "meta", "query"];
      commands = ["help", "fork", "goto"];
    } else if (d.cat === "ib") {
      // commands = ["pic", "info", "merge", "help", "share", "comment", "star", "fork", "flag", "thumbs up", "query", "meta", "mut8", "link"];
      commands = ["help", "fork", "comment"];
    } else {
      // commands = ["pic", "info", "merge", "help", "share", "comment", "star", "fork", "flag", "thumbs up", "query", "meta", "mut8", "link", "goto"];
      commands = ["help", "fork", "goto", "comment"];
    }

    let nodes = commands.map(cmdName => d3MenuCommands.filter(cmd => cmd.name == cmdName)[0]);
    return {
      "nodes": nodes
    };
  }
}
