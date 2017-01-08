/** Extracts the full ib + gib from the ibGibJson info. */
export function getFull_ibGib(ibGibJson) {
  return ibGibJson.ib + "^" + ibGibJson.gib;
}

/** Separates the ib and gib in a javascript object { ib: x, gib: y} */
export function getIbAndGib(ibGib) {
  if (ibGib) {
    let [ib, gib] = ibGib.split("^");
    return {ib: ib, gib: gib};
  } else {
    console.error("getIbAndGib: ibGib not provided.");
  }
}

/**
 * Returns the first non-root ib^gib in the given ibGibJson past.
 * If there are no previous ib^gib in the past besides the root ib^gib, then
 * this returns
 */
export function getTemporalJunctionIbGib(ibGibJson) {
  let past = ibGibJson.rel8ns.past;
  return past.length > 1 ? past[1] : getFull_ibGib(ibGibJson);
}

/** For safe access to ibGibJson.data.text */
export function getDataText(ibGibJson) {
  return (ibGibJson && ibGibJson.data && ibGibJson.data.text) ?
      ibGibJson.data.text :
      null;
}

/** Just gets a random string which is actually just a number. */
export function getRandomString() {
  return Math.trunc(Math.random() * 10000000).toString();
}

/**
 * Cargo culting this so I don't have to parse the transform string manually.
 * Big thanks to SO and @altocumulus for this one at
 * http://stackoverflow.com/questions/38224875/replacing-d3-transform-in-d3-v4
 * and @LarsKotthoff at
 * http://stackoverflow.com/questions/28508785/how-to-get-specific-transform-attribute-in-d3
 */
export function parseTransformString(transform) {
  if (transform) {
    // Create a dummy g for calculation purposes only. This will never
    // be appended to the DOM and will be discarded once this function
    // returns.
    var g = document.createElementNS("http://www.w3.org/2000/svg", "g");

    // Set the transform attribute to the provided string value.
    g.setAttributeNS(null, "transform", transform);

    // consolidate the SVGTransformList containing all transformations
    // to a single SVGTransform of type SVG_TRANSFORM_MATRIX and get
    // its SVGMatrix.
    var matrix = g.transform.baseVal.consolidate().matrix;

    // Below calculations are taken and adapted from the private function
    // transform/decompose.js of D3's module d3-interpolate.
    var {a, b, c, d, e, f} = matrix;   // ES6, if this doesn't work, use below assignment
    // var a=matrix.a, b=matrix.b, c=matrix.c, d=matrix.d, e=matrix.e, f=matrix.f; // ES5
    var scaleX, scaleY, skewX;
    if (scaleX = Math.sqrt(a * a + b * b)) a /= scaleX, b /= scaleX;
    if (skewX = a * c + b * d) c -= a * skewX, d -= b * skewX;
    if (scaleY = Math.sqrt(c * c + d * d)) c /= scaleY, d /= scaleY, skewX /= scaleY;
    if (a * d < b * c) a = -a, b = -b, skewX = -skewX, scaleX = -scaleX;
    return {
      translateX: e,
      translateY: f,
      rotate: Math.atan2(b, a) * Math.PI/180,
      skewX: Math.atan(skewX) * Math.PI/180,
      scaleX: scaleX,
      scaleY: scaleY
    };
  } else {
    return {
      translateX: 0,
      translateY: 0,
      rotate: 0,
      skewX: 0,
      scaleX: 1,
      scaleY: 1
    };
  }
}

/** Simple function to extract the identity ibGibs from the json object. */
export function getIdentityIbGibs(ibGibJson) {
  return ibGibJson.rel8ns.identity;
}

/**
 * Checks to see if the given `currentIdentityIbGibs` are authorized to Perform
 * an `AllowCommand` on the `adjunctTargetIbGibJson`.
 *
 * This is my only authorization function, so I'm just putting it in this
 * helper file for now. In the future, however, we should refactor this into its
 * own authorization module. This is especially true since the amount of
 * server-side code duplicated on the client will grow as we want to increase
 * distributed and disconnected processing, eventually to the point of
 * "duplicating" the engine. (It does not have to be an actual duplicate per se,
 * rather it should be able to have ib^gib addresses with data and hashes that
 * can interoperate with.)
 */
