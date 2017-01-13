import { huhText_Cmd_Fork } from "./huh-texts/commands/fork";
import { huhText_Cmd_Pic } from "./huh-texts/commands/pic";
import { huhText_Cmd_Comment } from "./huh-texts/commands/comment";
import { huhText_Cmd_Link } from "./huh-texts/commands/link";
import { huhText_Cmd_Huh } from "./huh-texts/commands/huh";
import { huhText_Cmd_Ack } from "./huh-texts/commands/ack";
import { huhText_Cmd_Add } from "./huh-texts/commands/add";
import { huhText_Cmd_Download } from "./huh-texts/commands/download";
import { huhText_Cmd_IdentEmail } from "./huh-texts/commands/ident-email";
import { huhText_Cmd_Info } from "./huh-texts/commands/info";

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
  "context": 5,
  "root": 3,
  "cmd": 1.5,
  "virtual": 1,
  "text": 3,
  "image": 3,
  "source": 4,
  "ibGib": 1.5,
  "rel8n": 1.5,
  "result": 2,
  "ib^gib": 2,
  "pic": 3,
  "link": 4,
  "result": 3,
  "comment": 3,
  "default": 2
};

let d3Colors = {
  "context": "#F2EC41",
  "dna": "#C5DADE",
  "ancestor": "lightgray",
  "past": "#A9CBD6",
  "ib": "#F2EC41",
  "ibGib": "#76963e",
  "result": "#86CC6C",
  "ib^gib": "#73BFAE",
  "comment": "#CCF26B",
  "text": "#A7D169",
  "name": "#FFDFAB",
  "pic": "#DDEDD3",
  "image": "#DDEDD3",
  "img": "#DDEDD3",
  "identity": "#FFFFFF",
  "huh": "#EBFF0F",
  "help": "#EBFF0F",
  "query": "#C7FF4F",
  "default": "#8EFAD3",

  "imageBorder": "#3CAA71",
  "textBorder": "#8F26A3",
  "rootBorder": "#12F50A",
  "defaultBorder": "#ED6DCD"
};

var d3BoringRel8ns = [
  "ancestor",
  "past",
  "dna",
  "query",
  "ib^gib",
  "identity"
];

/** Rel8ns that should always be showing when user clicks node. */
var d3AlwaysRel8ns = [
  "pic",
  "link",
  "comment",
];

var d3RequireExpandLevel2 = [
  "ancestor",
  "past",
  "dna",
  "query",
  "ib^gib",
  "identity"
];

/**
 * For commands with a details view, the corresponding view is located in
 * `web/components/details/cmdname.ex`.
 */
