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
    t.cachedRefreshExpiryMs = cachedRefreshExpiryMs || 30000;
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
    t.pollInterval = setInterval(() => {
      if (t.queue && t.queue.length > 0) {
        if (t.busy) {
          console.warn("Background refresher is still busy. Cannot exec.")
        } else {
          t.busy = true;
          try {
            t.exec(t.queue, t.successCallback, t.errorCallback);
            t.queue = [];
          } catch (e) {
            console.error(`refresh error: ${e}`);
          } finally {
            t.busy = false;
          }
        }
      }
    }, t.intervalMs);
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

    if (ibGibs && ibGibs.length && ibGibs.length > 0) {
  
      let cachedIbGibs = ibGibs.filter(ibGib => {
        if (t.cachedRefreshes[ibGib]) {
          let { timestamp, refreshedIbGib } = t.cachedRefreshes[ibGib];
          return timestamp && (Date.now() - timestamp < t.cachedRefreshExpiryMs);
        } else {
          return false;
        }
      });
      let serverIbGibs = ibGibs.filter(ibGib => !cachedIbGibs.includes(ibGib));
      
      if (serverIbGibs && serverIbGibs.length > 0) {
        let d = { ibGibs:  serverIbGibs };
        
        console.log(`hitting server for refresh ibGibs. cached ibGibs: ${JSON.stringify(cachedIbGibs)}.   server ibGibs: ${JSON.stringify(serverIbGibs)}`);
        let cmd =
          new BatchRefreshCommand(t.ibScape, d, successMsg => {
              if (successCallback) {
                if (!successMsg.data) { successMsg.data = {}; }
                
                let latestIbGibs = successMsg.data.latest_ib_gibs || {};
                // add any results to cache
                Object.keys(latestIbGibs)
                  .forEach(oldIbGib => {
                    console.log(`Adding cached refresh ibGib for oldIbGib: ${oldIbGib}`)
                    let cacheEntry = {
                      timestamp: Date.now(),
                      refreshedIbGib: latestIbGibs[oldIbGib]
                    };
                    t.cachedRefreshes[oldIbGib] = cacheEntry;
                  });
                
                // latest only includes those with actual updates. We need
                // to cache also the ones that have no updates.
                serverIbGibs
                  .filter(serverIbGib => !Object.keys(latestIbGibs).includes(serverIbGib))
                  .forEach(ibGibWithoutUpdate => { 
                    let cacheEntry = {
                      timestamp: Date.now(),
                      refreshedIbGib: null
                    };
                    t.cachedRefreshes[ibGibWithoutUpdate] = cacheEntry;
                  });
    
                t._addCachedEntriesToSuccessMsg(cachedIbGibs, successMsg);
                
                successCallback(successMsg); 
              }
            }, errorCallback);

        cmd.exec();
      } else {
        if (successCallback) {
          let successMsg = { data: {latest_ib_gibs: null} }
          t._addCachedEntriesToSuccessMsg(cachedIbGibs, successMsg);
          successCallback(successMsg);
        }
      }
    } else {
      console.log(`nothing to refresh.`);
      if (successCallback) { successCallback(null); }
    }
  }

  _addCachedEntriesToSuccessMsg(cachedIbGibs, successMsg) {
    let t = this;
    cachedIbGibs.forEach(cachedIbGib => {
      // We skipped refreshing the cached ibGibs on the server, so 
      // add these cached entries back into the results before
      // returning to the caller.
      let { refreshedIbGib } = t.cachedRefreshes[cachedIbGib];
      if (!successMsg.data.latest_ib_gibs) {
        successMsg.data.latest_ib_gibs = {}; 
      }
      
      successMsg.data.latest_ib_gibs[cachedIbGib] = refreshedIbGib;
    });
  }

  /**
   * Queues the given `ibGibs` to be refreshed. Sends as a batch, polling on an interval.
   * Any newer versions found will come down the event bus as normal, one at a
   * time.
   */
  enqueue(ibGibs) {
    this.queue = this.queue.concat(ibGibs);
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
      
      let cacheEntry = {
        timestamp: Date.now(),
        refreshedIbGib: msg.data.new_ib_gib
      };
      t.cachedRefreshes[msg.metadata.temp_junc_ib_gib] = cacheEntry;
    } else {
      // console.warn(`background refresher: improperly formatted update event. msg: ${JSON.stringify(msg)}`);
    }
  }
}
