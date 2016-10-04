import * as d3 from 'd3';
import * as d3text from 'd3-textwrap';
import { d3CircleRadius, d3Scales, d3Colors, d3DefaultCollapsed, d3MenuCommands } from './d3params';
// import { nerdAlert } from './text-helpers';
import * as ibHelper from './services/ibgib-helper';


export class IbScape {
  constructor(graphDiv, baseJsonPath, ibGibCache, ibGibImageProvider) {
    this.graphDiv = graphDiv;
    this.baseJsonPath = baseJsonPath;
    this.ibGibCache = ibGibCache;
    this.ibGibImageProvider = ibGibImageProvider;

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
    let svgGroup = svg
        .append('svg:g')
          .attr("id", "d3vis");
    t.svgGroup = svgGroup;

    let zoom = d3.zoom().on("zoom", () => {
      svgGroup.attr("transform",
        `translate(${d3.event.transform.x}, ${d3.event.transform.y})` + " " +
        `scale(${d3.event.transform.k})`);
    });
    view.call(zoom);

    let simulation = d3.forceSimulation()
        .velocityDecay(0.55)
        // .force("link", d3.forceLink(links).distance(20).strength(1))
        .force("link",
               d3.forceLink()
                 .distance(getLinkDistance)
                 .strength(.8)
                 .id(d => d.id))
        .force("charge", d3.forceManyBody().strength(-25))
        // .force("collide", d3.forceCollide(3 * d3CircleRadius))
        .force("collide", d3.forceCollide(getCollideDistance))
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
        let hiddenNodeIds = [];
        graph.nodes.forEach(n => {
          if (d3DefaultCollapsed.some(rel8n => rel8n === n.cat)) {
            // If a node's rel8n is in the collapsed cats list, hide it.
            n.visible = false;
            n.collapsed = false;
            hiddenNodeIds.push(n.id);
          } else if (d3DefaultCollapsed.some(cat => cat === n.id)) {
            // If the node's id itself is the rel8n, then keep it visible but
            // mark it as collapsed.
            n.visible = true;
            n.collapsed = true;
          } else {
            // The node is not a collapsed rel8n, and it's not in a collapsed
            // rel8n.
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

      let graphLinks = svgGroup.append("g")
          .attr("class", "links")
          .selectAll("line")
          .data(modifiedLinks)
          .enter().append("line")
          .attr("stroke-width", function(d) { return Math.sqrt(d.value); });


      let graphNodes = svgGroup
          .selectAll("g.gnode")
          .data(modifiedNodes)
          .enter()
          .append("g")
          .classed('gnode', true)
          .call(d3.drag()
              .on("start", dragstarted)
              .on("drag", dragged)
              .on("end", dragended));


      let graphNodeHyperlinks = graphNodes
          .append("foreignObject")
          .attr("name", "graphNodeLink")
          .attr("width", 1)
          .attr("height", 1)
          .html(d => {
            let graphNodeLinkId = "link_" + d.js_id;
            return `<a id="${graphNodeLinkId}" href="#"></a>`;
          });

      d3.selectAll("[name=graphNodeLink]")
          .select("a")
          .on("click", nodeClicked);

      let graphImageDefs = graphNodes
          .append("defs")
          .attr("id", "imgDefs");
      t.graphImageDefs = graphImageDefs;

      let graphNodeCircles = graphNodes
          .append("circle")
          .attr("class", "nodes")
          .attr("id", d => d.js_id || null)
          .attr("cursor", "pointer")
          .attr("r", getRadius)
          .attr("fill", getColor)
          .on("click", nodeClicked)
          .on("dblclick", nodeDblClicked);

      graphNodeCircles.append("title")
          .text(getNodeLabel);

      let graphNodeLabels = graphNodes
          .append("text")
          .attr("id", d => "label_" + d.js_id)
          .attr("font-size", "3px")
          .attr("text-anchor", "middle")
          .text(getNodeLabel)

      graphNodeLabels.append("title")
          .text(getNodeLabel);

      // create a text wrapping function
      var wrap = d3text.textwrap()
          .bounds({height: 75, width: 25})
          .method('tspans');
      t.wrap = wrap;

      graphNodeLabels
          .call(wrap)
          .attr("text-anchor", "middle");

      let graphNodeImages = graphNodes
          .append("image")
          .attr("id", d => "img_" + d.js_id)
          .attr("xlink:href", getNodeImage)
          .attr("cursor", "pointer")
          .on("click", nodeClicked)
          .attr("x", -8)
          .attr("y", -8)
          .attr("width", 16)
          .attr("height", 16)
          .on("dblclick", nodeDblClicked)
          .call(d3.drag()
              .on("start", dragstarted)
              .on("drag", dragged)
              .on("end", dragended));

      graphNodeImages.append("title")
          .text(d => d.id);

      simulation
          .nodes(graph.nodes)
          .on("tick", ticked);

      simulation
          .force("link")
          .links(graph.links);

      function ticked() {
        graphLinks
            .attr("x1", d => d.source.x)
            .attr("y1", d => d.source.y)
            .attr("x2", d => d.target.x)
            .attr("y2", d => d.target.y);

        // Translate the groups
        graphNodes
            .attr("transform", d => 'translate(' + [d.x, d.y] + ')');
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

    function getNodeLabel(d) {
      if (d.render === "text" || d.render == "link") {
        let ibGibJson = t.ibGibCache.get(d.ibgib);
        if (ibGibJson) {
          // hack because it's double-adding the label texts when
          // expand/collapase and I don't know why.
          setTimeout(() => updateLabelText(d, ibGibJson), 700);
          return "loading...";
        } else {
          // We don't yet have the json for this particular data
          // So we need to load the json, and when it returns we will
          // set the label then.
          d3.json(t.baseJsonPath + d.ibgib, ibGibJson => {
            t.ibGibCache.add(ibGibJson);
            updateLabelText(d, ibGibJson);
          });
          return "loading...";
        }
      } else {
        // Label gets no text because it's not rendered as text.
        return "";
      }
    }

    function updateLabelText(d, ibGibJson) {
      let labelText =
          ibGibJson && ibGibJson.data && ibGibJson.data.text ?
          ibGibJson.data.text :
          "?";

      d3.select("#label_" + d.js_id)
        .text(labelText)
        .call(t.wrap)
        .select('title')
        .text(labelText);

      d3.select("#" + d.js_id)
        .select('title')
        .text(labelText);

      d3.select("#img_" + d.js_id)
        .select('title')
        .text(labelText);
    }

    function getNodeImage(d) {
      if (d.render === "text") {
        return null;
      } else if (d.render && d.render === "image") {
        let ibGibJson = t.ibGibCache.get(d.ibgib);
        if (ibGibJson) {
          let imageUrl =
            t.ibGibImageProvider.getFullImageUrl(d.ibgib, ibGibJson);
          makeImageNode(d, ibGibJson, imageUrl);
        } else {
          d3.json(t.baseJsonPath + d.ibgib, ibGibJson => {
            t.ibGibCache.add(ibGibJson);

            let imageUrl = t.ibGibImageProvider.getFullImageUrl(d.ibgib, ibGibJson);

            makeImageNode(d, ibGibJson, imageUrl);
          });

          return "...";
        }
      } else {
        return "/images/ibgib_100x200.png";
      }
    }

    function makeImageNode(d, ibGibJson, imageUrl) {
      let patternId = "imgDef_" + d.js_id;
      // Magic numbers here...I don't really know what they do. :-X
      let imagePattern = t.graphImageDefs
        .append("pattern")
        .attr("id", patternId)
        // I really have no idea about these 1s.
        .attr("height", 1)
        .attr("width", 1)
        .attr("x", 0)
        .attr("y", 0);

        // Magic numbers here...I don't really know what they do. :-X
      imagePattern
        .append("image")
        // Some kind of offset
        .attr("x", -75)
        .attr("y", -75)
        // Some kind of sizing. I have it set to fill the whole circle
        .attr("height", 300)
        .attr("width", 300)
        .attr("xlink:href", imageUrl);

      let label = ibGibJson.data.filename;
      d3.select("#img_" + d.js_id)
        .remove();

      d3.select("#label_" + d.js_id)
        .text("")
        .call(t.wrap)
        .select('title')
        .text(label);

      d3.select("#" + d.js_id)
        .attr("fill", `url(#${patternId})`)
        .select('title')
        .text(label);

    }

    function getLinkDistance(l) {
      if (["comment", "pic", "link"].some(x => x == l.target.id)) {
        return 150;
      } else if (["comment", "pic", "link"].some(x => x == l.target.cat)) {
        return 30;
      } else if (l.target.cat === "rel8n") {
        return 50;
      } else {
        return 80;
      }
    }

    function getCollideDistance(dIbGib, i, allIbGibs) {
      let scale = d3Scales[dIbGib.cat] || 3;
      return scale * d3CircleRadius;
    }
  }

  clearSelectedNode() {
    d3.select("#d3vis")
      .selectAll("circle")
        .style("opacity", 1)
        .attr("stroke", null)
        .attr("stroke-width", null)
        ;

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
    let graph = t.getMenuCommandsJson(d);

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

    let menuNodeHyperlinks = nodeGroup
        .append("foreignObject")
        .attr("name", "menuNodeHyperlink")
        .attr("width", 1)
        .attr("height", 1)
        .html(d => {
          let menuNodeHyperlinkId = "menulink_" + d.id;
          return `<a id="${menuNodeHyperlinkId}" href="#"></a>`;
        });

    d3.selectAll("[name=menuNodeHyperlink]")
        .select("a")
        .on("click", menuNodeClicked);


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

      menuNodeHyperlinks
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
      this.execFork(dIbGib)
    } else if (dCommand.name == "goto") {
      this.execGoto(dIbGib);
    } else if (dCommand.name == "help") {
      this.execHelp(dIbGib);
    } else if (dCommand.name == "comment") {
      this.execComment(dIbGib);
    } else if (dCommand.name == "pic") {
      this.execPic(dIbGib);
    } else if (dCommand.name == "fullscreen") {
      this.execFullscreen(dIbGib);
    } else if (dCommand.name == "link") {
      this.execLink(dIbGib);
    } else if (dCommand.name == "externallink") {
      this.execExternalLink(dIbGib);
    }
  }

  execFork(dIbGib) {
    let init = () => {
      d3.select("#fork_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("fork", init);
    $("#fork_form_data_dest_ib").focus();
  }

  execGoto(dIbGib) {
    location.href = `/ibgib/${dIbGib.ibgib}`
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
      } else if (dIbGib.cat === "identity") {
        text = `This is an identity ibGib. It lets you know who someone is, and you can add layers of identities to be "more secure". If the ib is a long number, then that is an "anonymous" user. Anyone can have their ib be the same, so be sure to check the gib! (It's that long number after the ^ character in the form of 'ibGib_LETTERSandNUMBERS_ibGib')`;
      } else if (dIbGib.cat === "rel8n") {
        text = `This is the '${dIbGib.name}' rel8n node. All of its children are rel8ed to the current ibGib by this rel8n. One ibGib can have multiple rel8ns to any other ibGib. You can expand / collapse the rel8n to show / hide its children by either double-clicking or clicking and selecting the "view" button.`;
      } else if (dIbGib.cat === "pic") {
        text = `This is a picture that you have uploaded! Viewing it in fullscreen will open the image in a new window or tab, depending on your browser preferences. Navigating to it will take you to the pic's ibGib itself.`;
      } else if (dIbGib.cat === "comment") {
        let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
        let commentText = ibHelper.getDataText(ibGibJson);
        text = `This is a comment. It contains text...umm..you can comment on just about anything. This particular comment's text is: "${commentText}"`;
      } else if (dIbGib.cat === "link") {
        let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
        let linkText = ibHelper.getDataText(ibGibJson);
        text = `This is a hyperlink to somewhere outside of ibGib. If you want to navigate to the external link, then choose the open external link command. If you want to goto the link's ibGib, then click the goto navigation.\n\nLink: "${linkText}"`;
      } else {
        text = `This is one of the related ibGib. Click the information button to get more details about it. You can also navigate to it, expand / collapse any children, fork it, merge it, add comments, pictures, links, and more.`;
      }

      $("#ib-help-details-text").text(text);
    };

    this.showDetails("help", init);
  }

  execComment(dIbGib) {
    let init = () => {
      d3.select("#comment_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("comment", init);
    $("#comment_form_data_text").focus();
  }

  execPic(dIbGib) {
    let init = () => {
      d3.select("#pic_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("pic", init);
    $("#pic_form_data_file").focus();
  }

  execFullscreen(dIbGib) {
    let imageUrl =
      this.ibGibImageProvider.getFullImageUrl(dIbGib.ibgib);

    location.href = imageUrl;
  }

  execLink(dIbGib) {
    let init = () => {
      d3.select("#link_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("link", init);
    $("#link_form_data_text").focus();
  }

  execFullscreen(dIbGib) {
    let imageUrl =
      this.ibGibImageProvider.getFullImageUrl(dIbGib.ibgib);

    window.open(imageUrl,'_blank');
    // location.href = imageUrl;
  }

  execExternalLink(dIbGib) {
    let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
    let url = ibHelper.getDataText(ibGibJson);
    if (url) {
      window.open(url,'_blank');
    } else {
      alert("Error opening external link... :-/");
    }
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
        l.active = l.source.visible && l.target.visible;
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
        l.active = l.source.visible && l.target.visible;
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
    delete(this.svgGroup);
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
  getMenuCommandsJson(d) {
    // TODO: ib-scape.js getMenuCommandsJson: When we have client-side dynamicism (prefs, whatever), then we need to change this to take that into account when building the popup menu.
    let commands = [];

    if (d.cat === "rel8n") {
      commands = ["help", "view"];
    } else if (d.ibgib && d.ibgib === "ib^gib") {
      // commands = ["help", "fork", "meta", "query"];
      commands = ["help", "fork", "goto"];
    } else if (d.cat === "ib") {
      // commands = ["pic", "info", "merge", "help", "share", "comment", "star", "fork", "flag", "thumbs up", "query", "meta", "mut8", "link"];
      commands = ["help", "fork", "comment", "pic", "link"];
    } else {
      // commands = ["pic", "info", "merge", "help", "share", "comment", "star", "fork", "flag", "thumbs up", "query", "meta", "mut8", "link", "goto"];
      commands = ["help", "fork", "goto", "comment", "pic", "link"];
    }

    if (d.render && d.render == "image") {
      commands.push("fullscreen");
    }
    if (d.cat === "link") {
      commands.push("externallink");
    }

    let nodes = commands.map(cmdName => d3MenuCommands.filter(cmd => cmd.name == cmdName)[0]);
    return {
      "nodes": nodes
    };
  }
}
