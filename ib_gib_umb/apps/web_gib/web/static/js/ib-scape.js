import * as d3 from 'd3';
import * as d3text from 'd3-textwrap';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands } from './d3params';
import * as ibHelper from './services/ibgib-helper';


export class IbScape {
  constructor(graphDiv, baseJsonPath, ibGibCache, ibGibImageProvider) {
    this.graphDiv = graphDiv;
    this.baseJsonPath = baseJsonPath;
    this.ibGibCache = ibGibCache;
    this.ibGibImageProvider = ibGibImageProvider;
    this.circleRadius = 10;

    this.initWindowResize();
  }

  initWindowResize() {
    let t = this;
    window.onresize = () => {
      const debounceMs = 250;

      if (t.resizeTimer) { clearTimeout(t.resizeTimer); }

      t.resizeTimer = setTimeout(() => {
        // For some reason, when resizing vertically, it doesn't always trigger
        // the graph itself to change sizes. So we're checking the parent.
        let nowWidth = t.graphDiv.parentNode.scrollWidth;
        let nowHeight = t.graphDiv.parentNode.scrollHeight;
        if (nowWidth !== t.parentWidth || nowHeight !== t.parentHeight) {
          t.destroyStuff();
          t.update(null);
        }

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
    // console.log(`width, height: ${t.width}, ${t.height}`);

    // For some reason, when resizing vertically, it doesn't always trigger
    // the graph itself to change sizes. So we're checking the parent.
    t.parentWidth = t.graphDiv.parentNode.scrollWidth;
    t.parentHeight = t.graphDiv.parentNode.scrollHeight;
    // console.log(`parent width, parent height: ${t.parentWidth}, ${t.parentHeight}`);

    t.repositionDetails();

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
      t.ibNode = null;
      t.rawData = graph;
      if (!t.workingData) {
        let hiddenNodeIds = [];
        graph.nodes.forEach(n => {
          if (n.cat === "ib") {
            t.ibNode = n;
            n.expandLevel = 1;
            n.collapsed = true;
            n.visible = true;
          } else if (n.cat === "ibGib") {
            n.collapsed = true;
            n.visible = true;
          } else {
            n.collapsed = true;
            n.visible = false;
          }
        });

        graph.links.forEach(l => {
          l.active = false;
        });

        graph.links.
          filter(l => l.source === t.ibNode.id &&
                      !d3RequireExpandLevel2.some(r => r === l.target)).
          forEach(l => {
            let node = graph.nodes.filter(n => n.id === l.target)[0];
            if (node) {
              node.visible = true;
              node.collapsed = false;
              l.active = true;

              // debugger;
              let subLinks = graph.links.filter(sl => {
                // debugger;
                return sl.source === l.target;
              });
              subLinks.forEach(sl => {
                let subnode = graph.nodes.filter(n => n.id === sl.target)[0];
                subnode.visible = true;
                subnode.collapsed = true;
                sl.active = true;
              });
            }
        });

        t.ibNode.collapsed = false;

        t.workingData = graph;

        // At this point, these graph nodes and links do not have the same
        // structure as later.
        // t.expandNode(ibNode);
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

      let pressTimer;

      let graphNodes = svgGroup
          .selectAll("g.gnode")
          .data(modifiedNodes)
          .enter()
          .append("g")
          .classed('gnode', true)
          .on("click", nodeClicked)
          .on("mousedown", nodeMouseDown)
          .on("touchstart", nodeTouchStart)
          .on("touchend", nodeTouchEnd)
          .attr("cursor", "pointer")
          .on("contextmenu", (d, i)  => { d3.event.preventDefault(); })
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
          .on("click", nodeHyperlinkClicked);

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
          .attr("fill", getColor);

      graphNodeCircles.append("title")
          .text(getNodeTitle);

      let graphNodeLabels = graphNodes
          .append("g")
          .attr("id", d => "label_" + d.js_id)
          .text(getNodeLabel);

      let graphNodeImages = graphNodes
          .append("image")
          .attr("id", d => "img_" + d.js_id)
          .attr("opacity", 0.1)
          .attr("xlink:href", getNodeImage)
          .attr("x", -8)
          .attr("y", -8)
          .attr("width", 16)
          .attr("height", 16);

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
      } else if (d.render && d.render === "text") {
        index = "text";
      } else if (d.render && d.render === "image") {
        index = "image";
      } else if (d.cat === "rel8n") {
        index = d.id;
      }
      return d3Colors[index] || d3Colors["default"];
    }

    function backgroundClicked(d) {
      console.log("background clicked");
      // alert("background clicked")

      t.clearSelectedNode();

      d3.select("#ib-d3-graph-menu-div")
        .style("left", t.center.x + "px")
        .style("top", t.center.y + "px")
        .style("visibility", "hidden")
        .attr("z-index", -1);

      d3.event.preventDefault();
    }

    function handleTouchstartOrMouseDown(d, dIndex, dList) {
      t.beforeLastMouseDownTime = t.lastMouseDownTime || 0;
      t.lastMouseDownTime = new Date();

      setTimeout(() => {
        if (t.lastMouseDownTime && ((t.lastMouseDownTime - t.beforeLastMouseDownTime) < d3DblClickMs)) {
          delete t.lastMouseDownTime;
          delete t.beforeLastMouseDownTime;

          // We toggle expanding if the node is double clicked.
          if (d.ibgib !== "ib^gib") {
            t.clearSelectedNode();

            t.toggleExpandNode(d);
            t.destroyStuff();
            t.update(null);
          }
        } else if (t.lastMouseDownTime) {
          console.log("long click handler here");
        } else {
          // alert("else handletouchor")
        }
      }, d3LongPressMs);
    }

    function nodeTouchStart(d, dIndex, dList) {
      // alert("touchstart");
      t.isTouch = true;
      t.lastTouchStart = d3.event;
      t.targetNode = d3.event.target;
      let touch = t.lastTouchStart.touches[0];
      // debugger;
      t.mouseOrTouchPosition = [touch.clientX, touch.clientY];
      // alert(`pos: ${t.mouseOrTouchPosition}`)
      handleTouchstartOrMouseDown(d, dIndex, dList);
      d3.event.preventDefault();
    }

    function nodeTouchEnd(d, dIndex, dList) {
      // debugger;
      t.lastTouchEnd = d3.event;
      let elapsedMs = new Date() - t.lastMouseDownTime;
      if (elapsedMs < d3LongPressMs) { nodeClicked(d); }
    }

    function nodeMouseDown(d, dIndex, dList) {
      t.isTouch = false;
      t.mouseOrTouchPosition = d3.mouse(t.view.node());
      t.lastMouseDownEvent = d3.event;
      t.targetNode = t.lastMouseDownEvent.target;
      // console.log("nodeMouseDown")
      if (d3.event.button === 0) {
        handleTouchstartOrMouseDown(d, dIndex, dList);
      }
      d3.event.preventDefault();
    }

    function nodeHyperlinkClicked(d) {
      // This is a hack so that the long-click doesn't get triggered when
      // using vimperator.
      // The intent is just "Hey, this is a fake mousedown so don't long-click."
      t.lastMouseDown = new Date();
      nodeClicked(d);
    }

    function nodeClicked(d) {
      // console.log(`nodeClicked: ${JSON.stringify(d)}`);
      // alert("nodeClicked");

      // Only handle the click if it's not a double-click.
      // on refactor, I should seriously consider doing rx or hammer handlers.
      if (t.maybeDoubleClicking) {
        // we're double-clicking
        delete t.maybeDoubleClicking;
        delete t.mouseOrTouchPosition;
        delete t.targetNode;
      } else {
        t.maybeDoubleClicking = true;

        setTimeout(() => {
          if (t.maybeDoubleClicking) {
            // Not double-clicking, so handle click
            let now = new Date();
            let elapsedMs = now - t.lastMouseDownTime;
            // alert("nodeclicked maybe")
            delete t.lastMouseDownTime;
            if (elapsedMs < d3LongPressMs) {
              // normal click
              if (t.selectedDatum && t.selectedDatum.js_id === d.js_id) {
                t.clearSelectedNode();
              } else {
                t.clearSelectedNode();
                t.selectNode(d);
              }
            } else {
              // long click, handled already in mousedown handler.
              console.log("long click, already handled. no click handler.");
            }

            delete t.maybeDoubleClicking;
          }
        }, d3DblClickMs);
      }
    }

    function dragstarted(d) {
      if (!d3.event.active) simulation.alphaTarget(0.3).restart();
      d.fx = d.x;
      d.fy = d.y;

      t.x0 = d3.event.x;
      t.y0 = d3.event.y;
    }

    function dragged(d) {
      d.fx = d3.event.x;
      d.fy = d3.event.y;

      let dist = Math.sqrt(Math.pow(t.x0 - d.fx, 2) + Math.pow(t.y0 - d.fy, 2));
      if (dist > 2.5) {
        // alert(`dist: ${dist}`)
        delete t.lastMouseDownTime;
        t.x0 = null;
        t.y0 = null;
      }
    }

    function dragended(d) {
      // console.log("dragended")
      if (!d3.event.active) simulation.alphaTarget(0);

      let dist = Math.sqrt(Math.pow(t.x0 - d.fx, 2) + Math.pow(t.y0 - d.fy, 2));

      d.fx = d3.event.x;
      d.fy = d3.event.y;

      d.fx = null;
      d.fy = null;
      // alert("deleting fx0")
      t.x0 = null;
      t.y0 = null;
    }

    function getNodeTitle(d) {
      if (d.render === "text" || d.render === "link") {
        t.getIbGibJson(d.ibgib, (ibGibJson) => {
          setTimeout(() => updateLabelText(d, ibGibJson), 100);
        });
        return "...";
      } else {
        // Label gets no text because it's not rendered as text.
        if (d.ibgib === "ib^gib") {
          return "root ib^gib";
        } else {
          return d.id;
        }
      }
    }

    function getNodeLabel(d) {
      if (d.render === "text" || d.render === "link") {
        t.getIbGibJson(d.ibgib, (ibGibJson) => {
          setTimeout(() => updateLabelText(d, ibGibJson), 100);
        });
        return "...";
      } else if (d.render === "image") {
        return "";
      } else if (d.ibgib === "ib^gib") {
        return "";
      } else if (d.cat === "rel8n") {
        return "";
      } else {
        t.getIbGibJson(d.ibgib, (ibGibJson) => {
          setTimeout(() => updateLabelText(d, ibGibJson), 100);
        });
      }
    }

    function updateLabelText(d, ibGibJson) {

      let labelText = "?";
      if (ibGibJson && ibGibJson.data && ibGibJson.data.text) {
        labelText = ibGibJson.data.text;
      } else if (ibGibJson && ibGibJson.data && ibGibJson.data.label) {
        labelText = ibGibJson.data.label;
      } else if (ibGibJson && ibGibJson.data && ibGibJson.data.title) {
        labelText = ibGibJson.data.title;
      } else if (ibGibJson && ibGibJson.ib) {
        labelText = ibGibJson.ib;
      }

      let label = d3.select("#label_" + d.js_id)

      let fontSize = 0;
      let lines = [];
      if (labelText.length < 10) {
        lines = labelText.match(/.{1,10}/g);
        fontSize = 10;
      } else if (labelText.length < 20) {
        lines = labelText.match(/.{1,12}/g);
        fontSize = 8;
      } else if (labelText.length < 40) {
        lines = labelText.match(/.{1,15}/g);
        fontSize = 7;
      } else if (labelText.length < 90) {
        lines = labelText.match(/.{1,18}/g);
        fontSize = 6;
      } else {
        lines = labelText.match(/.{1,24}/g);
        fontSize = 5;
      }

      for (let i = 0; i < lines.length; i++) {
        let offset = fontSize * Math.trunc(lines.length / 2);
        let lineText = lines[i];
        let y = (i * fontSize) - offset;
        label
          .append("text")
          .attr("font-size", `${fontSize}px`)
          .attr("text-anchor", "middle")
          .text(lineText)
          .attr("y", y)
          .select('title')
          .text(labelText)
          .attr("text-anchor", "middle");
      }


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
            t.ibGibImageProvider.getThumbnailImageUrl(d.ibgib, ibGibJson);
          makeImageNode(d, ibGibJson, imageUrl);
        } else {
          d3.json(t.baseJsonPath + d.ibgib, ibGibJson => {
            t.ibGibCache.add(ibGibJson);

            let imageUrl = t.ibGibImageProvider.getThumbnailImageUrl(d.ibgib, ibGibJson);

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
      let imagePattern = t.graphImageDefs
        .append("pattern")
        .attr("id", patternId)
        // height/width seems to have a tiling effect if set to a fraction
        .attr("height", 1)
        .attr("width", 1)
        .attr("x", 0)
        .attr("y", 0);

      // This has to do with how to size the image.
      // I have the images thumbnails to 300x300 ATOW (2016/10/16), so
      // this is actually scaling down a bit, but we can zoom in svgs.
      // I'm not sure what the magic offset is, but it works.
      let magicSize = 75;
      let magicOffset = -7.5;

      // background fill color
      imagePattern
        .append("circle")
        .attr("r", getRadius)
        .attr("fill", d3Colors.pic)
        .attr("cx", d => { return getRadius(d) + magicOffset; })
        .attr("cy", d => { return getRadius(d) + magicOffset; });

      // pic
      imagePattern
        .append("image")
        .attr("height", magicSize)
        .attr("width", magicSize)
        .attr("x", magicOffset)
        .attr("y", magicOffset)
        .attr("xlink:href", imageUrl);

      let label = ibGibJson.data.filename;
      d3.select("#img_" + d.js_id)
        .remove();

      d3.select("#label_" + d.js_id)
        .text("")
        // .call(t.wrap)
        .select('title')
        .text(label);

      d3.select("#" + d.js_id)
        .attr("fill", `url(#${patternId})`)
        .select('title')
        .text(label);
    }

    function getLinkDistance(l) {
      if (["comment", "pic", "link"].some(x => x === l.target.id)) {
        return d3LinkDistances["special"];
      } else if (["comment", "pic", "link"].some(x => x === l.target.cat)) {
        return d3LinkDistances["specialMember"];
      } else if (l.target.cat === "rel8n") {
        return d3LinkDistances["rel8n"];
      } else {
        return d3LinkDistances["default"];
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
    d3.select("#" + d.js_id)
        .style("opacity", 1)
        .attr("stroke", "yellow")
        .attr("stroke-width", "10px");

    let transition =
      d3.transition()
        .duration(150)
        .ease(d3.easeLinear);

    let position = this.getMenuPosition(this.mouseOrTouchPosition, this.targetNode);
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
    if ((dCommand.name === "view" || dCommand.name === "hide")) {
      this.toggleExpandNode(dIbGib);
      this.destroyStuff();
      this.update(null);
    } else if (dCommand.name === "fork") {
      this.execFork(dIbGib)
    } else if (dCommand.name === "goto") {
      this.execGoto(dIbGib);
    } else if (dCommand.name === "help") {
      this.execHelp(dIbGib);
    } else if (dCommand.name === "comment") {
      this.execComment(dIbGib);
    } else if (dCommand.name === "pic") {
      this.execPic(dIbGib);
    } else if (dCommand.name === "fullscreen") {
      this.execFullscreen(dIbGib);
    } else if (dCommand.name === "link") {
      this.execLink(dIbGib);
    } else if (dCommand.name === "externallink") {
      this.execExternalLink(dIbGib);
    } else if (dCommand.name === "identemail") {
      this.execIdentEmail(dIbGib);
    } else if (dCommand.name === "info") {
      this.execInfo(dIbGib);
    } else if (dCommand.name === "query") {
      this.execQuery(dIbGib);
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
        text = `Double-click to expand an ibGib, single-click to view its menu. Click the Spock Hand to fork into a "new" ibGib. Click login to identify yourself with your (public) email address. Click search to search your existing ibGib. Click the pointer finger to navigate to an ibGib.`;
      } else if (dIbGib.cat === "ib") {
        text = `This is your current ibGib. Click the information button to get more details about it. You can expand / collapse any children, fork it, merge it, add comments, pictures, links, and more.`;
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

  execLink(dIbGib) {
    let init = () => {
      d3.select("#link_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("link", init);
    $("#link_form_data_text").focus();
  }

  execFullscreen(dIbGib) {
    if (dIbGib.ibgib === "ib^gib") {
      let id = this.graphDiv.id;
      this.toggleFullScreen(`#${id}`);
    } else {
      let imageUrl =
        this.ibGibImageProvider.getFullImageUrl(dIbGib.ibgib);

      window.open(imageUrl,'_blank');
    }
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

  execIdentEmail(dIbGib) {
    let init = () => {
      d3.select("#ident_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("ident", init);
    $("#ident_form_data_text").focus();
  }

  execInfo(dIbGib) {
    let t = this;
    let init = () => {
      d3.select("#info_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);

      let container = d3.select("#ib-info-details-container");
      container.each(function() {
        while (this.firstChild) {
          this.removeChild(this.firstChild);
        }
      });

      t.getIbGibJson(dIbGib.ibgib, ibGibJson => {

        let text = JSON.stringify(ibGibJson.data, null, 2);
        // Formats new lines in json.data values. It's still a hack just
        // showing the JSON but it's an improvement.
        // Thanks SO (for the implementation sort of) http://stackoverflow.com/questions/42068/how-do-i-handle-newlines-in-json
        text = text.replace(/\\n/g, "\n").replace(/\\r/g, "").replace(/\\t/g, "\t");
        container
          .append("pre")
          .text(text);

        t.repositionDetails();
      });
    };
    this.showDetails("info", init);
  }

  execQuery(dIbGib) {
    let init = () => {
      d3.select("#query_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.showDetails("query", init);
    $("#query_form_data_search_ib").focus();
  }

  toggleFullScreen(elementJquerySelector) {
    // if already full screen; exit
    // else go fullscreen
    if (
      document.fullscreenElement ||
      document.webkitFullscreenElement ||
      document.mozFullScreenElement ||
      document.msFullscreenElement
    ) {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
      } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
      } else if (document.msExitFullscreen) {
        document.msExitFullscreen();
      }
    } else {
      let element = $(elementJquerySelector).get(0);
      if (element.requestFullscreen) {
        element.requestFullscreen();
      } else if (element.mozRequestFullScreen) {
        element.mozRequestFullScreen();
      } else if (element.webkitRequestFullscreen) {
        element.webkitRequestFullscreen(Element.ALLOW_KEYBOARD_INPUT);
      } else if (element.msRequestFullscreen) {
        element.msRequestFullscreen();
      }
    }
  }

  /**
   * This uses a convention that each details div is named
   * `#ib-${cmdName}-details`. It shows the details div, initializes the
   * specifics to the given cmdName and pops it up. This also takes care of
   * cancelling, which is effected when the user just clicks somewhere else.
   */
  showDetails(cmdName, detailsInitFunction) {
    this.ibScapeDetails =
      d3.select("#ib-scape-details")
        .attr("class", "ib-pos-abs ib-info-border");

    this.details =
      d3.select(`#ib-${cmdName}-details`)
        .attr("class", "ib-details-on");

    this.repositionDetails();

    if (detailsInitFunction) {
      detailsInitFunction();
    }

    this.tearDownMenu(/*cancelDetails*/ false);
  }

  /** Manually checks to see if height > width. */
  getIsPortrait() {
    return this.rect.height > this.rect.width;
  }

  /** Positions the details modal view, e.g. comment text, info details, etc. */
  repositionDetails() {
    if (this.details && this.ibScapeDetails) {
      // Position the details based on its size.
      let ibScapeDetailsDiv = this.ibScapeDetails.node();
      let detailsRect = ibScapeDetailsDiv.getBoundingClientRect();
      ibScapeDetailsDiv.style.position = "absolute";


      // Relative to top left corner of the graph, move up and left half
      // of the details height/width.
      ibScapeDetailsDiv.style.left = (this.rect.left + this.center.x - (detailsRect.width / 2)) + "px";

      // Special handling for the top, because virtual keyboards on mobile
      // devices take up real estate and it's not worth it to check for
      // keyboard manually. Just have the top of the details higher than center.
      let topOffset = this.getIsPortrait() ? this.rect.height / 5 : 20;
      ibScapeDetailsDiv.style.top = (this.rect.top + topOffset) + "px";
    }
  }

  /** Closes the details modal view. */
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

  collapseNode(d) {
    let runningList = [];
    let recursive = true; // Collapse **all** children
    let nodeChildren = this.getNodeChildren(d, recursive, runningList);
    nodeChildren.forEach(nodeChild => {
      nodeChild.collapsed = true;
      nodeChild.visible = false;
    });

    d.collapsed = true;

    // activate links
    this.workingData.links.forEach(l => {
      // debugger;

      l.active = l.source.visible && l.target.visible;
    });
  }

  expandNode(d) {
    let runningList = [];
    let recursive = false; // Expand **only direct** children
    let nodeChildren = this.getNodeChildren(d, recursive, runningList);
    nodeChildren.forEach(nodeChild => {
      let shouldShowChild = this.getShouldShowChild(d, nodeChild);
      nodeChild.visible = shouldShowChild;

      let shouldExpandChild = nodeChild.cat === "rel8n" ?
        d3DefaultCollapsed.some(r => r === nodeChild.id) :
        d3DefaultCollapsed.some(r => r === nodeChild.cat);
      if (shouldExpandChild) {
        nodeChild.collapsed = true;
      } else {
        this.expandNode(nodeChild);
      }
    });
    d.collapsed = false;

    // activate links
    this.workingData.links.forEach(l => {
      // debugger;

      l.active = l.source.visible && l.target.visible;
    });
  }

  getShouldShowChild(d, nodeChild) {
    if (d.cat !== "ib") {
      return true;
    } else if (d.expandLevel === 2) {
      return true;
    } else if (d.expandLevel === 1) {
      // Determine if the nodeChild should be collapsed or not.
      // This whole thing is hacky!
      // The gist is that if it's in the require expand level 2, then
      // dont show it unless we're at level 2. Right now, we're at level 1.
      if (nodeChild.cat === "rel8n") {
        return !d3RequireExpandLevel2.some(r => r === nodeChild.id);
      } else {
        return !d3RequireExpandLevel2.some(r => r === nodeChild.cat);
      }
    } else {
      console.warn("unknown expand level");
      return true;
    }
  }

  getNodeChildren(d, recursive, runningList) {
    let t = this;
    let directChildren =
      t.workingData.links.
        filter(l => l.source.js_id === d.js_id).
        map(l => l.target);

    if (recursive && directChildren.length > 0) {
      let allChildren = [].concat(directChildren);
      runningList.push(d.js_id);

      allChildren = directChildren.reduce((agg, item) => {
        if (runningList.some(x => item.js_id === x)) {
          // Don't call recursively because this item has already be processed.
          return agg;
        } else {
          // Item has not been processed yet, so call recursively.
          runningList.push(item.js_id);
          return agg.concat(t.getNodeChildren(item, recursive, runningList));
        }
      }, allChildren);

      return allChildren;
    } else {
      return directChildren;
    }
  }

  toggleExpandNode(d) {
    // debugger;
    let recursive = false;
    let nodeChildren = this.getNodeChildren(d, recursive, []);

    if ((d.collapsed || d.collapsed === undefined) && nodeChildren.length > 0) {
      d.expandLevel = 1;
      this.expandNode(d);
    } else if (d.expandLevel === 1 && d.cat === "ib") {
      d.expandLevel = 2;
      this.expandNode(d);
    } else {
      d.expandLevel = 0;
      this.collapseNode(d);
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

  getMenuPosition(mouseOrTouchPosition, targetNode) {
    // Start our position away from right where we click.

    // let bufferAwayFromClickPoint = this.menuRadius;
    let bufferAwayFromClickPoint = 30; //magic number :-/
    let $graphDivPos = $(`#${this.graphDiv.id}`).position();

    let mousePosIsOnLeftSide = mouseOrTouchPosition[0] < this.width/2;
    let x = mousePosIsOnLeftSide ?
            $graphDivPos.left + mouseOrTouchPosition[0] + bufferAwayFromClickPoint :
            $graphDivPos.left + mouseOrTouchPosition[0] - this.menuDiam;
    if (x < $graphDivPos.left) { x = $graphDivPos.left; }
    if (x > $graphDivPos.left + this.width - this.menuDiam) {
      x = $graphDivPos.left + this.width - this.menuDiam;
    }

    let mousePosIsInTopHalf = mouseOrTouchPosition[1] < (this.height/2);
    let y = mousePosIsInTopHalf ?
            $graphDivPos.top + mouseOrTouchPosition[1] + bufferAwayFromClickPoint :
            $graphDivPos.top + mouseOrTouchPosition[1] - this.menuDiam;
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
    this.menuOpacity = 0.9;

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
      commands = ["help", "fork", "goto", "identemail", "fullscreen", "query"];
    } else if (d.cat === "ib") {
      // commands = ["pic", "info", "merge", "help", "share", "comment", "star", "fork", "flag", "thumbs up", "query", "meta", "mut8", "link"];
      commands = ["help", "view", "fork", "comment", "pic", "link", "info"];
    } else {
      // commands = ["pic", "info", "merge", "help", "share", "comment", "star", "fork", "flag", "thumbs up", "query", "meta", "mut8", "link", "goto"];
      commands = ["help", "view", "fork", "goto", "comment", "pic", "link", "info"];
    }

    if (d.render && d.render === "image") {
      commands.push("fullscreen");
    }
    if (d.cat === "link") {
      commands.push("externallink");
    }

    let nodes = commands.map(cmdName => d3MenuCommands.filter(cmd => cmd.name === cmdName)[0]);
    return {
      "nodes": nodes
    };
  }

  getIbGibJson(ibgib, callback) {
    let ibGibJson = this.ibGibCache.get(ibgib);
    if (ibGibJson) {
      if (callback) { callback(ibGibJson); }
    } else {
      // We don't yet have the json for this particular data.
      // So we need to load the json, and when it returns we will exec callback.
      d3.json(this.baseJsonPath + ibgib, ibGibJson => {
        this.ibGibCache.add(ibGibJson);

        if (callback) { callback(ibGibJson); }
      });
    }
  }
}
