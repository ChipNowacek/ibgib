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

var d3MenuCommands = [
  {
    "id": "menu-pic",
    "name": "pic",
    "text": "Pic",
    "icon": "\uf03e",
    "color": "#1DA8A8"
  },
  {
    "id": "menu-info",
    "name": "info",
    "text": "Info",
    "icon": "\uf05a",
    "color": "#CFA1C8"
  },
  {
    "id": "menu-merge",
    "name": "merge",
    "text": "Merge",
    "icon": "\uf247",
    "color": "lightblue"
  },
  {
    "id": "menu-help",
    "name": "help",
    "text": "Help",
    "icon": "\uf29c",
    "color": "#E8AC4A"
  },
  {
    "id": "menu-share",
    "name": "share",
    "text": "Share",
    "icon": "\uf1e0",
    "color": "gold"
  },
  {
    "id": "menu-comment",
    "name": "comment",
    "text": "Comment",
    "icon": "\uf075",
    "color": "#1DA8A8"
  },
  {
    "id": "menu-star",
    "name": "star",
    "text": "Star",
    "icon": "\uf005",
    "color": "gold"
  },
  {
    "id": "menu-fork",
    "name": "fork",
    "text": "Fork",
    "icon": "\uf259",
    "color": "lightblue"
  },
  {
    "id": "menu-flag",
    "name": "flag",
    "text": "Flag",
    "icon": "\uf024",
    "color": "#FF4F4F"
  },
  {
    "id": "menu-thumbsup",
    "name": "thumbs up",
    "text": "Thumbs up",
    "icon": "\uf087",
    "color": "gold"
  },
  {
    "id": "menu-link",
    "name": "link",
    "text": "Link",
    "icon": "\uf0c1",
    "color": "#1DA8A8"
  },
  {
    "id": "menu-meta",
    "name": "meta",
    "text": "Meta",
    "icon": "\uf013",
    "color": "lightgray"
  },
  {
    "id": "menu-mut8",
    "name": "mut8",
    "text": "Mut8",
    "icon": "\u2622",
    "color": "lightblue"
  },
  {
    "id": "menu-view",
    "name": "view",
    "text": "View",
    "icon": "\uf06e",
    "color": "pink"
  },
  {
    "id": "menu-query",
    "name": "query",
    "text": "Query",
    "icon": "\uf002",
    "color": "#C7FF4F"
  }
];

export { d3CircleRadius, d3Scales, d3Colors, d3MenuCommands };
