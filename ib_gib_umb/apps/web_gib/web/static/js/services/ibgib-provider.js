import * as d3 from 'd3';

export class IbGibProvider {
  constructor(ibGibCache, baseJsonPath) {
    let t = this;

    t.ibGibCache = ibGibCache;
    t.baseJsonPath = baseJsonPath;
  }

  getIbGibJson(ibGib, callback) {
    let t = this;
    let ibGibJson = this.ibGibCache.get(ibGib);
    if (ibGibJson) {
      if (callback) { callback(ibGibJson); }
    } else {
      // We don't yet have the json for this particular data.
      // So we need to load the json, and when it returns we will exec callback.
      d3.json(t.baseJsonPath + ibGib, ibGibJson => {
        t.ibGibCache.add(ibGibJson);

        if (callback) { callback(ibGibJson); }
      });
    }
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

    let ibGibJson = this.ibGibCache.get(ibGib);
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
    return t.ibGibCache.getAdjunctInfo_ByAdjunctIbGib(adjunctIbGib);
  }
}
