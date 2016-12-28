import * as ibHelper from './ibgib-helper';
import { Socket } from "phoenix";

export class IbGibEventBus {
  constructor(socket, ibGibProvider) {
    let t = this;

    t.socket = socket;
    t.connectionInfos = [];
    t.ibGibProvider = ibGibProvider;
  }

  /**
   * Creates a new connection info for the given `ibGib`.
   * When a msg is published on the bus for the given `ibGib`, then all
   * `handleMsgFunc` are called that are subscribed to that `ibGib`.
   *
   * The `connectionId` is used for uniquely identifying the subscriber.
   * If connectionId already exists, then does NOT create a new connection and
   * reuses the existing one.
   */
  connect(connectionId, ibGib, handleMsgFunc) {
    let t = this;

    if (ibGib === "ib^gib") {
      debugger;
    }
    if (ibGib && handleMsgFunc) {
      // If connectionId already exists, then return immediately.
      if (t.connectionInfos.some(info => info.connId === connectionId)) {
        console.warn(`Already connected with id ${connectionId} to ibGib ${ibGib}. handleMsgFunc is ignored (should be connecting with a different connectionId if truly a different connection.)`);

        return -1;
      }

      // Search existing infos for same ibGib. Reuse channel if exists.
      let channel;
      let existingInfos =
        t.connectionInfos.filter(info => info.ibGib === ibGib);
      if (existingInfos.length === 0) {
        console.log(`connecting to ibGib channel: ${ibGib}`)
        channel = t.initChannel(ibGib);
      } else {
        // console.log(`already connected to ibGib channel: ${ibGib}`)
        channel = existingInfos[0].channel;
      }

      // Create the connection info
      let connectionInfo = {
        connectionId: connectionId || ibHelper.getRandomString(),
        ibGib: ibGib,
        channel: channel,
        handler: handleMsgFunc
      }

      t.connectionInfos.push(connectionInfo);

      return connectionInfo.connectionId;
    } else {
      // No ibGib given.
      console.error(`EventBus.connect requires a valid ibGib and handleMsgFunc.`);
      return -1;
    }
  }

  /** Creates and joins a channel for the given ibGib. */
  initChannel(ibGib) {
    let t = this;

    let topic = `event:${ibGib}`;
    let channel = t.socket.channel(topic, {});

    channel.join()
      .receive("ok", resp => {
        console.log(`Joined event bus channel successfully.`, `topic: ${topic}}`, JSON.stringify(resp));
      })
      .receive("error", resp => {
        console.error(`Unable to join event bus channel. topic: ${topic}`, JSON.stringify(resp));
      })

    channel.on("update", msg => t.handleMsg(ibGib, msg));
    channel.on("adjuncts", msg => t.handleMsg(ibGib, msg));
    channel.on("new_adjunct", msg => t.handleMsg(ibGib, msg));

    return channel;
  }

  handleMsg(ibGib, msg) {
    let t = this;
    t.connectionInfos
      .filter(info => info.ibGib === ibGib)
      .forEach(info => info.handler(msg));
  }

  /**
   * Reference counted leaving channels for given `connectionId`.
   *
   * If when disconnecting `connectionId` there are no more references to the
   * associated `ibGib`, then will leave the phoenix channel proper.
   *
   * If `connectionId` is not given, then this will leave ALL channels and
   * clear out all connection infos.
   */
  disconnect(connectionId) {
    let t = this;

    if (connectionId) {
      let connectionInfo = t.connectionInfos.filter(info => info.connectionId === connectionId)[0];

      // If we don't have a corresponding info, then log & immediately return.
      if (!connectionInfo) {
        console.error(`EventBus.disconnect(${connectionId}) called, but no connections associated to this id.`);
        return;
      }

      // Go ahead and splice off the connectionInfo.
      let indexToRemove = t.connectionInfos.indexOf(connectionInfo);
      t.connectionInfos.splice(indexToRemove, 1);

      // Check for other existingInfos to determine if we leave the channel.
      // Only leave the channel if this connectionId is the last reference.
      let existingInfos = t.connectionInfos.filter(info => info.ibGib === connectionInfo.ibGib);
      if (existingInfos.length === 0) {
        if (connectionInfo) {
          console.log(`Disconnecting connectionId ${connectionId}. Leaving channel for ibGib: ${connectionInfo.ibGib}`);
          connectionInfo.channel.leave();
        } else {
          debugger;
        }
      }
    } else {
      // disconnect from all channels.
      let uniqueChannels = {};
      t.connectionInfos.forEach(info => {
        uniqueChannels[info.ibGib] = info.channel;
      });
      uniqueChannels.forEach(channel => {
        channel.leave();
      });

      t.connectionInfos = [];
    }
  }

  /**
   * I want to publish on the event bus from the local client for use in a
   * cache.
   * This is similar to `WebGib.Bus.Channels.Event.broadcast_ib_gib_update/2`
   * in event.ex file.
   */
  broadcastIbGibUpdate_LocallyOnly(oldIbGib, newIbGib) {
    let t = this;

    t.ibGibProvider.getIbGibJson(oldIbGib, oldIbGibJson => {
      let tempJuncIbGib = ibHelper.getTemporalJunctionIbGib(oldIbGibJson);

      let connectionInfos = t.connectionInfos.filter(info => info.ibGib === oldIbGib);
      if (connectionInfos.length > 0) {
        let msg = {
          data: {
            old_ib_gib: oldIbGib,
            new_ib_gib: newIbGib
          },
          metadata: {
            name: "update",
            temp_junc_ib_gib: tempJuncIbGib,
            src: "client",
            timestamp: Date.now()
          }
        }

        connectionInfos.forEach(info => info.handler(msg));
      }
    })
  }
}
