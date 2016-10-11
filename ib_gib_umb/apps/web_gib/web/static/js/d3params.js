var d3CircleRadius = 10;
var d3LongPressMs = 700;

let d3LinkDistances = {
  "special": 120,
  "specialMember": 30,
  "rel8n": 50,
  "default": 80
}

let d3Scales = {
  "rel8n": 1,
  "dna": 1,
  "ancestor": 1,
  "past": 2,
  "ib": 5,
  "ibGib": 4,
  "result": 2,
  "rel8d": 2,
  "pic": 3,
  "default": 2
};

let d3Colors = {
  // "rel8n": "#C3ECFA",
  "dna": "#C5DADE",
  "ancestor": "lightgray",
  "past": "#A9CBD6",
  "comment": "#CFF097",
  "ib": "#F2EC41",
  "ibGib": "#76963e",
  "result": "#3088FC",
  "rel8d": "#FFDFAB",
  "text": "#FFDFAB",
  "name": "#FFDFAB",
  "pic": "#ABCBFF",
  "image": "#ABCBFF",
  "img": "#ABCBFF",
  "identity": "#404040",
  "default": "#AEA6E3"
};

var d3DefaultCollapsed = [
  "ancestor",
  "past",
  "dna",
  "query",
  "rel8d",
  "identity"
];

var d3MenuCommands = [
  {
    "id": "menu-pic",
    "name": "pic",
    "text": "Pic",
    "icon": "\uf03e",
    "description": "This will let you upload an image or link to an existing one online",
    "color": "#1DA8A8"
  },
  {
    "id": "menu-info",
    "name": "info",
    "text": "Info",
    "icon": "\uf05a",
    "description": "This lets you see additional information, like when this ibGib was created",
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
    "description": "This shows general help information for the available commands",
    "color": "#E8AC4A"
  },
  {
    "id": "menu-share",
    "name": "share",
    "text": "Share",
    "icon": "\uf1e0",
    "description": "Share this ibGib with others on things like Facebook or Twitter",
    "color": "gold"
  },
  {
    "id": "menu-comment",
    "name": "comment",
    "text": "Comment",
    "icon": "\uf075",
    "description": "Add a comment (or any text really) to this ibGib",
    "color": "#1DA8A8"
  },
  {
    "id": "menu-star",
    "name": "star",
    "text": "Star",
    "icon": "\uf005",
    "description": "Give this ibGib a rating",
    "color": "gold"
  },
  {
    "id": "menu-fork",
    "name": "fork",
    "text": "Fork",
    "icon": "\uf259",
    "description": "Ah, forking...this is how you create a 'new' ibGib or copy from an existing one. You will be using this a lot",
    "color": "lightblue"
  },
  {
    "id": "menu-flag",
    "name": "flag",
    "text": "Flag",
    "icon": "\uf024",
    "description": "Flag this ibGib as having inappropriate content",
    "color": "#FF4F4F"
  },
  {
    "id": "menu-thumbsup",
    "name": "thumbs up",
    "text": "Thumbs up",
    "icon": "\uf087",
    "description": "Give it the thumbs up yo",
    "color": "gold"
  },
  {
    "id": "menu-link",
    "name": "link",
    "text": "Link",
    "icon": "\uf0c1",
    "description": "Add a hyperlink from the world wide interweb",
    "color": "#1DA8A8"
  },
  {
    "id": "menu-meta",
    "name": "meta",
    "text": "Meta",
    "icon": "\uf013",
    "description": "This contains settings, tweaks, preferences, et cetera, et cetera",
    "color": "lightgray"
  },
  {
    "id": "menu-mut8",
    "name": "mut8",
    "text": "Mut8",
    "icon": "\u2622",
    "description": "This will allow you to edit an existing ibGib",
    "color": "lightblue"
  },
  {
    "id": "menu-view",
    "name": "view",
    "text": "View",
    "icon": "\uf06e",
    "description": "Expand/collapse an ibGib's visible children",
    "color": "pink"
  },
  {
    "id": "menu-query",
    "name": "query",
    "text": "Query",
    "icon": "\uf002",
    "description": "Create a query to look for other ibGib",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-goto",
    "name": "goto",
    "text": "Goto",
    "icon": "\uf0a6",
    "description": "Navigate to the ibGib",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-fullscreen",
    "name": "fullscreen",
    "text": "View Fullscreen",
    "icon": "\uf0b2",
    "description": "View fullscreen",
    "color": "pink"
  },
  {
    "id": "menu-externallink",
    "name": "externallink",
    "text": "Open external link.",
    "icon": "\uf08e",
    "description": "Open external link",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-identemail",
    "name": "identemail",
    "text": "Login via email",
    "icon": "\uf090",
    "description": "Sends an email containing a link to login",
    "color": "#FFFFFF"
  }
];

export { d3CircleRadius, d3LongPressMs, d3LinkDistances, d3Scales, d3Colors, d3DefaultCollapsed, d3MenuCommands };
