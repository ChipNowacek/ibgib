// // NOTE: The contents of this file will only be executed if
// // you uncomment its entry in "web/static/js/app.js".
//
// // To use Phoenix channels, the first step is to import Socket
// // and connect at the socket path in "lib/my_app/endpoint.ex":
// import {Socket} from "phoenix"
//
// export class IbGibChannel {
//   constructor() {
//   }
//
//   connect() {
//     if (!this.socket) {
//       this.initSocket();
//     }
//
//     if (!this.channel) {
//       this.initChannel();
//     }
//   }
//
//   initSocket() {
//     let socket = new Socket("/ibgibsocket", {params: {token: window.userToken}})
//     socket.connect();
//     this.socket = socket;
//   }
//
//   initChannel() {
//     // Now that you are connected, you can join channels with a topic:
//     let channel           = this.socket.channel("ibgib:lobby", {});
//     let chatInput         = $("#chat-input");
//     let messagesContainer = $("#messages");
//
//     chatInput.on("keypress", event => {
//       const ENTER_KEY = 13;
//       if (event.keyCode === ENTER_KEY) {
//         channel.push("new_msg", {body: chatInput.val()});
//         chatInput.val("");
//       }
//     });
//
//
//     channel.on("new_msg", payload => {
//       messagesContainer.append(`<br/>[${Date()}] ${payload.body}`);
//     });
//
//     channel.join()
//       .receive("ok", resp => { console.log("Joined channel successfully", resp) })
//       .receive("error", resp => { console.error("Unable to join channel", resp) })
//
//     this.channel = channel;
//   }
//
//
// }
