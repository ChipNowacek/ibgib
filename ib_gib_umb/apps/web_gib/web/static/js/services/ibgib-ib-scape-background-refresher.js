import { BatchRefreshCommand } from './commanding/commands';

/**
 * Background helper class (not background thread) that pings the server with
 * refresh commands for multiple ibGibs (batch). Executes on set intervalMs,
 * but also can execute immediately.
 * Can be started/stopped/paused/resumed. To send immediately, call `execute`.
 * To defer, use `enqueue`.
 */
export class IbGibIbScapeBackgroundRefresher {
  constructor(ibScape) {
    let t = this;
    t.ibScape = ibScape;
    t.queue = [];
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
    console.log("BackgroundRefresher.exec")

    if (ibGibs && ibGibs.length && ibGibs.length > 0) {
      let d = { ibGibs: ibGibs };

      let cmd =
        new BatchRefreshCommand(t.ibScape, d, successCallback, errorCallback);

      cmd.exec();
    } else {
      console.error("IbGibIbScapeBackgroundRefresher.exec: invalid ibGibs.");
    }
  }

  /**
   * Queues the given `ibGibs` to be refreshed. Sends as a batch, polling on an interval.
   * Any newer versions found will come down the event bus as normal, one at a
   * time.
   */
  enqueue(ibGibs) {
    this.queue = this.queue.concat(ibGibs);
  }
}
