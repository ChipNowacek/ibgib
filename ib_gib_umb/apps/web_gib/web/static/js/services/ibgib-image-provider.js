export class IbGibImageProvider {
  constructor(ibGibCache) {
    this.ibGibCache = ibGibCache;
  }

  getFullImageUrl(ibGib, ibGibJson) {
    ibGibJson = ibGibJson || this.ibGibCache.get(ibGib);
    if (ibGibJson &&
        ibGibJson.data &&
        ibGibJson.data.bin_id &&
        ibGibJson.data.ext) {
      return `/files/${ibGibJson.data.bin_id}${ibGibJson.data.ext}`;
    } else {
      return "";
    }
  }
}
