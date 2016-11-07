var spokenAppName = "ib jib";
var spokenAppNameSsml = "ib jib";


/** Represents information for a given FSM-ish Context. */
export interface AlexaContextData {
    id: string,
    spokenContext: string,
    // spokenContextSsml?: string,
    spokenExampleCmds: string[]
    // spokenExampleCmdsSsml?: string[]
}

/** Enumeration of `AlexaContextData` */
export var ALEXA_CONTEXT_DATA: AlexaContextData[] = [
    {
        "id": "launched", 
        "spokenContext": "home",
        "spokenExampleCmds": [
            "Open my shopping list",
            "Read my todo list"
        ]
    },
    {
        "id": "root", 
        "spokenContext": "root",
        "spokenExampleCmds": [
            "Open my shopping list",
            "Read my todo list"
        ]
    },
    {
        "id": "jib-opened", 
        "spokenContext": "jib opened",
        "spokenExampleCmds": [
            "Close the list",
            "Read the list"
        ]
    }
];
