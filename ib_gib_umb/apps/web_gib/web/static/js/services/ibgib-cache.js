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
      return this.naiveCache[ibGib];
    } else {
      return null;
    }
  }
}
