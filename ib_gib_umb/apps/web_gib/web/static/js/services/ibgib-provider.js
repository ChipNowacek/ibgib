import * as d3 from 'd3';
import * as ibHelper from './ibgib-helper';

export class IbGibProvider {
  constructor(ibGibJsonCache, ibGibAdjunctCache, ibGibLatestCache, baseJsonPath) {
    let t = this;

    t.ibGibJsonCache = ibGibJsonCache;
    t.ibGibAdjunctCache = ibGibAdjunctCache;
    t.ibGibLatestCache = ibGibLatestCache;
    t.baseJsonPath = baseJsonPath;
    
    t.gettingJsonCallbacks = {};
  }

  getIbGibJson(ibGib, callback) {
    let t = this, lc = `IbGibProvider.getIbGibJson ${ibGib}`;
    let ibGibJson = this.ibGibJsonCache.get(ibGib);
    if (ibGibJson) {
      if (callback) { callback(ibGibJson); }
    } else {
      // We don't yet have the json for this particular data.
      // So we need to load the json, and when it returns we will exec callback.
      // But we don't want to duplicate calls that are already in progress for
      // a given ibGib. So we keep track of callbacks and only make the call 
      // once to the server.
      if (ibGib in t.gettingJsonCallbacks) {
        // console.warn(`${lc} already in progress. adding callback.`)
        t.gettingJsonCallbacks[ibGib].push(callback);
      } else {
        t.gettingJsonCallbacks[ibGib] = [callback];
        // console.warn(`${lc} getting json from server...`)
        d3.json(t.baseJsonPath + ibGib, ibGibJson => {
          // console.warn(`${lc} returned json from server.`)
          
          let verified = ibHelper.verifyIbGibJson(ibGibJson);
          if (verified === true) {
            t.ibGibJsonCache.add(ibGibJson);
            t._dispatchGetJsonCallback(ibGib, ibGibJson);
            // if (callback) { callback(ibGibJson); }
          } else if (verified === false) {
            console.error(`${lc} ibGibJson is not valid. :-/`);
            ibGibJson = this.ibGibJsonCache.get("ib^gib");
            t._dispatchGetJsonCallback(ibGib, ibGibJson);
          } else {
            console.error(`${lc} There was an error during verification of ibGibJson.`);
            ibGibJson = this.ibGibJsonCache.get("ib^gib");
            t._dispatchGetJsonCallback(ibGib, ibGibJson);
          }
        });
      }
    }
  }
  
  _dispatchGetJsonCallback(ibGib, ibGibJson) {
    let t = this, lc = `_dispatchGetJsonCallback ${ibGib}`;
    let callbacksCount = 0;
    do {
      let callbacks = t.gettingJsonCallbacks[ibGib];
      // console.log(`${lc} callbacksCount: ${callbacks.length}. Dispatching...`)
      t.gettingJsonCallbacks[ibGib] = callbacks.splice(1);
      let callback = callbacks[0];
      callback(ibGibJson);
      callbacksCount = t.gettingJsonCallbacks[ibGib].length;
    } while (callbacksCount > 0);
    delete t.gettingJsonCallbacks[ibGib];
  }

  /**
   * Gets the ibGibJson from the cache synchronously. If it doesn't exist
   * already, then it will NOT get it from the server.
   *
   * Use Case: I'm creating this for the use case of adjuncts, where the target
   * to the adjunct should already be loaded in the cache.
   */
  getIbGibJsonOrNull_Sync(ibGib) {
    let lc = `getIbGibJsonOrNull_Sync(${ibGib})`;

    let ibGibJson = this.ibGibJsonCache.get(ibGib);
    if (ibGibJson) {
      return ibGibJson;
    } else {
      console.warn(`${lc} ibGibJson not found in cache. This function's original intent assumes the given ibGib to be loaded (in cache) by now.`);
      return null;
    }
  }

  /**
   * Gets all ibGibJsons for given ibGibs in a javascript object.
   * Ugly manual async whenAll code here...ick.
   */
  getIbGibJsons(ibGibs, callback) {
    let t = this;

    if (!ibGibs || ibGibs.length === 0) {
      callback(null);
    } else {
      t._getIbGibJsonsRecursive(ibGibs.concat(), {}, callback);
    }
  }
  _getIbGibJsonsRecursive(ibGibsToDo, ibGibsDone, callback) {
    let t = this;
    if (ibGibsToDo && ibGibsToDo.length > 0) {
      t.getIbGibJson(ibGibsToDo[0], ibGibJson => {
        let ibGibDone = ibGibsToDo.splice(0,1);
        ibGibsDone[ibGibDone] = ibGibJson;
        t._getIbGibJsonsRecursive(ibGibsToDo, ibGibsDone, callback);
      });
    } else {
      callback(ibGibsDone);
    }
  }

  getAdjunctInfo_ByAdjunctIbGib(adjunctIbGib) {
    let t = this;
    return t.ibGibAdjunctCache.getAdjunctInfo_ByAdjunctIbGib(adjunctIbGib);
  }
  
  getLatestIbGib(ibGib) {
    let t = this;
    if (!ibGib) {
      return null;
    } else if (ibGib === "ib^gib") {
      return "ib^gib";
    } else {
      return t.ibGibLatestCache.get(ibGib) || ibGib;
    }
  }
  
  setLatestIbGib(ibGib, latest) {
    let t = this;
    if (ibGib && ibGib !== "ib^gib") {
      t.ibGibLatestCache.set(ibGib, latest);
    }
  }
}
