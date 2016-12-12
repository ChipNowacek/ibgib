import * as ibHelper from './ibgib-helper';
import { Socket } from "phoenix";

export class IbGibEventBus {
  constructor(socket) {
    let t = this;

    t.socket = socket;
    t.channelInfos = [];
  }

  connect(ibGib, handleUpdateFunc) {
    let t = this;

    if (ibGib) {
      // Search existing infos for same ibGib. Reuse channel if exists.
      let channel;
      let existingInfos = t.channelInfos.filter(channelInfo => channelInfo.ibGib === ibGib);
      if (existingInfos.length === 0) {
        console.log(`connecting to ibGib channel: ${ibGib}`)
        channel = t.initChannel(ibGib, handleUpdateFunc);
      } else {
        console.log(`already connected to ibGib channel: ${ibGib}`)
        channel = existingInfos[0].channel;
      }

      // Create the channel info
      let channelInfo = {
        ibGib: ibGib,
        channel: channel
      }

      // duplicates ok, this effectively does reference counting
      t.channelInfos.push(channelInfo);
    } else {
      console.error(`EventBus.connect requires a valid ibGib`);
    }
  }

  initChannel(ibGib, handleUpdateFunc) {
    let t = this;

    let topic = `event:${ibGib}`;
    let channel = t.socket.channel(topic, {});

    channel.join()
      .receive("ok", resp => { console.log(`Joined event bus channel successfully. topic: ${topic}`, resp) })
      .receive("error", resp => { console.error(`Unable to join event bus channel. topic: ${topic}. resp: ${JSON.stringify(resp)}`, resp) })

    channel.on("update", msg => { handleUpdateFunc(msg); });

    return channel;
  }

  disconnect(ibGib) {
    let t = this;

    if (ibGib) {
      // disconnect from a single ibGib channel. If it's the only one we're
      // currently connected to, then leave the channel. Otherwise, we're
      // essentially decrementing a reference count.
      let existingInfos = t.channelInfos.filter(channelInfo => channelInfo.ibGib === ibGib);
      switch (existingInfos.length) {
        case 0:
          console.error(`EventBus.disconnect(${ibGib}) called, but not currently connected to this ibGib channel.`);
          break;
        case 1:
          // disconnecting the only ref to channel, so splice and leave.
          let onlyChannelInfo = existingInfos[0];
          let indexOnly = t.channelInfos.indexOf(onlyChannelInfo);
          t.channelInfos.splice(indexOnly, 1);
          console.log(`disconnecting from ibGib channel: ${ibGib}`)
          onlyChannelInfo.channel.leave();
          break;
        default:
          // multiple refs to channel, so just splice one off and continue.
          let firstChannelInfo = existingInfos[0];
          let indexFirst = t.channelInfos.indexOf(firstChannelInfo);
          t.channelInfos.splice(indexFirst, 1);
          break;
      }
    } else {
      // disconnect from all channels.
      let uniqueChannels = {};
      t.channelInfos.forEach(info => {
        uniqueChannels[info.ibGib] = info.channel;
      });
      uniqueChannels.forEach(channel => {
        channel.leave();
      });

      t.channelInfos = [];
    }
  }
}
