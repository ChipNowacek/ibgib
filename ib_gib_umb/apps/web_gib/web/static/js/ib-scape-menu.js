import * as d3 from 'd3';
import * as d3text from 'd3-textwrap';

import { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands } from './d3params';
import * as ibHelper from './services/ibgib-helper';


export class IbScapeMenu {
  constructor(ibScape) {
    this.ibScape = ibScape;

    // These are left over from refactoring. They are for convenience, even
    // though they could be gotten at via the ibScape itself every time.
    this.graphDiv = ibScape.graphDiv;
    this.baseJsonPath = ibScape.baseJsonPath;
    this.ibGibCache = ibScape.ibGibCache;
    this.ibGibImageProvider = ibScape.ibScapeibGibImageProvider;
  }

  init() {
    let t = this;
    this.menuRadius = 120;
    this.menuDiam = 2 * this.menuRadius;
    this.menuDivSize = this.menuDiam;
    this.menuBackgroundColor = "#2B572E";
    this.menuOpacity = 1.0;

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

  open(d) {
    let t = this;
    t.menuButtonRadius = 22;

    t.menuDiv = d3.select("#ib-d3-graph-menu-div");

    t.menuArea =
      t.menuDiv
        .append("svg")
          .attr("id", "ib-d3-graph-menu-area")
          .style("width", t.menuDiam)
          .style("height", t.menuDiam);

    t.menuView =
      t.menuArea.append("circle")
        .attr("width", t.menuDiam)
        .attr("height", t.menuDiam)
        .style("fill", "blue");
        // .style("background-color", "transparent");

    t.svgGroup = t.menuArea
      .append("svg:g")
        .attr("id", "d3menuvis");

    t.menuSimulation = d3.forceSimulation()
        .velocityDecay(0.07)
        .force("x", d3.forceX().strength(0.02))
        .force("y", d3.forceY().strength(0.02))
        .force("center", d3.forceCenter(t.menuRadius, t.menuRadius))
        .force("collide",
               d3.forceCollide().radius(t.menuButtonRadius).iterations(2));

    let graph = t.getMenuCommandsJson(d);

    let graphNodesAndLinks =
      t.svgGroup
        .selectAll("g.gnode")
        .data(graph.nodes)
        .enter()
        .append("g");


    let graphNodes =
      graphNodesAndLinks
        .append("g")
        .classed('gnode', true)
        .on("click", nodeClicked)
        .on("mousedown", nodeMouseDown)
        .on("touchstart", nodeTouchStart)
        .on("touchend", nodeTouchEnd)
        .attr("cursor", "pointer")
        .on("contextmenu", (d, i)  => { d3.event.preventDefault(); })
        ;

    let nodeCircles =
      graphNodes
        .append("circle")
        .attr("class", "nodes")
        .attr("id", d => d.id)
        .attr("r", t.menuButtonRadius)
        .attr("cursor", "pointer")
        .attr("fill", d => d.color);

    nodeCircles
        .append("title")
        .text(d => d.text);

    let nodeTexts =
      graphNodes
        .append("text")
        .attr("font-size", "30px")
        .attr("fill", "#4F6627")
        .attr("text-anchor", "middle")
        .attr("cursor", "pointer")
        .attr("class", "ib-noselect")
        .text(d => d.text)
        .attr('dominant-baseline', 'central')
        .attr('font-family', 'FontAwesome')
        .text(d => d.icon);

    nodeTexts
        .append("title")
        .text(d => `${d.text}: ${d.description}`);

    let menuNodeHyperlinks = graphNodesAndLinks
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
        .on("click", nodeHyperlinkClicked);


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

    function handleTouchstartOrMouseDown(d, dIndex, dList) {
      t.beforeLastMouseDownTime = t.lastMouseDownTime || 0;
      t.lastMouseDownTime = new Date();

      setTimeout(() => {
        if (t.lastMouseDownTime && ((t.lastMouseDownTime - t.beforeLastMouseDownTime) < d3DblClickMs)) {
          delete t.lastMouseDownTime;
          delete t.beforeLastMouseDownTime;

          // We toggle expanding if the node is double clicked.
          handleDblClicked(d);
        } else if (t.lastMouseDownTime) {
          handleLongClicked(d);
        } else {
          // alert("else handletouchor")
        }
      }, d3LongPressMs);
    }

    function handleClicked(d) {
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

      t.executeMenuCommand(t.ibScape.selectedDatum, d);
    }

    function handleDblClicked(d) {
      console.log(`menu node dblclicked. d: ${JSON.stringify(d)}`);
    }

    function handleLongClicked(d) {
      console.log(`menu node longclicked. d: ${JSON.stringify(d)}`);
    }

    function nodeTouchStart(d, dIndex, dList) {
      // alert("touchstart");
      t.isTouch = true;
      t.lastTouchStart = d3.event;
      t.targetNode = d3.event.target;
      let touch = t.lastTouchStart.touches[0];
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
      t.lastMouseDownEvent = d3.event;
      t.targetNode = t.lastMouseDownEvent.target;
      // console.log("nodeMouseDown")
      if (d3.event.button === 0) {
        handleTouchstartOrMouseDown(d, dIndex, dList);
      }
      d3.event.preventDefault();
    }

    function nodeHyperlinkClicked(d) {
      console.log("nodeHyperlinkClicked");
      // This is a hack so that the long-click doesn't get triggered when
      // using vimperator.
      // The intent is just "Hey, this is a fake mousedown so don't long-click."
      t.lastMouseDown = new Date();
      handleClicked(d);
    }

    function nodeClicked(d) {
      // Only handle the click if it's not a double-click.
      if (t.maybeDoubleClicking) {
        // we're double-clicking
        delete t.maybeDoubleClicking;
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

  }

  close() {
    if (this.menuArea) { d3.select("#ib-d3-graph-menu-area").remove();
      delete this.menuArea;
    }
    if (this.svgGroup) { d3.select("#d3menuvis").remove();
      delete this.svgGroup;
    }

    d3.select("#ib-d3-graph-menu-div")
      .style("visibility", "hidden");
  }

  destroyStuff() {
    delete(this.ibScape);
  }

  executeMenuCommand(dIbGib, dCommand) {
    if ((dCommand.name === "view" || dCommand.name === "hide")) {
      this.execView(dIbGib)
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
    } else if (dCommand.name === "refresh") {
      this.execRefresh(dIbGib);
    }
  }

  execView(dIbGib) {
    this.ibScape.toggleExpandNode(dIbGib);
    this.ibScape.destroyStuff();
    this.ibScape.update(null);
  }

  execFork(dIbGib) {
    let init = () => {
      d3.select("#fork_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("fork", init);
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
        text = `ibGib are like ideas. Click an ibGib to view its menu, double-click to expand/collapse it. Click the "Spock Hand" to create a forked ("new") ibGib. Click "login" to identify yourself with your (public) email address. Click "search" to search your existing ibGib. Click the pointer finger to navigate to an ibGib. For more info on ibGib and what you can do with them, see https://github.com/ibgib/ibgib/wiki/Just-What-Exactly-**IS**-an-ibGib-(or-at-least,-how-can-i-use-them)`;
      } else if (dIbGib.cat === "ib") {
        text = `This is your current ibGib. Click the information (i) button to get more details about it. Double-click to expand/collapse any children. Spock hand to fork it, or add comments, pictures, links, and more.`;
      } else if (dIbGib.cat === "ancestor") {
        text = `This is an "ancestor" ibGib, like a parent or grandparent. Each time you "fork" a new ibGib, the src ibGib becomes its ancestor. For example, if you fork a RecipeGib -> WaffleGib, then the WaffleGib becomes a child of the RecipeGib.`
      } else if (dIbGib.cat === "past") {
        text = `This is a "past" version of your current ibGib. A past ibGib kinda like previous versions of a text document, whither you can 'undo'. Each time you mut8 an ibGib, either by adding/removing a comment or image, changing a comment, etc., you create a "new" version in time. ibGib retains all histories of all changes of all ibGib!`
      } else if (dIbGib.cat === "dna") {
        text = `Each ibGib is produced by an internal "dna" code, precisely as living organisms are. Each building block is itself an ibGib that you can navigate to, fork, etc. We can't dynamically build dna yet though (in the future of ibGib!)`;
      } else if (dIbGib.cat === "identity") {
        text = `This is an identity ibGib. It gives you information about who produced what ibGib. You can add layers of identities to "provide more identification", like showing someone your driver's license, your voter's card, club membership, etc. Each identity's ib should start with either "session" or "email". Session is an anonymous id and should be attached to each and every ibGib. Email ids show the email that was used to "log in" (but you can log in with multiple emails!). All authenticated identities should be "stamped" (the "gib" starts and ends with "ibGib", e.g. "ibGib_LETTERSandNUMBERS_ibGib").`;
      } else if (dIbGib.cat === "rel8n") {
        text = `This is a '${dIbGib.name}' rel8n node. All of its children are rel8ed to the current ibGib by this rel8n. One ibGib can have multiple rel8ns to any other ibGib. You can expand / collapse the rel8n to show / hide its children by either double-clicking or clicking and selecting the "view" button. Click help on the children to learn more about that rel8n.`;
      } else if (dIbGib.cat === "pic") {
        text = `This is a picture that you have uploaded! Viewing it in fullscreen will open the image in a new window or tab, depending on your browser preferences. Navigating to it will take you to the pic's ibGib itself. (We're working on an improved experience with adding comments, pictures, etc.)`;
      } else if (dIbGib.cat === "comment") {
        let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
        let commentText = ibHelper.getDataText(ibGibJson);
        text = `This is a comment. It contains text...umm...you can comment on just about anything. (We're working on an improved experience with adding comments, pictures, etc.) This particular comment's text is: "${commentText}"`;
      } else if (dIbGib.cat === "link") {
        let ibGibJson = this.ibGibCache.get(dIbGib.ibgib);
        let linkText = ibHelper.getDataText(ibGibJson);
        text = `This is a hyperlink to somewhere outside of ibGib. If you want to navigate to the external link, then choose the open external link command. If you want to goto the link's ibGib, then click the goto navigation. (We're working on an improved experience with adding comments, pictures, etc.) \n\nLink: "${linkText}"`;
      } else {
        text = `This ibGib is rel8d to the current ibGib via ${dIbGib.cat}. Click the information button to get more details about it. You can also navigate to it, expand / collapse any children, fork it, add comments, pictures, links, and more.`;
      }

      $("#ib-help-details-text").text(text);
    };

    this.ibScape.showDetails("help", init);
  }

  execComment(dIbGib) {
    let init = () => {
      d3.select("#comment_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("comment", init);
    $("#comment_form_data_text").focus();
  }

  execPic(dIbGib) {
    let init = () => {
      d3.select("#pic_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("pic", init);
    $("#pic_form_data_file").focus();
  }

  execLink(dIbGib) {
    let init = () => {
      d3.select("#link_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("link", init);
    $("#link_form_data_text").focus();
  }

  execFullscreen(dIbGib) {
    if (dIbGib.ibgib === "ib^gib") {
      let id = this.graphDiv.id;
      this.ibScape.toggleFullScreen(`#${id}`);
    } else {
      this.ibScape.openImage(dIbGib.ibgib);
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
    this.ibScape.showDetails("ident", init);
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

      t.ibScape.getIbGibJson(dIbGib.ibgib, ibGibJson => {

        let text = JSON.stringify(ibGibJson, null, 2);
        // Formats new lines in json.data values. It's still a hack just
        // showing the JSON but it's an improvement.
        // Thanks SO (for the implementation sort of) http://stackoverflow.com/questions/42068/how-do-i-handle-newlines-in-json
        text = text.replace(/\\n/g, "\n").replace(/\\r/g, "").replace(/\\t/g, "\t");
        container
          .append("pre")
          .text(text);

        t.ibScape.repositionDetails();
      });
    };
    this.ibScape.showDetails("info", init);
  }

  execQuery(dIbGib) {
    let init = () => {
      d3.select("#query_form_data_src_ib_gib")
        .attr("value", dIbGib.ibgib);
    };
    this.ibScape.showDetails("query", init);
    $("#query_form_data_search_ib").focus();
  }

  execRefresh(dIbGib) {
    location.href = `/ibgib/${dIbGib.ibgib}?latest=true`
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
      commands = ["help", "fork", "goto", "identemail", "fullscreen", "query"];
    } else if (d.cat === "ib") {
      commands = ["help", "view", "fork", "comment", "pic", "link", "info", "refresh"];
    } else {
      commands = ["help", "view", "fork", "goto", "comment", "pic", "link", "info", "refresh"];
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

  moveTo(position) {
    let transition =
      d3.transition()
        .duration(150)
        .ease(d3.easeLinear);
    d3.select("#ib-d3-graph-menu-div")
      .transition(transition)
        .style("left", position.x + "px")
        .style("top", position.y + "px")
        .style("visibility", null)
        .attr("z-index", 1000);
  }
}
