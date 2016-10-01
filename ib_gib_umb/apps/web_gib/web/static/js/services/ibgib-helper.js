export function getFull_ibGib(ibGibJson) {
  return ibGibJson.ib + "^" + ibGibJson.gib;
}

export function getDataText(ibGibJson) {
  return (ibGibJson && ibGibJson.data && ibGibJson.data.text) ?
      ibGibJson.data.text :
      null;
}
