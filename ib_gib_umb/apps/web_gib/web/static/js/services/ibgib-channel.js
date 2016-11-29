// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import { Socket } from "phoenix";

export class IbGibChannel {
  constructor(ibIdentityToken) {
    this.ibIdentityToken = ibIdentityToken;
  }

  connect() {
    if (!this.socket) {
      this.initSocket();
    }

    if (!this.channel) {
      this.initChannel();
    }
  }

  initSocket() {
    console.log('IbGibChannel.initSocket')
    let blah = window.userToken;
    debugger;
    let socket = new Socket("/ibgibsocket", {params: {token: this.ibIdentityToken}})
    socket.connect();
    this.socket = socket;
  }

  initChannel() {
    // Now that you are connected, you can join channels with a topic:
    let channel = this.socket.channel("ibgib:lobby", {});

    setInterval(() => {
      let now = new Date();
      channel.push("new_msg", {body: now.toString()});
    }, 3000);

    channel.on("new_msg", payload => {
      console.log(`new_msg payload: ${JSON.stringify(payload)}`);
    });

    channel.join()
      .receive("ok", resp => { console.log("Joined channel successfully", resp) })
      .receive("error", resp => { console.error("Unable to join channel", resp) })

    this.channel = channel;
  }
}
