import * as ibHelper from '../ibgib-helper';

/**
 * Cache that currently uses localStorage to track what the latest (most 
 * up-to-date) ib^gib pointers are for any given ib^gib pointer.
 * 
 * This is expected to be used with tempJuncIbGibs.
 */
export class IbGibLatestCache {
  constructor() {
  }

  exists(ibGib) {
    return localStorage.getItem(t._getKey(ibGib)) !== null;
  }

  set(ibGib, latestIbGib) {
    let t = this;
    localStorage.setItem(t._getKey(ibGib), latestIbGib);
  }

  get(ibGib) {
    let t = this;
    return localStorage.getItem(t._getKey(ibGib));
  }
  
  _getKey(ibGib) {
    console.log(`IbGibLatestCache._getKey: ${ibGib}`);
    return "lc_" + ibGib;
  }
}
