import * as d3 from 'd3';
import * as d3text from 'd3-textwrap';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands } from './d3params';
import { IbScapeMenu } from './ib-scape-menu';
import * as ibHelper from './services/ibgib-helper';


export class IbScape {
  constructor(graphDiv, baseJsonPath, ibGibCache, ibGibImageProvider) {
    this.graphDiv = graphDiv;
    this.baseJsonPath = baseJsonPath;
    this.ibGibCache = ibGibCache;
    this.ibGibImageProvider = ibGibImageProvider;
    this.circleRadius = 10;

    this.initWindowResize();

    d3.select("#ib-main-header")
      .classed("ib-hidden", true);
    d3.select("main")
      .style("height", "100% !important")
      .style("width", "100% !important");
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

      let graphNodesAndLinks =
        t.svgGroup
          .selectAll("g.gnode")
          .data(modifiedNodes)
          .enter()
          .append("g")
          .call(d3.drag()
              .on("start", dragstarted)
              .on("drag", dragged)
              .on("end", dragended));

      let graphNodes =
        graphNodesAndLinks
          .append("g")
          .classed('gnode', true)
          .on("click", nodeClicked)
          .on("mousedown", nodeMouseDown)
          .on("touchstart", nodeTouchStart)
          .on("touchend", nodeTouchEnd)
          .attr("cursor", "pointer")
          .on("contextmenu", (d, i)  => { d3.event.preventDefault(); });

      let graphNodeHyperlinks =
        graphNodesAndLinks
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
        graphNodesAndLinks
            .attr("transform", d => 'translate(' + [d.x, d.y] + ')');
      }
    });

    this.menu = new IbScapeMenu(this);
    this.menu.init();

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

    function handleClicked(d) {
      console.log(`node clicked. d: ${JSON.stringify(d)}`);

      if (t.selectedDatum && t.selectedDatum.js_id === d.js_id) {
        t.clearSelectedNode();
      } else {
        t.clearSelectedNode();
        t.selectNode(d);
      }
    }

    function handleDblClicked(d) {
      console.log(`node dblclicked. d: ${JSON.stringify(d)}`);

      delete t.lastMouseDownTime;
      delete t.beforeLastMouseDownTime;

      // We toggle expanding if the node is double clicked.
      if (d.render && d.render === "image") {
        t.execFullscreen(d);
      } else if (d.render && d.render === "text") {
        t.getIbGibJson(d.ibgib, (ibGibJson) => {
          if (ibGibJson.data && ibGibJson.data.text) {
            alert(ibGibJson.data.text);
          }
        });
      } else if (d.ibgib !== "ib^gib") {
        t.clearSelectedNode();

        t.toggleExpandNode(d);
        t.destroyStuff();
        t.update(null);
      }
    }

    function handleLongClicked(d) {
      console.log(`node longclicked. d: ${JSON.stringify(d)}`);
    }

    function handleTouchstartOrMouseDown(d, dIndex, dList) {
      t.beforeLastMouseDownTime = t.lastMouseDownTime || 0;
      t.lastMouseDownTime = new Date();

      setTimeout(() => {
        if (t.lastMouseDownTime && ((t.lastMouseDownTime - t.beforeLastMouseDownTime) < d3DblClickMs)) {
          handleDblClicked(d);
        } else if (t.lastMouseDownTime) {
          handleLongClicked(d);
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
      handleClicked(d);
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
              handleClicked(d);
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

    this.menu.open(d);

    this.selectedDatum = d;
    this.selectedNode = d3.select("#" + d.js_id);
    d3.select("#" + d.js_id)
        .style("opacity", 1)
        .attr("stroke", "yellow")
        .attr("stroke-width", "10px");


    let position = this.getMenuPosition(this.mouseOrTouchPosition || {x: 0, y: 0}, this.targetNode);
    this.menu.moveTo(position);
  }

  toggleFullScreen(elementJquerySelector) {
    let selection = d3.select(elementJquerySelector);
    let node = selection.node();
    let isFullscreen = selection.classed("ib-fullscreen");
    let body = d3.select("body").node();

    if (isFullscreen) {
      // return from fullscreen
      body.removeChild(node);
      this.currentParent.appendChild(node);
      selection
        .classed("ib-fullscreen", false);
    } else {
      // go fullscreen
      this.currentParent = node.parentNode;
      this.currentParent.removeChild(node)
      body.appendChild(node);
      selection
        .classed("ib-fullscreen", true);
    }

    this.destroyStuff();
    this.update(null);
  }

  /**
   * This uses a convention that each details div is named
   * `#ib-${cmdName}-details`. It shows the details div, initializes the
   * specifics to the given cmdName and pops it up. This also takes care of
   * cancelling, which is effected when the user just clicks somewhere else.
   */
  showDetails(cmdName, detailsInitFunction, keepMenuOpen) {
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

    if (keepMenuOpen) {
      // do nothing?
    } else {
      this.tearDownMenu(/*cancelDetails*/ false);
    }
  }

  openImage(ibGib) {
    let imageUrl =
      this.ibGibImageProvider.getFullImageUrl(ibGib);

    window.open(imageUrl,'_blank');
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
    if (this.menu) {
      this.menu.close();
    }

    if (cancelDetails) {
      this.cancelDetails();
    }
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
