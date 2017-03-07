import $ from 'jquery';
import textcomplete from 'jquery-textcomplete';
import { emojies } from '../textcomplete/emoji';

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
 * this returns the current ibGib (i.e. "no past", so return the present)
 */
export function getTemporalJunctionIbGib(ibGibJson) {
  let ibGib = getFull_ibGib(ibGibJson);
  if (ibGib === "ib^gib") {
    return ibGib;
  } else {
    // makes a copy, splice off the head which is the root (and never the temporal junction point)
    let past = ibGibJson.rel8ns.past.concat().splice(1); 
    
    if (isImage(ibGibJson) || isComment(ibGibJson) || isLink(ibGibJson)) {
      // We need special handling for pics, comments, links, because the first
      // non-root in the history is actually a "blank", with empty `data`. So,
      // in older versions, it is the same thing. In the current version they're
      // unique, but we don't want to count on that at the moment. So we'll just 
      // ignore this first "blank" anyway
      past = past.splice(1);
    }
    
    return past.length > 0 ? past[0] : ibGib;
  }
}

export function isInPast(ibGibJson, ibGib) {
  return ibGibJson && ibGibJson.rel8ns && ibGibJson.rel8ns["past"] && ibGibJson.rel8ns["past"].includes(ibGib);
}

export function isDirectlyRel8d(ibGibJson, ibGib) {
  return Object.keys(ibGibJson.rel8ns)
               .map(key => ibGibJson.rel8ns[key])
               .some(rel8nIbGibs => rel8nIbGibs.includes(ibGib));
}

export function isDirectlyRel8dToAny(ibGibJson, ibGibs) {
  return ibGibs.some(ibGib => {
    
    return ibGib !== "ib^gib" &&
           Object.keys(ibGibJson.rel8ns)
                 .map(key => ibGibJson.rel8ns[key])
                 .some(rel8nIbGibs => rel8nIbGibs.includes(ibGib));
  })
}

export function getRel8dIbGibs(ibGibJson, rel8nName) {
  if (ibGibJson && ibGibJson.rel8ns) {
    return ibGibJson.rel8ns[rel8nName] || []; 
  } else {
    console.error(`ibGibJson and ibGibJson.rel8ns assumed to be populated.`)
  }
}

/** 
 * For safe access to ibGibJson.data.text.
 * ATOW 2/13/
 */
export function getDataText(ibGibJson) {
  return (ibGibJson && ibGibJson.data && ibGibJson.data.text) ?
      ibGibJson.data.text :
      null;
}

/** 
 * For safe access to ibGibJson.data.text.
 * ATOW 2/13/
 */
export function getDataQueryResultCount(ibGibJson) {
  return (ibGibJson && ibGibJson.ib === "query_result" && ibGibJson.data && ibGibJson.data.result_count) ?
      ibGibJson.data.result_count :
      -1;
}

export function getTagIconsText(ibGibJson) {
  return (ibGibJson && ibGibJson.data && ibGibJson.data.icons) ?
      ibGibJson.data.icons :
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

export function isComment(ibGibJson) {
  let result = false;

  if (ibGibJson.ib === "comment") {
    result = true;
  } else {
    // check the ancestry to see if those are comments, because
    // maybe this comment has just been forked.
    let ancestors = ibGibJson.rel8ns["ancestor"];
    for (var i = 0; i < ancestors.length; i++) {
      let { ancestorIb } = getIbAndGib(ancestors[i]);
      if (ancestorIb === "comment" && ibGibJson.data.text) {
        result = true;
        break;
      }
    }
  }

  return result;
}

export function isImage(ibGibJson) {
  let result = false;

  if (ibGibJson.ib === "pic") {
    result = true;
  } else if (ibGibJson.data.content_type &&
             ibGibJson.data.content_type.substring(0,6) === "image/" &&
             ibGibJson.data.bin_id &&
             ibGibJson.data.filename &&
             ibGibJson.data.ext) {
    result = true;
  }

  return result;
}

export function isLink(ibGibJson) {
  let result = false;

  result = (ibGibJson.rel8ns.instance_of &&
            ibGibJson.rel8ns.instance_of[0] === "link^gib") ||
           ibGibJson.data.render === "link";

  return result;
}

export function isIdentity(ibGibJson) {
  return ibGibJson.rel8ns.instance_of &&
         ibGibJson.rel8ns.instance_of[0] === "identity^gib";
}

export function isTag(ibGibJson) {
  return ibGibJson.rel8ns.ancestor.some(x => x === "tag^gib");
}

/*
 * Determines if the browser is on a mobile device or not.
 * Thanks SO!
 * http://stackoverflow.com/questions/3514784/what-is-the-best-way-to-detect-a-mobile-device-in-jquery
 */
export function isMobile() {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
}

export function initAutocomplete(textAreaId) {
    let t = this, lc = `Comment initAutocomplete`;
    console.log(`{lc} initializing Autocomplete starting...`)
    
    $('#' + textAreaId).textcomplete([
      { // emoji strategy
          id: 'emoji',
          match: /\B:([\-+\w]*)$/,
          search: function (term, callback) {
              callback($.map(emojies, function (emoji) {
                  return emoji.indexOf(term) === 0 ? emoji : null;
              }));
          },
          template: function (value) {
              return '<img src="/images/emoji/' + value + '.png" class="ib-emoji-list"></img>' + value;
          },
          replace: function (value) {
              return ':' + value + ': ';
          },
          index: 1
      }
    ], {
        onKeydown: function (e, commands) {
            if (e.ctrlKey && e.keyCode === 74) { // CTRL-J
                return commands.KEY_ENTER;
            }
        }
    });
    
    console.log(`{lc} initializing Autocomplete complete.`)
  }
