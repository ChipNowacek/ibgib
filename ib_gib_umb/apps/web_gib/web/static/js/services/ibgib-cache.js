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

  addAdjunctInfo(tempJuncIbGib, ibGib, adjunctIbGib, adjunctIbGibJson) {
    let t = this;
    let existingInfos = t.adjunctNaiveCache[tempJuncIbGib];
    if (!existingInfos) {
      t.adjunctNaiveCache[tempJuncIbGib] = [];
    } else if (existingInfos.some(info => info.adjunctIbGib === adjunctIbGib)) {
      console.warn(`Adjunct info already exists for adjunctIbGib: ${adjunctIbGib}`);

      // return early, since we have already added this adjunctIbGib
      return;
    }

    let adjunctTempJuncIbGib = ibHelper.getTemporalJunctionIbGib(adjunctIbGibJson);

    let adjunctInfo = {
        adjunctIbGib: adjunctIbGib,
        ibGib: ibGib,
        tempJuncIbGib: tempJuncIbGib,
        adjunctTempJuncIbGib: adjunctTempJuncIbGib,
        adjunctIbGibJson: adjunctIbGibJson,
        adjunctRel8n: adjunctIbGibJson.data.adjunct_rel8n,
        adjunctTargetRel8n: adjunctIbGibJson.data.adjunct_target_rel8n,
        // should be the same as tempJuncIbGib
        adjunctToTemporalJunction: adjunctIbGibJson.rel8ns.adjunct_to[0],

        adjunctRel8nTarget: adjunctIbGibJson.rel8ns[adjunctIbGibJson.data.adjunct_rel8n][0]
      };

    console.log(`addAdjunctInfo: adjunctInfo: ${JSON.stringify(adjunctInfo)}`)

    t.adjunctNaiveCache[tempJuncIbGib].push(adjunctInfo);
  }

  getAdjunctInfos(tempJuncIbGib) {
    let t = this;
    return t.adjunctNaiveCache[tempJuncIbGib];
  }

  clearAdjunctInfos(tempJuncIbGib) {
    let t = this;
    if (t.adjunctNaiveCache[tempJuncIbGib]) {
      delete t.adjunctNaiveCache[tempJuncIbGib];
    }
  }

  getAdjunctInfo_ByAdjunctIbGib(adjunctIbGib) {
    let t = this;
    let result = null;

    // Groups by tempJuncIbGib
    let adjunctInfoGroups =
      Object.keys(t.adjunctNaiveCache)
        .map(key => t.adjunctNaiveCache[key]);

    for (var i = 0; i < adjunctInfoGroups.length; i++) {
      let infos = adjunctInfoGroups[i];
      let adjunctInfos = infos.filter(info => info.adjunctIbGib === adjunctIbGib);
      if (adjunctInfos && adjunctInfos.length > 0) {
        if (adjunctInfos.length > 1) {
          console.warn(`multiple adjunctInfos found for adjunctIbGib: ${adjunctIbGib}`)
        }
        result = adjunctInfos[0];
        break;
      }
    }

    return result;
    // if (adjunctInfos.length === 0) {
    //   return null;
    // } else
  }
}
