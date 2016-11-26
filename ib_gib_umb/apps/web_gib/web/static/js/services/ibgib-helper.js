export function getFull_ibGib(ibGibJson) {
  return ibGibJson.ib + "^" + ibGibJson.gib;
}

export function getIbAndGib(ibGib) {
  if (ibGib) {
    let [ib, gib] = ibGib.split("^");
    return {ib: ib, gib: gib};
  } else {
    console.error("getIbAndGib: ibGib not provided.");
  }
}


export function getDataText(ibGibJson) {
  return (ibGibJson && ibGibJson.data && ibGibJson.data.text) ?
      ibGibJson.data.text :
      null;
}

export function getRandomString() {
  return Math.trunc(Math.random() * 10000000).toString();
}
