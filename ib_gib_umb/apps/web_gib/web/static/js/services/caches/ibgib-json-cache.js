import * as ibHelper from '../ibgib-helper';

/**
 * ibGibJson cache stores ibGibJson per ibGib.
 * updateEventMsg cache stores update event messages per ibGib with an expiryMs.
 *
 * This acts as an ibGibJson cache as well as an updateEventMsg cache, because I
 * am too unsure of the overall approach for the updateEventMsg cache to
 * refactor right now.
 */
export class IbGibJsonCache {
  constructor() {
  }

  /**
   * True if ibGibJson exists for given `ibGib`.
   */
  exists(ibGib) {
    return localStorage.getItem(t._getKey(ibGib)) !== null;
  }

  add(ibGibJson) {
    let t = this;
    let ibGib = ibHelper.getFull_ibGib(ibGibJson);
    localStorage.setItem(t._getKey(ibGib), JSON.stringify(ibGibJson));
  }

  get(ibGib) {
    let t = this;
    let key = t._getKey(ibGib);
    let json = localStorage.getItem(key);
    let result = JSON.parse(json);
    return result;
  }
  
  _getKey(ibGib) {
    console.log(`IbGibJsonCache._getKey: ${ibGib}`);
    return "json_" + ibGib;
  }
}
