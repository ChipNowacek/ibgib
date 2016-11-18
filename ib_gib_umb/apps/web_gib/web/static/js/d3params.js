var d3CircleRadius = 20;
var d3LongPressMs = 900;
var d3DblClickMs = 200;

let d3LinkDistances = {
  "special": 90,
  "specialMember": 30,
  "rel8n": 50,
  "default": 80
}

let d3Scales = {
  "rel8n": 1.5,
  "dna": 1,
  "ancestor": 1,
  "past": 2,
  "ib": 5,
  "ibGib": 4,
  "result": 2,
  // "rel8d": 3,
  "ib^gib": 3,
  "pic": 3,
  "link": 3,
  "result": 3,
  "comment": 3,
  "default": 2
};

let d3Colors = {
  // "rel8n": "#C3ECFA",
  "dna": "#C5DADE",
  "ancestor": "lightgray",
  "past": "#A9CBD6",
  "ib": "#F2EC41",
  "ibGib": "#76963e",
  "result": "#86CC6C",
  // "rel8d": "#FFDFAB",
  "ib^gib": "#73BFAE",
  "comment": "#CCF26B",
  "text": "#CCF26B",
  "name": "#FFDFAB",
  "pic": "#DDEDD3",
  "image": "#DDEDD3",
  "img": "#DDEDD3",
  "identity": "#FFFFFF",
  "default": "#AEA6E3",

  "imageBorder": "#3CAA71",
  "textBorder": "#8F26A3",
  "rootBorder": "#12F50A",
  "defaultBorder": "#ED6DCD"
};

var d3DefaultCollapsed = [
  "ancestor",
  "past",
  "dna",
  "query",
  // "rel8d",
  "ib^gib",
  "identity"
];

var d3RequireExpandLevel2 = [
  "ancestor",
  "past",
  "dna",
  "query",
  // "rel8d",
  "ib^gib",
  "identity"
];

var d3MenuCommands = [
  {
    "id": "menu-pic",
    "name": "pic",
    "text": "Pic",
    "icon": "\uf03e",
    "description": "The Picture button will add a picture to the selected ibGib. You can choose to upload a file, or take a picture with your camera. You can even add pictures to pictures",
    "color": "#61B9FF"
  },
  {
    "id": "menu-info",
    "name": "info",
    "text": "Info",
    "icon": "\uf05a",
    "description": "The Information button lets you see the internal gibblies of an ibGib",
    "color": "#CFA1C8"
  },
  {
    "id": "menu-merge",
    "name": "merge",
    "text": "Merge",
    "icon": "\uf247",
    "description": "Merging is how we relate existing ibGib to each other",
    "color": "lightblue"
  },
  {
    "id": "menu-help",
    "name": "help",
    "text": "Help",
    "icon": "\uf29c",
    "description": "The Help button shows you help about the selected ibGib",
    "color": "#EBFF0F"
  },
  {
    "id": "menu-share",
    "name": "share",
    "text": "Share",
    "icon": "\uf1e0",
    "description": "The Share button will share a link to this ibGib to others",
    "color": "gold"
  },
  {
    "id": "menu-comment",
    "name": "comment",
    "text": "Comment",
    "icon": "\uf075",
    "description": "The Comment button adds a comment (or any text really) to the selected ibGib",
    "color": "#61B9FF"
  },
  {
    "id": "menu-star",
    "name": "star",
    "text": "Star",
    "icon": "\uf005",
    "description": "The Star button will rate the selected ibGib",
    "color": "gold"
  },
  {
    "id": "menu-fork",
    "name": "fork",
    "text": "Fork",
    "icon": "\uf259",
    "description": "The Fork button will take the selected ibGib and create a new one based on it in your personal ib space. Live Long and Prosper!",
    "color": "#61B9FF"
  },
  {
    "id": "menu-flag",
    "name": "flag",
    "text": "Flag",
    "icon": "\uf024",
    "description": "The Flag button will mark the selected ibGib as containing inappropriate content",
    "color": "#FF4F4F"
  },
  {
    "id": "menu-thumbsup",
    "name": "thumbs up",
    "text": "Thumbs up",
    "icon": "\uf087",
    "description": "The Thumbs Up button will let you give the selected ibGib a Thumbs Up",
    "color": "gold"
  },
  {
    "id": "menu-link",
    "name": "link",
    "text": "Link",
    "icon": "\uf0c1",
    "description": "The Link button will add a hyperlink from the World Wide interWeb to the selected ibGib",
    "color": "#61B9FF"
  },
  {
    "id": "menu-meta",
    "name": "meta",
    "text": "Meta",
    "icon": "\uf013",
    "description": "The Meta button contains settings, tweaks, preferences, etc",
    "color": "lightgray"
  },
  {
    "id": "menu-mut8",
    "name": "mut8",
    "text": "Mut8",
    "icon": "\u2622",
    "description": "The Mut8 button will allow you to edit the selected ibGib",
    "color": "lightblue"
  },
  {
    "id": "menu-view",
    "name": "view",
    "text": "View",
    "icon": "\uf06e",
    "description": "The View button will show/hide the selected ibGib's children",
    "color": "#CFA1C8"
  },
  {
    "id": "menu-query",
    "name": "query",
    "text": "Query",
    "icon": "\uf002",
    "description": "The Query button will show you a search screen where you can look for other ibGib",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-goto",
    "name": "goto",
    "text": "Goto",
    "icon": "\uf0a6",
    "description": "The Goto button will navigate you to the selected ibGib",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-fullscreen",
    "name": "fullscreen",
    "text": "View Fullscreen",
    "icon": "\uf0b2",
    "description": "The Fullscreen button will view something in fullscreen",
    "color": "#CFA1C8"
  },
  {
    "id": "menu-externallink",
    "name": "externallink",
    "text": "Open external link",
    "icon": "\uf08e",
    "description": "The Open Link button will open a link in your browser",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-identemail",
    "name": "identemail",
    "text": "Login via email",
    "icon": "\uf090",
    "description": "The Login button will let you identify yourself with an email address",
    "color": "#FFFFFF"
  },
  {
    "id": "menu-refresh",
    "name": "refresh",
    "text": "Refresh ibGib",
    "icon": "\uf021",
    "description": "The Refresh button refreshes the selected ibGib to the most up-to-date version",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-download",
    "name": "download",
    "text": "Download from the Cloud",
    "icon": "\uf0ed",
    "description": "The Cloud Download button saves the pic/file to your local device",
    "color": "#CFA1C8"
  }
];

export { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3RequireExpandLevel2, d3MenuCommands };