var d3MenuCommands = [
  {
    "id": "menu-fork",
    "name": "fork",
    "text": "Fork",
    "icon": "\uf259",
    "description": "The Fork button will take the selected ibGib and create a new one based on it in your personal ib space. It's like making a copy at that point in time and branching off of it. Live Long and Prosper!",
    "color": "#61B9FF",
    "huh": huhText_Cmd_Fork
  },
  {
    "id": "menu-pic",
    "name": "pic",
    "text": "Pic",
    "icon": "\uf03e",
    "description": "The Picture button will add a picture to the selected ibGib. You can choose to upload a file, or take a picture with your camera. You can even add pictures to pictures",
    "color": "#61B9FF",
    "huh": huhText_Cmd_Pic
  },
  {
    "id": "menu-comment",
    "name": "comment",
    "text": "Comment",
    "icon": "\uf075",
    "description": "The Comment button adds a comment (or any text really) to the selected ibGib",
    "color": "#61B9FF",
    "huh": huhText_Cmd_Comment
  },
  {
    "id": "menu-link",
    "name": "link",
    "text": "Link",
    "icon": "\uf0c1",
    "description": "The Link button will add a hyperlink from the World Wide interWeb to the selected ibGib",
    "color": "#61B9FF",
    "huh": huhText_Cmd_Link
  },
  {
    "id": "menu-huh",
    "name": "huh",
    "text": "Huh?",
    "icon": "\uf128 \uf12a \uf128",
    "description": "This is like in-depth help. Click it when you have no idea what is going on.",
    "color": "#EBFF0F",
    "huh": huhText_Cmd_Huh
  },
  {
    "id": "menu-mut8comment",
    "name": "mut8comment",
    "text": "Mut8 Comment",
    "icon": "\u2622",
    "description": "The Mut8 button will allow you to edit the ibGib",
    "color": "lightblue"
  },
  {
    "id": "menu-view",
    "name": "view",
    "text": "View",
    "icon": "\uf06e", // :eye: 
    "description": "The View button will lets you look more closely at the ibGib.",
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
    "description": "The goto button will navigate you to the selected ibGib. ",
    "color": "#C7FF4F"
  },
  {
    "id": "menu-info",
    "name": "info",
    "text": "Info",
    "icon": "\uf05a",
    "description": "The Information button lets you see the internal gibblies of an ibGib",
    "color": "#CFA1C8",
    "huh": huhText_Cmd_Info
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
    "color": "#FFFFFF",
    "huh": huhText_Cmd_IdentEmail
  },
  {
    "id": "menu-refresh",
    "name": "refresh",
    "text": "Refresh ibGib",
    "icon": "\uf021",
    "description": "The Refresh button refreshes the selected ibGib to the most up-to-date version",
    "color": "#C7FF4F",
    "huh": [
      `Time is a big deal in ibGib.`,
      ` `,
      `Every ibGib that you look at is kinda like a cartoon. Each ibGib has a snapshot that is a single frame in time, and at any one point in time you're just looking at that snapshot.`,
      ``,
      `Refresh brings you to the most recent snapshot in a timeline.`,
      ``,
      `...Wait...timeline? Huh?`,
      ``,
      `You can fork ibGib timelines with the "Fork" command. When you do this, you create a **new** timeline for the "same" thing. So when you do a Refresh on an ibGib, it always gets you the most recent version **in that timeline**.`,
      ``,
      `For more info on timelines, check out the "Fork" command's Huh?!? (It's the funny "Spock Hand" command).`,
      ``,
      `Also, every time you refresh a _Source_ ibGib (The big-ish, non-yellow free-floating ibGibs), any updates will update your current _Context_ ibGib (The BIG yellow ibGib).`,
      ``,
      `For more info on the Context ibGib, check out its Huh?!? by clicking on the BIG yellow ibGib and choosing the ""\uf128 \uf12a \uf128" button`,
      `It's basically like Back To The Future II. If you haven't, go watch that movie (like right now). I'll wait...`,
      ``,
      `Now that you've seen that movie and are thus an Alternate Timeline Expert, we can talk using that vocabulary. So when they first go into the Future, that is their current "Hill Valley" ibGib timeline. Then future Old Biff takes the Delorian back in time and **forks`,
    ]
  },
  {
    "id": "menu-download",
    "name": "download",
    "text": "Download from the Cloud",
    "icon": "\uf0ed",
    "description": "The Cloud Download button saves the pic/file to your local device",
    "color": "#CFA1C8",
    "huh": huhText_Cmd_Download
  },
  {
    "id": "menu-zap",
    "name": "zap",
    "text": "Zap",
    "icon": "\uf0e7",
    "description": "Zaps virtual ibGib with some juice \u26a1",
    "color": "yellow",
  },
  {
    "id": "menu-add",
    "name": "add",
    "text": "Add ibGib",
    // http://www.alt-codes.net/plus-sign-symbols
    "icon": "\uf067", // http://fontawesome.io/icon/plus/
    "description": "Creates and adds a new ibGib with a given rel8n.",
    "color": "#C7FF4F",
    "huh": huhText_Cmd_Add
  },
  {
    "id": "menu-ack",
    "name": "ack",
    "text": "Acknowledge",
    // http://www.fileformat.info/info/unicode/char/2713/index.htm
    "icon": "\u2713", // ✓ (check mark)
    "description": "Acknowledge an ibGib that has been created by someone else to be directly rel8d to your ibGib.",
    "color": "#C7FF4F",
    "huh": huhText_Cmd_Ack
  },
  // {
  //   "id": "menu-merge",
  //   "name": "merge",
  //   "text": "Merge",
  //   "icon": "\uf247",
  //   "description": "Merging is how we relate existing ibGib to each other",
  //   "color": "lightblue"
  // },
  // {
  //   "id": "menu-help",
  //   "name": "help",
  //   "text": "Help",
  //   "icon": "\uf29c",
  //   "description": "The Help button shows you help about the selected ibGib",
  //   "color": "#EBFF0F"
  // },
  // {
  //   "id": "menu-share",
  //   "name": "share",
  //   "text": "Share",
  //   "icon": "\uf1e0",
  //   "description": "The Share button will share a link to this ibGib to others",
  //   "color": "gold"
  // },
  // {
  //   "id": "menu-star",
  //   "name": "star",
  //   "text": "Star",
  //   "icon": "\uf005",
  //   "description": "The Star button will rate the selected ibGib",
  //   "color": "gold"
  // },
  // {
  //   "id": "menu-flag",
  //   "name": "flag",
  //   "text": "Flag",
  //   "icon": "\uf024",
  //   "description": "The Flag button will mark the selected ibGib as containing inappropriate content",
  //   "color": "#FF4F4F"
  // },
  // {
  //   "id": "menu-thumbsup",
  //   "name": "thumbs up",
  //   "text": "Thumbs up",
  //   "icon": "\uf087",
  //   "description": "The Thumbs Up button will let you give the selected ibGib a Thumbs Up",
  //   "color": "gold"
  // },
  // {
  //   "id": "menu-meta",
  //   "name": "meta",
  //   "text": "Meta",
  //   "icon": "\uf013",
  //   "description": "The Meta button contains settings, tweaks, preferences, etc",
  //   "color": "lightgray"
  // },
  // {
  //   "id": "menu-fullscreen",
  //   "name": "fullscreen",
  //   "text": "View Fullscreen",
  //   "icon": "\uf0b2",
  //   "description": "The Fullscreen button will view something in fullscreen",
  //   "color": "#CFA1C8"
  // },
];