export function isAuthorizedToAllow(adjunctTargetIbGibJson, currentIdentityIbGibs) {
  let t = this;

  let targetIdentityIbGibs = getIdentityIbGibs(adjunctTargetIbGibJson);
  let targetAuthTier = _getHighestAuthTier(targetIdentityIbGibs);
  let targetTierValue = _tierValues[targetAuthTier];

  let currentAuthTier = _getHighestAuthTier(currentIdentityIbGibs);
  let currentTierValue = _tierValues[currentAuthTier];

  if (targetTierValue > currentTierValue) {
    // The target requires a higher level of authorization.
    return false; // unauthorized

  } else if (targetTierValue === 0) {
    // We're trying to allow an adjunct to an ibGib with only the root ib^gib
    // as its identity? That doesn't sound right, but I'm not 100% - we'll see.
    console.error(`${lc} error: cannot allow adjunct to a target with no authorization tier.`);
    return false; // unauthorized

  } else if (targetAuthTier === "session") {
    return _isAuthorizedToAllow_Session(targetIdentityIbGibs, currentIdentityIbGibs);

  } else if (targetAuthTier === "email") {
    return _isAuthorizedToAllow_Email(targetIdentityIbGibs, currentIdentityIbGibs);

  } else {
    // huh? How'd we get here? Should be logical impossibility.
    console.error(`${lc} My logic is bad...how'd we get here? targetAuthTier: ${targetAuthTier}. currentAuthTier: ${currentAuthTier}`);
    return false; // unauthorized
  }
}

function _isAuthorizedToAllow_Session(targetIdentityIbGibs, currentIdentityIbGibs) {
  let lc = `_isAuthorizedToAllow_Session`;

  // Usually (always?) there will be only one session. But regardless, if the
  // highest level is session, then only one of them has to match to be
  // authorized.
  let authorized =
    targetIdentityIbGibs
      .filter(targetIdentityIbGib => targetIdentityIbGib !== "ib^gib")
      .reduce((authorized, targetIdentityIbGib) => {
        if (authorized) {
          // bypass further checking since we know we're authorized
          return true;
        } else {
          // not yet authorized, so check if targetIdentityIbGib is included
          // in currentIdentityIbGibs
          return currentIdentityIbGibs.includes(targetIdentityIbGib);
        }
      }, false);

    // console.log(`${lc} authorized: ${authorized}. (requires one) targetIdentityIbGibs: ${JSON.stringify(targetIdentityIbGibs)}. (actual) currentIdentityIbGibs: ${JSON.stringify(currentIdentityIbGibs)}`);

    return authorized;
}

function _isAuthorizedToAllow_Email(targetIdentityIbGibs, currentIdentityIbGibs) {
  let lc = `_isAuthorizedToAllow_Email`;

  // only email identityIbGibs matter at "email" auth tier
  let targetIdentityIbGibs_Email =
    targetIdentityIbGibs
      .filter(identityIbGib => _getIdentityType(identityIbGib) === "email");

  // All target email identities must be present in the current identity ibGibs.
  let authorized =
    targetIdentityIbGibs_Email
      .every(targetIdentityIbGib => currentIdentityIbGibs.includes(targetIdentityIbGib));

  console.log(`${lc} authorized: ${authorized}. (requires all) targetIdentityIbGibs: ${JSON.stringify(targetIdentityIbGibs)}. (actual) currentIdentityIbGibs: ${JSON.stringify(currentIdentityIbGibs)}`);

  return authorized;
}

const _tierValues = {
  "ibgib": 0,
  "session": 1,
  "email": 2
}
// easier to just invert than anything fancy
const _tierValues_ByValue = {
  0: "ibgib",
  1: "session",
  2: "email"
}

function _getHighestAuthTier(identityIbGibs) {
  let lc = `_getHighestAuthTier`;

  let tierValue = identityIbGibs.reduce((highestTierValue, identityIbGib) => {
    let identityType = _getIdentityType(identityIbGib);
    let tierValue = _tierValues[identityType];
    return tierValue > highestTierValue ? tierValue : highestTierValue;
  }, 0);

  let highestAuthTier = _tierValues_ByValue[tierValue];

  // console.log(`${lc} highestAuthTier: ${highestAuthTier}. identityIbGibs: ${JSON.stringify(identityIbGibs)}`);

  return highestAuthTier;
}

function _getIdentityType(identityIbGib) {
  let lc = `_getIdentityType(${identityIbGib})`;

  if (identityIbGib === "ib^gib") {
    return "ibgib";
  } else {
    const identityTypeDelim = "_"
    let identityIb = getIbAndGib(identityIbGib).ib;
    let [identityType, _rest] = identityIb.split(identityTypeDelim);

    // console.log(`${lc} identityIb: ${identityIb}. identityType: ${identityType}`);

    return identityType;
  }
}
