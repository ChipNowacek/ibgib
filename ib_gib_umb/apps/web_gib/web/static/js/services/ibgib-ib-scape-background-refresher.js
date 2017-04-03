import { BatchRefreshCommand } from './commanding/commands';

/**
 * Background helper class (not background thread) that pings the server with
 * refresh commands for multiple ibGibs (batch). Executes on set intervalMs,
 * but also can execute immediately.
 * Can be started/stopped/paused/resumed. To send immediately, call `execute`.
 * To defer, use `enqueue`.
 */
export class IbGibIbScapeBackgroundRefresher {
  constructor(ibScape, cachedRefreshExpiryMs) {
    let t = this;
    t.ibScape = ibScape;
    t.queue = [];
    t.cachedRefreshes = {};
    t.cachedRefreshExpiryMs = cachedRefreshExpiryMs || 600000;
  }
  destroy() {
    this.stop();
  }

  /** Starts the refresh poll. Checks internal queue for refreshing. */
  start(successCallback, errorCallback, intervalMs) {
    let t = this;
    t.successCallback = successCallback;
    t.errorCallback = errorCallback;
    t.intervalMs = intervalMs;
    t.pollInterval = setInterval(() => { t.flushQueue(); }, t.intervalMs);
  }
  
  flushQueue(callback) {
    let t = this, lc = `Refresher.flushQueue`;
    // console.log(`${lc}`);
    if (t.queue && t.queue.length > 0) {
      if (t.busy) {
        console.warn("Background refresher is still busy. Cannot exec.")
      } else {
        t.busy = true;
        try {
          let mainCallback = t.successCallback;
          t.exec(t.queue, successMsg => {
            if (mainCallback) {
              mainCallback(successMsg);
            } else if (t.successCallback) {
              t.successCallback(successMsg);
            } else {
              console.error(`why is successCallback falsy? :-?`)
              // huge hack
              let count = 5;
              let interval = setInterval(() => {
                if (count > 0) {
                  if (mainCallback) {
                    clearInterval(interval);
                    mainCallback(successMsg);
                  } else if (t.successCallback) {
                    clearInterval(interval);
                    t.successCallback(successMsg);
                  } else {
                    count = count - 1;
                  }
                } else {
                  clearInterval(interval);
                  console.error(`${lc} I give up.`);
                }
              }, 3000);
            }
            if (callback) { callback(successMsg); }
          }, t.errorCallback);
          t.queue = [];
        } catch (e) {
          console.error(`refresh error: ${e}`);
        } finally {
          t.busy = false;
        }
      }
    } else {
      // console.log(`nada to flush.`)
    }
  }

  /** Stops the refresh poll. Deletes the internal queue and callbacks. */
  stop() {
    let t = this;
    t.pause();
    delete t.queue;
    t.queue = [];
    delete t.successCallback;
    delete t.errorCallback;
    if (t.pollInterval) {
      clearInterval(t.pollInterval);
      delete t.pollInterval;
    }
  }

  /** Clears the internal poll, but retains the internal queue. */
  pause() {
    let t = this;
    if (t.pollInterval) {
      clearInterval(t.pollInterval);
      delete t.pollInterval;
    }
    t.paused = true;
  }

  /**
   * If paused, resumes with same success/error callbacks with optionally
   * a new intervalMs. If not provided (or 0), will use previous intervalMs.
   */
  resume(optionalNewIntervalMs) {
    let t = this;
    if (t.paused) {
      t.start(t.successCallback, t.errorCallback, optionalNewIntervalMs || t.intervalMs);
    } else {
      console.error(`refresh tried to resume, but not paused.`);
    }
  }

  /**
   * Immediately sends a batch of given `ibGibs` to the server via the command
   * bus to check for newer versions.
   * See also `queue` for queuing ibGibs.
   */
  exec(ibGibs, successCallback, errorCallback) {
    let t = this;
    // console.log("BackgroundRefresher.exec")

    ibGibs = t._pruneIbGibs(ibGibs);

    if (ibGibs && ibGibs.length && ibGibs.length > 0) {
      let d = { ibGibs:  ibGibs };
      
      console.log(`hitting server for refresh ibGibs. ibGibs: ${JSON.stringify(ibGibs)}`);
      let cmd =
        new BatchRefreshCommand(t.ibScape, d, successMsg => {
            if (successCallback) {
              if (!successMsg.data) { successMsg.data = {}; }
              
              let latestIbGibs = successMsg.data.latest_ib_gibs || {};
              // add any results to cache
              Object.keys(latestIbGibs)
                .forEach(oldIbGib => {
                  console.log(`Adding cached refresh ibGib for oldIbGib: ${oldIbGib}`);
                  t.ibScape.ibGibProvider.setLatestIbGib(oldIbGib, latestIbGibs[oldIbGib]);
                });
              
              successCallback(successMsg); 
            }
          }, errorCallback);

      cmd.exec();
    } else {
      console.log(`nothing to refresh.`);
      if (successCallback) { successCallback(null); }
    }
  }

  /**
   * Queues the given `ibGibs` to be refreshed. Sends as a batch, polling on an interval.
   * Any newer versions found will come down the event bus as normal, one at a
   * time.
   */
  enqueue(ibGibs) {
    let t = this;
    ibGibs.forEach(ibGib => {
      if (!t.queue.includes(ibGib)) {
        t.queue.push(ibGib);
      }
    })
  }

  /*
   * I'm hacking this on to be able to update the refresher.
   * Currently, the event bus is designed for the ibScape to connect/disconnect.
   * It doesn't accept just any ol' subscribers for all messages or anything.
   * So this function is called from within the
   * ibScape.connectToEventBus_IbGibNode function. eesh. :-/
   */ 
  handleEventBusMsg_Update(msg) {
    let t = this;
    // console.log(`handleEventBusMsg_Update msg:\n${JSON.stringify(msg)}`)

    if (msg && msg.data && msg.data.new_ib_gib && 
        msg.metadata && msg.metadata.temp_junc_ib_gib) {

      console.log(`background refresher.handleEventBusMsg_Update. old: ${msg.metadata.temp_junc_ib_gib}. new: ${msg.data.new_ib_gib}`)

      t.ibScape.ibGibProvider.setLatestIbGib(msg.metadata.temp_junc_ib_gib, msg.data.new_ib_gib);
      if (msg.data.old_ib_gib) {
        t.ibScape.ibGibProvider.setLatestIbGib(msg.data.old_ib_gib, msg.data.new_ib_gib);
      }
    } else {
      // console.warn(`background refresher: improperly formatted update event. msg: ${JSON.stringify(msg)}`);
    }
  }
  
  _pruneIbGibs(ibGibs = []) {
    let t = this;
    let toRefresh = [];
    // let pruned = [];
    
    let addRefresh = (ibGib) => {
      toRefresh.push(ibGib);
      t.cachedRefreshes[ibGib] = Date.now();
    }
    
    ibGibs.forEach(ibGib => {
      let lastRefreshTimestamp = t.cachedRefreshes[ibGib];
      if (lastRefreshTimestamp) {
        if (Date.now() - lastRefreshTimestamp > t.cachedRefreshExpiryMs) {
          addRefresh(ibGib);
        } else {
          // pruned.push(ibGib);
          console.log(`skipping refresh ibGib: ${ibGib}`)
        }
      } else {
        addRefresh(ibGib);
      }
    });
    
    return toRefresh;
  }
}
