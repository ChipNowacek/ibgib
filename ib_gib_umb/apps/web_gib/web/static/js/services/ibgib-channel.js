// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import { Socket } from "phoenix";

export class IbGibSocketAndChannels {
  constructor(ibIdentityToken, ibAggregateIdentityHash) {
    this.ibIdentityToken = ibIdentityToken;
    this.ibAggregateIdentityHash = ibAggregateIdentityHash;
  }

  connect() {
    if (!this.socket) { this.initSocket(); }
    if (!this.primaryChannel) { this.initPrimaryChannel(); }
  }

  initSocket() {
    console.log('IbGibSocketAndChannels.initSocket')
    let socket = new Socket("/ibgibsocket", {params: {token: this.ibIdentityToken}})
    socket.connect();
    this.socket = socket;
  }

  initPrimaryChannel() {
    // Now that you are connected, you can join channels with a topic:
    // debugger;
    let channel = this.socket.channel(`primary:${this.ibAggregateIdentityHash}`, {});

    // setInterval(() => {
    //   let now = new Date();
    //   let msgName = Math.random() > 0.5 ? "user_cmd" : "user_cmd2";
    //   channel.push(msgName, {body: now.toString()});
    // }, 3000);

    channel.on("user_cmd", payload => {
      console.log(`user_cmd payload: ${JSON.stringify(payload)}`);
    });

    channel.on("user_cmd2", payload => {
      console.log(`user_cmd2 yo payload: ${JSON.stringify(payload)}`);
    });

    channel.join()
      .receive("ok", resp => { console.log("Joined channel successfully", resp) })
      .receive("error", resp => { console.error("Unable to join channel", resp) })

    this.primaryChannel = channel;
  }
}
