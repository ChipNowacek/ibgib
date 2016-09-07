var d3CircleRadius = 10;

let d3Scales = {
  "rel8n": 1.2,
  "dna": .5,
  "ancestor": .5,
  "past": 1,
  "ib": 3,
  "ibGib": 5,
  "result": 2
};

let d3Colors = {
  // "rel8n": "#C3ECFA",
  "dna": "#FFD5CC",
  "ancestor": "gray",
  "past": "black",
  "ib": "#F2EC41",
  "ibGib": "#76963e",
  "result": "#FAD98C",
  "default": "#ECC3FA"
};

let d3Menu = {
  "nodes": [
    {
      "id": "help", 
      "name": "help",
      "text": "help"
    }
  ]
}

export { d3CircleRadius, d3Scales, d3Colors };
