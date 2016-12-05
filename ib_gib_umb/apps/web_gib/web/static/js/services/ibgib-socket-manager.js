// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import { Socket } from "phoenix";

export class IbGibSocketManager {
  constructor(ibIdentityToken, ibAggregateIdentityHash) {
    this.ibIdentityToken = ibIdentityToken;
    this.ibAggregateIdentityHash = ibAggregateIdentityHash;
  }

  connect() {
    if (!this.socket) { this.initSocket(); }
  }

  initSocket() {
    console.log('IbGibSocketManager.initSocket')
    let socket = new Socket("/ibgibsocket", {params: {token: this.ibIdentityToken}})
    socket.connect();
    this.socket = socket;
  }
}
