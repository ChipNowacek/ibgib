import * as ibHelper from './ibgib-helper';

/**
 * ibGibJson cache stores ibGibJson per ibGib.
 * updateEventMsg cache stores update event messages per ibGib with an expiryMs.
 *
 * This acts as an ibGibJson cache as well as an updateEventMsg cache, because I
 * am too unsure of the overall approach for the updateEventMsg cache to
 * refactor right now.
 */
export class IbGibCache {
  /** `latestExpiryMs` is invalidation timeout for calls to `getLatest`. */
  constructor(latestExpiryMs) {
    let t = this;
    t.naiveCache = {};
    t.adjunctNaiveCache = {};
    t.updateEventMsgInfos = {};
    t.latestExpiryMs = latestExpiryMs;
  }

  /**
   * True if ibGibJson exists for given `ibGib`.
   *
   * This has nothing to do with the `getLatest` mechanism. :nose:
   */
  exists(ibGib) {
    return ibGib in this.naiveCache;
  }

  add(ibGibJson) {
    let ibGib = ibHelper.getFull_ibGib(ibGibJson);
    this.naiveCache[ibGib] = ibGibJson;
  }

  get(ibGib) {
    if (ibGib in this.naiveCache) {
      return this.naiveCache[ibGib];
    } else {
      return null;
    }
  }

  /**
   * Adds a cache entry for the given `originalMsg`. `oldIbGib` and `newIbGib`
   * are both convenience arguments and should exist in the `originalMsg`.
   * i.e. originalMsg.old_ib_gib === oldIbGib, same for new.
   * This
   */
  addUpdateEventMsg(oldIbGib, newIbGib, originalMsg) {
    let t = this;

    let existingInfo = t.updateEventMsgInfos[oldIbGib];
    if (existingInfo) { clearTimeout(existingInfo.expiryTimer); }

    let newInfo = {
      newIbGib: newIbGib,
      originalMsg: originalMsg,
      // Cache invalidation driven by simple timer.
      expiryTimer: setTimeout(() => {
          if (t.updateEventMsgInfos[oldIbGib]) {
            delete t.updateEventMsgInfos[oldIbGib];
          }
        }, t.latestExpiryMs)
    }
    t.updateEventMsgInfos[oldIbGib] = info;
  }

  getLatest(ibGib) {
    let info = this.updateEventMsgInfos[ibGib];
    return info ? info.newIbGib : "";
  }

  addAdjunct(ibGib, adjunctIbGib) {
    let existingAdjunctIbGibs = t.adjunctNaiveCache[ibGib] || [];

    if (!existingAdjunctIbGibs.includes(adjunctIbGib)) {
      existingAdjunctIbGibs.push(adjunctIbGib);
    }

    t.adjunctNaiveCache[ibGib] = existingAdjunctIbGibs;
  }

  getAdjunctIbGibs(ibGib) {
    return t.adjunctNaiveCache[ibGib];
  }
}
