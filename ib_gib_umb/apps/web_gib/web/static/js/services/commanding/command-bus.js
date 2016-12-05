import * as ibHelper from '../ibgib-helper';
import { Socket } from "phoenix";

export class CommandBus {
  constructor(socket) {
    let t = this;

    t.socket = socket;
    // We add a random identifier for this device for handling the same
    // identity on multiple devices.
    t.channelSubtopic = ibHelper.getRandomString() +
                        "_" +
                        t.socket.ibAggregateIdentityHash;
  }

  connect() {
    if (!this.channel) { this.initChannel(); }
  }

  disconnect() {
    let t = this;

    if (t.channel) { t.channel.leave(); delete t.channel; }
  }

  initChannel() {
    let t = this;

    // Now that you are connected, you can join channels with a topic:
    t.channel = t.socket.channel(`command:${t.channelSubTopic}`, {});

    // setInterval(() => {
    //   let now = new Date();
    //   let msgName = Math.random() > 0.5 ? "user_cmd" : "user_cmd2";
    //   channel.push(msgName, {body: now.toString()});
    // }, 3000);

    // channel.on("user_cmd", payload => {
    //   console.log(`user_cmd payload: ${JSON.stringify(payload)}`);
    // });
    //
    // channel.on("user_cmd2", payload => {
    //   console.log(`user_cmd2 yo payload: ${JSON.stringify(payload)}`);
    // });

    t.channel.join()
      .receive("ok", resp => { console.log("Joined command channel successfully", resp) })
      .receive("error", resp => { console.error("Unable to join command channel", resp) })
  }

  send(msg, successCallback, errorCallback) {
    this.channel.push(msg.metadata.name, msg)
      .receive("ok", (successMsg) => {
        if (successCallback) { successCallback(successMsg); }
      })
      .receive("error", (errorMsg) => {
        if (errorCallback) { errorCallback(errorMsg); }
      });
  }
}
