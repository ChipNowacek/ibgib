export function getFull_ibGib(ibGibJson) {
  return ibGibJson.ib + "^" + ibGibJson.gib;
}

export function getDataText(ibGibJson) {
  return (ibGibJson && ibGibJson.data && ibGibJson.data.text) ?
      ibGibJson.data.text :
      null;
}

export function getRandomString() {
  return Math.trunc(Math.random() * 10000000).toString();
}
