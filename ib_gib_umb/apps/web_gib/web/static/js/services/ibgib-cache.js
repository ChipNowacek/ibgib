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

  addAdjunctInfo(tempJuncIbGib, ibGib, adjunctIbGib, adjunctIbGibJson) {
    let t = this;
    tempJuncIbGib = tempJuncIbGib || ibHelper.getTemporalJunctionIbGib(ibGib);

    // adjunctInfo is considered immutable, since currently we
    // assume an adjunct is only related to a single ibGib. So make this
    // idempotent.
    let adjunctInfo =
      t.adjunctNaiveCache[adjunctIbGib] || {
        adjunctIbGib: adjunctIbGib,
        ibGib: ibGib,
        tempJuncIbGib: tempJuncIbGib,
        adjunctIbGibJson: adjunctIbGibJson,
        adjunctRel8n: adjunctIbGibJson.data.adjunct_rel8n,

        // should be the same as tempJuncIbGib
        adjunctToTemporalJunction: adjunctIbGibJson.rel8ns.adjunct_to[0],

        adjunctRel8nTarget: adjunctIbGibJson.rel8ns[adjunctIbGibJson.data.adjunct_rel8n][0]
      };

    t.adjunctNaiveCache[adjunctIbGib] = adjunctInfo;
  }

  getAdjunctInfos(tempJuncIbGib) {
    let t = this;

    return Object.keys(t.adjunctNaiveCache)
      .map(key => t.adjunctNaiveCache[key])
      .filter(adjunctInfo => adjunctInfo.tempJuncIbGib === tempJuncIbGib);
  }
}