let d3Rel8nIcons = {
  "identity": "\uf007",
  "pic": "\uf03e",
  "comment": "\uf075",
  "past": "\uf100",
  "ancestor": "\uf102",
  "instance": "\uf107",
  "result": "\uf1c0",
  "verse": "\uf30c",
  "link": "\uf0c1", // 🔗 (font awesome)
  // "ib^gib": "\u29c2",
  "ib^gib": d3RootUnicodeChar,
  "dna": "➿",
  "adjunct": "\uf01c", // Font awesome inbox, unicode one is -> 📥
  "identity_session": "\uf21b"
};

var d3RootUnicodeChar = "\uf10c";
// var d3RootUnicodeChar = "\u2723";

// Addable rel8ns are rel8ns that can be added to any ibGib. For example,
// any ibGib can be commented on, even if there are no existing comment rel8ns.
// So the "comment" rel8n should always show up with at least an "add" virtual
// command.
var d3AddableRel8ns = [
  "pic",
  "link",
  "comment",
]

var d3PausedRel8ns = [
  "past",
  "dna"
]

export { d3CircleRadius, d3LongPressMs, d3DblClickMs, d3LinkDistances, d3Scales, d3Colors, d3BoringRel8ns, d3AlwaysRel8ns, d3RequireExpandLevel2, d3MenuCommands, d3Rel8nIcons, d3RootUnicodeChar, d3AddableRel8ns, d3PausedRel8ns };
0
