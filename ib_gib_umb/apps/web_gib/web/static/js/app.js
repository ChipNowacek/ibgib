// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import { IbGibChannel } from "./socket"

// import { CircleMenu } from "./circlemenu";
// import { IbScape } from "./ibscape-three";
// import { IbScape } from "./ibscape-pixi";

// import { IbScape } from "./ib-scape";
// import { IbScape } from "./dyn-ib-scape";
import { DynamicD3ForceGraph } from "./graphs/dynamic-d3-force-graph";
import { DynamicD3ForceGraph2 } from "./graphs/dynamic-d3-force-graph2";
import { IbGibCache } from "./services/ibgib-cache";
import { IbGibImageProvider } from "./services/ibgib-image-provider";

class App {

  static init(){
    console.warn(`init app. Now: ${Date.now()}`);

    let divIbGibData = document.querySelector("#ibgib-data");
    if (divIbGibData) {
      let ibGibCache = new IbGibCache();
      let ibGibImageProvider = new IbGibImageProvider(ibGibCache);

      // // I'm not sure if these are really useful anymore.
      // let query = divIbGibData.getAttribute("data-metaqueryibgib");
      // let queryResult = divIbGibData.getAttribute("data-metaqueryresultibgib");

      // The server passes the current ibgib via the ibgib attribute.
      let ibgib = divIbGibData.getAttribute("ibgib");

      // This is our base json path that we will use to pull anything down.
      let baseJsonPath = divIbGibData.getAttribute("data-path");
      let baseD3JsonPath = divIbGibData.getAttribute("d3-data-path");

      // Create the ibScape, which is the d3 "landscape" for the ibgib.
      let graphDiv = document.querySelector("#ib-d3-graph-div");

      // this.ibScape = new IbScape(graphDiv, baseJsonPath, ibGibCache, ibGibImageProvider);
      //
      // // We set the ibScape to get its json data
      // let data = baseD3JsonPath + ibgib;
      // this.ibScape.update(data);

      let graph = new DynamicD3ForceGraph(graphDiv, "testSvgId");
      graph.init();

      let graphDiv2 = document.createElement('div');
      let graphDiv2Id = "graphDiv2";
      graphDiv2.id = graphDiv2Id;
      graphDiv2.className = "test-graph-div";
      graphDiv.parentNode.appendChild(graphDiv2);
      let graph2 = new DynamicD3ForceGraph2(graphDiv2, "testSvgId2");
      graph.addChildGraph(graph2, /*shareDataReference*/ false);
      // graph2.init();

      initResize([graph, graph2]);

      setTimeout(() => {
        initNodes(graph);
        // initNodes(graph2);

        let count = 0;
        let interval = setInterval(() => {
          // let targetGraph = Math.random() > 0.5 ? graph : graph2;
          let targetGraph = graph; // testing children

          // console.log("adding from app.js")
          let randomIndex = Math.trunc(Math.random() * targetGraph.graphData.nodes.length);
          let randomNode = targetGraph.graphData.nodes[randomIndex];
          if (randomNode) {
            let randomId = Math.trunc(Math.random() * 100000);
            let newNode = {
              id: randomId,
              name: "server " + randomId,
              shape: Math.random() > 0.5 ? "circle" : "rect",
              // render: Math.random() > 0.1 ? "image" : ""
              render: "image"
            };
            if (randomNode.x) {
              newNode.x = randomNode.x;
              newNode.y = randomNode.y;
            }
            let newLink = {source: randomNode.id, target: randomId};
            targetGraph.add([newNode], [newLink], /*updateParent*/ true, /*updateChildren*/ true);
            count ++;
            if (count % 100 === 0) {
              console.log(`count: ${count}`)
              if (count % 1000 === 0) {
                clearInterval(interval);
              }
            }
          } else {
            // debugger;
            // setTimeout(() => initNodes(), 500);
            console.log("no nodes");
          }
        }, 5);

      }, 500);

      function initNodes(g) {
        let initialCount = 10;
        let nodes = [ {"id": 0, "name": "root node", render: "image", shape: "circle" } ];
        let links = [];
        for (var i = 1; i < initialCount; i++) {
          let randomIndex = Math.trunc(Math.random() * nodes.length);
          let randomNode = nodes[randomIndex];
          let newNode = {
            id: i,
            name: `node ${i}`,
            render: "image",
            shape: Math.random() > 0.5 ? "circle" : "rect"
          };
          let newLink = {source: randomIndex, target: newNode.id};

          nodes.push(newNode);
          links.push(newLink);
        }

        g.add(nodes, links, /*updateParent*/ true, /*updateChildren*/ true);
      }

      function initResize(graphs) {
        window.onresize = () => {
          const debounceMs = 250;

          // hack: apparently no static "properties" in ES6, so putting it on window.
          if (window.resizeTimer) { clearTimeout(window.resizeTimer); }

          window.resizeTimer = setTimeout(() => {
            graphs.forEach(g => g.handleResize());
          }, debounceMs);
        };
      }

      // let nodes = [
      //   {"id": 22, "name": "server 22"},
      //   {"id": 23, "name": "server 23"},
      // ]
      //
      // let links = [
      //   {source: 1, target: 22},
      //   {source: 1, target: 23},
      // ]

      // graph.add(nodes, links);
    }
    // if (!this.ibGibChannel) {
    //   this.ibGibChannel = new IbGibChannel();
    //   this.ibGibChannel.connect();
    // }

    // let socket = new Socket("/socket", {
    //   logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
    // })

    // socket.connect({user_id: "123"})

    // var $status    = $("#status")
    // var $messages  = $("#messages")
    // var $input     = $("#message-input")
    // var $username  = $("#username")
    //
    // socket.onOpen( ev => console.log("OPEN", ev) )
    // socket.onError( ev => console.log("ERROR", ev) )
    // socket.onClose( e => console.log("CLOSE", e))
    //
    // var chan = socket.channel("rooms:lobby", {})
    // chan.join().receive("ignore", () => console.log("auth error"))
    //            .receive("ok", () => console.log("join ok"))
    //            .after(10000, () => console.log("Connection interruption"))
    // chan.onError(e => console.log("something went wrong", e))
    // chan.onClose(e => console.log("channel closed", e))
    //
    // $input.off("keypress").on("keypress", e => {
    //   if (e.keyCode == 13) {
    //     chan.push("new:msg", {user: $username.val(), body: $input.val()})
    //     $input.val("")
    //   }
    // })
    //
    // chan.on("new:msg", msg => {
    //   $messages.append(this.messageTemplate(msg))
    //   scrollTo(0, document.body.scrollHeight)
    // })
    //
    // chan.on("user:entered", msg => {
    //   var username = this.sanitize(msg.user || "anonymous")
    //   $messages.append(`<br/><i>[${username} entered]</i>`)
    // })

  }
}

// Init slider
$(document).ready(function(){
  let counter = 0,
  $items = $('.diy-slideshow figure'),
  numItems = $items.length;

  var showCurrent = function(){
    var itemToShow = Math.abs(counter%numItems);
    $items.removeClass('show');
    $items.eq(itemToShow).addClass('show');
  };

  const intervalMs = 10000;
  setInterval(() => {
    counter++;
    showCurrent();
  }, intervalMs);

  $('.next').on('click', function(){
    counter++;
    showCurrent();
  });

  $('.prev').on('click', function(){
    counter--;
    showCurrent();
  });

  showCurrent();
});

$( () => App.init() )

export default App
