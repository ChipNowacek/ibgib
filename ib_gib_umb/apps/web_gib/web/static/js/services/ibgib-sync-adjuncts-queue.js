import { GetAdjunctsCommand } from './commanding/commands';

/**
 * Background helper class (not background thread) queue. Executes on set intervalMs,
 * but also can execute immediately.
 * Can be started/stopped/paused/resumed. To send immediately, call `execute`.
 * To defer, use `enqueue`.
 */
export class IbGibSyncAdjunctsQueue {
  constructor(ibScape) {
    let t = this;
    t.ibScape = ibScape;
    t.ibGibAdjunctCache = t.ibScape.ibGibAdjunctCache;
    t.queue = [];
    t.completedIbGibs = [];
    // t.getAdjunctInfosCallbacksInProgress = {};
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
  
  /**
   * This calls execute on the current queue. Upon success callback, this will
   * then execute t.successCallback if it exists. It will then execute the 
   * given param `callback`.
   */
  flushQueue(callback) {
    let t = this, lc = `SyncAdjunctsQueue.flushQueue`;
    // console.log(`${lc}`);
    if (t.queue && t.queue.length > 0) {
      if (t.busy) {
        console.warn(`${lc} Background refresher is still busy. Cannot exec.`)
      } else {
        t.busy = true;
        try {
          t.exec(t.queue, successMsg => {
            if (t.successCallback) {
              t.successCallback(successMsg);
            } else {
              console.error(`${lc} why is successCallback falsy? :-?`)
              // huge hack - tries up to count times again to see if callback
              // is assigned. I think I did this because I thought it may have
              // been a race condition in the other class.
              let count = 5;
              let interval = setInterval(() => {
                if (count > 0) {
                  if (t.successCallback) {
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
          console.error(`${lc} error: ${e}`);
        } finally {
          t.busy = false;
        }
      }
    } else {
      // console.log(`${lc} nada to flush.`)
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
   * bus.
   * See also `queue` for queuing ibGibs.
   */
  exec(ibGibs, successCallback, errorCallback) {
    let t = this, lc = `SyncAdjunctsQueue.exec`;
    console.log(`${lc} starting...`)

    let prunedIbGibs = t._pruneIbGibs(ibGibs);
    let skippedIbGibs = ibGibs.filter(ibGib => !prunedIbGibs.includes(ibGib));

    if (prunedIbGibs && prunedIbGibs.length && prunedIbGibs.length > 0) {
      let d = { ibGibs:  prunedIbGibs };
      console.log(`${lc} hitting server for adjuncts for these ibGibs: ${JSON.stringify(prunedIbGibs)}`);
      let cmd = new GetAdjunctsCommand(t.ibScape, d, successMsg => {
        if (successCallback) {
          console.log(`${lc} back from server. `)
          if (!successMsg.data) { successMsg.data = {}; }
          successMsg.data.skippedIbGibs = skippedIbGibs;
          ibGibs.forEach(ibGib => {
            if (!t.completedIbGibs.includes(ibGib)) {
              t.completedIbGibs.push(ibGib); 
            }
          })
          successCallback(successMsg); 
        }
      }, errorCallback);
      cmd.exec();
    } else {
      console.log(`${lc} complete - nothing to sync from server.`);
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
    ibGibs
      .filter(ibGib => !t.completedIbGibs.includes(ibGib) && !t.queue.includes(ibGib))
      .forEach(ibGib => t.queue.push(ibGib));
  }

  _pruneIbGibs(ibGibs = []) {
    let t = this;
    return ibGibs.filter(ibGib => !t.completedIbGibs.includes(ibGib));
  }

  // _dispatchGetAdjunctInfosCallbacksInProgress(tempJuncIbGib, adjunctInfos) {
  //   let t = this;
  //   let callbacksCount = 0;
  //   do {
  //     let callbacks = t.getAdjunctInfosCallbacksInProgress[tempJuncIbGib];
  //     t.getAdjunctInfosCallbacksInProgress[tempJuncIbGib] = callbacks.splice(1);
  //     let callback = callbacks[0];
  //     callback(adjunctInfos);
  //     callbacksCount = t.getAdjunctInfosCallbacksInProgress[tempJuncIbGib].length;
  //   } while (callbacksCount > 0);
  //   delete t.getAdjunctInfosCallbacksInProgress[tempJuncIbGib];
  // }
  // /**
  //  * The first init of adjunct infos will talk to the server and get all
  //  * of the adjuncts for the given `tempJuncIbGib`. Any subsequent
  //  * additional adjuncts will need to come down the event bus and be
  //  * added to the cache and added to the ibScape.
  //  */
  // getAdjunctInfos(tempJuncIbGib, callback) {
  //   let t = this;
  //   
  //   if (tempJuncIbGib === "ib^gib") {
  //     callback([]);
  //   } else {
  //     let adjunctInfos = t.ibGibAdjunctCache.getAdjunctInfos(tempJuncIbGib);
  //     if (adjunctInfos) {
  //       // console.log(`adjunctInfos gotten from cache: ${adjunctInfos.length}`);
  //       // console.log(`adjunctInfos gotten from cache: ${JSON.stringify(adjunctInfos)}`);
  //       callback(adjunctInfos);
  //     } else if (t.getAdjunctInfosCallbacksInProgress[tempJuncIbGib]) {
  //       t.getAdjunctInfosCallbacksInProgress[tempJuncIbGib].push(callback);
  //     } else {
  //       // console.log(`No adjunctInfos in cache. Getting from server...`);
  //       
  //       t.getAdjunctInfosCallbacksInProgress[tempJuncIbGib] = [callback];
  //       
  //       let {ib, gib} = ibHelper.getIbAndGib(tempJuncIbGib);
  //       if (gib === "gib" || 
  //           ib.startsWith("session_") || 
  //           ib.startsWith("email_") || 
  //           ib.startsWith("node_")) {
  //         callback([]);
  //       } else {
  //         let data = { ibGibs: [tempJuncIbGib] };
  //         let cmdGetAdjuncts = new GetAdjunctsCommand(t.ibScape, data, successMsg => {
  //           t.ibGibAdjunctCache.clearAdjunctInfos(tempJuncIbGib);
  //           if (successMsg.data && successMsg.data.adjunct_ib_gibs) {
  //             let adjunctIbGibs = successMsg.data.adjunct_ib_gibs[tempJuncIbGib];
  //             t.getIbGibJsons(adjunctIbGibs, adjunctIbGibJsons => {
  //               Object.keys(adjunctIbGibJsons)
  //                 .map(key => adjunctIbGibJsons[key])
  //                 .forEach(adjunctIbGibJson => {
  //                   let adjunctIbGib = ibHelper.getFull_ibGib(adjunctIbGibJson);
  //                   t.ibGibAdjunctCache.addAdjunctInfo(tempJuncIbGib, tempJuncIbGib, adjunctIbGib, adjunctIbGibJson);
  //                 });
  //               adjunctInfos = t.ibGibAdjunctCache.getAdjunctInfos(tempJuncIbGib);
  // 
  //               t._dispatchGetAdjunctInfosCallbacksInProgress(tempJuncIbGib, adjunctInfos);
  //               // callback(adjunctInfos);
  //             });
  //           } else {
  //             // console.log(`GetAdjunctsCommand did not have successMsg.data && successMsg.data.adjunct_ib_gibs. Probably has no adjuncts.)`);
  //             t._dispatchGetAdjunctInfosCallbacksInProgress(tempJuncIbGib, []);
  //               // callback([]);
  //           }
  //         }, errorMsg => {
  //           console.error(`getAdjuncts error: ${JSON.stringify(errorMsg)}`);
  //           t._dispatchGetAdjunctInfosCallbacksInProgress(tempJuncIbGib, []);
  //         });
  //         cmdGetAdjuncts.exec();
  //       }
  //     }
  //   }
  // }

}
