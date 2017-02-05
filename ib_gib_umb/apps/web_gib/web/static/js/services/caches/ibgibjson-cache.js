import * as ibHelper from '../ibgib-helper';

/**
 * ibGibJson cache stores ibGibJson per ibGib.
 * updateEventMsg cache stores update event messages per ibGib with an expiryMs.
 *
 * This acts as an ibGibJson cache as well as an updateEventMsg cache, because I
 * am too unsure of the overall approach for the updateEventMsg cache to
 * refactor right now.
 */
export class IbGibCache {
  constructor() {
    let t = this;
    t.naiveCache = {};
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
}
