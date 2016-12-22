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
