import * as ibHelper from '../ibgib-helper';

/**
 * ibGibJson cache stores ibGibJson per ibGib.
 * updateEventMsg cache stores update event messages per ibGib with an expiryMs.
 *
 * This acts as an ibGibJson cache as well as an updateEventMsg cache, because I
 * am too unsure of the overall approach for the updateEventMsg cache to
 * refactor right now.
 */
export class IbGibAdjunctCache {
  constructor() {
    let t = this;
    t.adjunctNaiveCache = {};
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

    let adjunctRel8nTarget = adjunctIbGibJson.rel8ns[adjunctIbGibJson.data.adjunct_rel8n] ? adjunctIbGibJson.rel8ns[adjunctIbGibJson.data.adjunct_rel8n][0] : null;

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

        adjunctRel8nTarget: adjunctRel8nTarget
      };

    // console.log(`addAdjunctInfo: adjunctInfo: ${JSON.stringify(adjunctInfo)}`)

    t.adjunctNaiveCache[tempJuncIbGib].push(adjunctInfo);
  }

  getAdjunctInfos(tempJuncIbGib) {
    let t = this;
    return t.adjunctNaiveCache[tempJuncIbGib] || [];
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
  }
}
