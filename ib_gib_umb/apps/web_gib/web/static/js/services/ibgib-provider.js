import * as ibHelper from './ibgib-helper';

export class IbGibProvider {
  constructor() {
  }

  /**
   * Gets a complete ibGibJson object, given an `ibgib` pointer, e.g. "ib^gib"
   * Mocked for now.
   */
  get(ibgib) {

    let ib = ibgib.split("^")[0];
    let gib = ibgib.split("^")[1];

    switch (ibgib) {
      case "ib^gib":
        return {
          "ib": "ib",
          "gib": "gib",
          "data": {
            "a": "aaa",
            "b": "bbb"
          },
          "rel8ns": {
            "ib^gib": [
              "ib^gib",
              "test^gib"
            ]
          }
        };

      case "test^gib":
        return {
          "ib": "test",
          "gib": "gib",
          "data": {
            "t": "test"
          },
          "rel8ns": {
            "ib^gib": [
              "ib^gib"
            ]
          }
        };

      default:
        return {
          "ib": ib,
          "gib": "gib",
          "data": {
            "a": "aaa",
            "b": "bbb",
            "ibgib": ibgib
          },
          "rel8ns": {
            "ib^gib": [
              "ib^gib",
              "test^gib"
            ]
          }
        };
    }
  }
}
