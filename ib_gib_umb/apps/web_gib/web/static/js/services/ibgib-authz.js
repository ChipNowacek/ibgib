import * as ibHelper from './ibgib-helper';

/**
 * Checks to see if the given `currentIdentityIbGibs` are authorized to Perform
 * an `AckCommand` on the `targetIbGibJson`.
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
export function isAuthorizedForMut8OrRel8(targetIbGibJson, currentIdentityIbGibs) {
  let t = this;

  let targetIdentityIbGibs = ibHelper.getIdentityIbGibs(targetIbGibJson);
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
    return _isAuthorizedForMut8OrRel8_Session(targetIdentityIbGibs, currentIdentityIbGibs);

  } else if (targetAuthTier === "email") {
    return _isAuthorizedForMut8OrRel8_Email(targetIdentityIbGibs, currentIdentityIbGibs);

  } else {
    // huh? How'd we get here? Should be logical impossibility.
    console.error(`${lc} My logic is bad...how'd we get here? targetAuthTier: ${targetAuthTier}. currentAuthTier: ${currentAuthTier}`);
    return false; // unauthorized
  }
}

export function isIdentifiedByEmail(currentIdentityIbGibs) {
  let highestAuthTier = _getHighestAuthTier(currentIdentityIbGibs);
  return highestAuthTier === "email";
}

function _isAuthorizedForMut8OrRel8_Session(targetIdentityIbGibs, currentIdentityIbGibs) {
  let lc = `_isAuthorizedForMut8OrRel8_Session`;

  // Usually (always?) there will be only one session. But regardless, if the
  // highest level is session, then only one of them has to match to be
  // authorized.
  let authorized =
    targetIdentityIbGibs
      // .filter(targetIdentityIbGib => targetIdentityIbGib !== "ib^gib")
      .filter(targetIdentityIbGib => getIdentityType(targetIdentityIbGib) === "session")
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

function _isAuthorizedForMut8OrRel8_Email(targetIdentityIbGibs, currentIdentityIbGibs) {
  let lc = `_isAuthorizedForMut8OrRel8_Email`;

  // only email identityIbGibs matter at "email" auth tier
  let targetIdentityIbGibs_Email =
    targetIdentityIbGibs
      .filter(identityIbGib => getIdentityType(identityIbGib) === "email");

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
    let identityType = getIdentityType(identityIbGib);
    let tierValue = _tierValues[identityType];
    return tierValue > highestTierValue ? tierValue : highestTierValue;
  }, 0);

  let highestAuthTier = _tierValues_ByValue[tierValue];

  // console.log(`${lc} highestAuthTier: ${highestAuthTier}. identityIbGibs: ${JSON.stringify(identityIbGibs)}`);

  return highestAuthTier;
}

export function getIdentityType(identityIbGib) {
  let lc = `getIdentityType(${identityIbGib})`;

  if (identityIbGib === "ib^gib") {
    return "ibgib";
  } else {
    const identityTypeDelim = "_"
    let identityIb = ibHelper.getIbAndGib(identityIbGib).ib;
    let [identityType, _rest] = identityIb.split(identityTypeDelim);

    // console.log(`${lc} identityIb: ${identityIb}. identityType: ${identityType}`);

    return identityType;
  }
}

export function isEmailIdentity(ibGibJson) {
  let { ib, gib, rel8ns, data } = ibGibJson;
  return ib.startsWith("email_") &&
         gib.startsWith("ibGib_") && 
         rel8ns.instance_of &&
         rel8ns.instance_of.length === 1 && 
         rel8ns.instance_of[0] === "identity^gib" &&
         data.type === "email";
}
