class IbGibEngine {
  /**
   * @param ibGibUrlPath is used to construct api-ish calls. For now, to
   * simplify things, it's not a completely separate json api. It's an actual
   * browser http call that will redirect (things like "fork", "merge", etc.).
   */
  constructor(ibGibUrlPath) {

  }

  // let divIbGibData = document.querySelector("#ibgib-data");
  // let openPath = divIbGibData.getAttribute("data-open-path");
  // if (d.cat !== "rel8n" && d.ibgib !== "ib^gib" && d.cat !== "ib") {
  //   console.log(`clicked ibgib: ${d.ibgib}`)
  //   location.href = openPath + d.ibgib;
  // }

  /**
   * Executes a fork on the given `ibGib`.
   * ATOW (2016/09/12), this puts in a fork command to the api and redirects
   * to the newly forked URL.
   */
  fork(ibGib, destIb) {
    // Call from IbScape.executeMenuCommand
    // this.ibEngine.fork(dIbGib.ibgib);


  }
}
