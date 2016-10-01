import * as ibHelper from './ibgib-helper';

export class IbGibCache {
  constructor() {
    this.naiveCache = {};
  }

  exists(ibGib) {
    return ibGib in this.naiveCache;
  }

  add(ibGibJson) {
    let ibGib = ibHelper.getFull_ibGib(ibGibJson);
    this.naiveCache[ibGib] = ibGibJson;
  }

  get(ibGib) {
    if (ibGib in this.naiveCache) {
      let ibGibJson = this.naiveCache[ibGib];
      return ibHelper.getDataText(ibGibJson) || "?";
    } else {
      return null;
    }
  }
}
