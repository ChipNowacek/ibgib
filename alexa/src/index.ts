/**
 * This is a TypeScript version started with the Space Geek template by
 * Amazon. They use Apache 2.0 license. I use MIT.
 *
 * The apache 2.0 note from Amazon is as follows:
 */

/**
    Copyright 2014-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.

    Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

        http://aws.amazon.com/apache2.0/

    or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

/**
 * Not sure what I'm doing at the moment!... :thinking:
 */
import * as data from './data';
import { Helper } from './helper'; // logging, utilities

/**
 * App ID for the skill. This is kept private, outside of version control storage, as
 * this is an open-source app.
 */
import { APP_ID } from './private/constants';

/**
 * Imports the askGib library, which has AlexaSkill and Amazon Skills Kit (ask) declarations.
 */
import * as ask from 'ask-gib';

/**
 * Primary class of our Skill called "ibGib".
 *
 * This is based off of code from Amazon's Space Geeks example.
 */
class IbGibAlexa extends ask.AlexaSkill {
    /**
     * @param appId e.g. amzn1.echo-sdk-ams.app.[your-unique-value-here]
     */
    constructor(appId: string) {
        super(appId);

        this._helper = new Helper();

        let logContext = `IbGibAlexa.ctor`;
        var helper = this._helper;
        var t: IbGibAlexa = this;
        this._helper.logFuncStart(logContext);

        try {
            this.eventHandlers.onSessionStarted = function (sessionStartedRequest, session: ask.Session) {
                let logContext = `onSessionStarted`;
                console.log("IbGibAlexa onSessionStarted requestId: " + sessionStartedRequest.requestId
                    + ", sessionId: " + session.sessionId);
                // any initialization logic goes here
                helper.currentUserId = session.user.userId;

                // Todo: Get the user's identity from ibGib API
            };

            this.eventHandlers.onLaunch = function (launchRequest: ask.LaunchRequest, session: ask.Session, response: ask.ResponseClass) {
                let logContext = `IbGibAlexa.eventHandlers.onLaunch(requestId: ${launchRequest.requestId}, sessionId: ${session.sessionId}, userId: ${session.user.userId})`;
                helper.logFuncStart(logContext);
                try {
                    helper.log(`request: ${JSON.stringify(launchRequest)}`, 'debug', 0, logContext);
                    helper.log(`session: ${JSON.stringify(session)}`, 'debug', 0, logContext);
                    helper.log(`response: ${JSON.stringify(response)}`, 'debug', 0, logContext);

                    // Have to do something that eventually sends a response
                    t.handleWelcomeRequest(session, response);

                    // // get an identity for the current user.
                    // storage.init('AwsDynamoStorage', t._helper).
                    //     subscribe(resInit => {
                    //         t.handleWelcomeRequest(session, response);
                    //     },
                    //     errInit => {
                    //         helper.logError('errInit', errInit, logContext);

                    //         let speech: ask.OutputSpeech = {
                    //             type: ask.OutputSpeechType.PlainText,
                    //             text: 'Danger Will Robinson, Danger. ' + errInit.msg
                    //         };

                    //         response.tell({ outputSpeech: speech });
                    //     });

                } catch (errFunc) {
                    helper.logError(`errFunc`, errFunc, logContext);
                }

                helper.logFuncComplete(logContext);
            };

            this.eventHandlers.onSessionEnded = function (sessionEndedRequest: ask.SessionEndedRequest, session: ask.Session) {
                let logContext = `IbGibAlexa.eventHandlers.onSessionEnded(reason: ${sessionEndedRequest.reason}, sessionId: ${session.sessionId})`;
                helper.logFuncStart(logContext);
                try {
                    helper.log(`request: ${JSON.stringify(sessionEndedRequest)}`, 'debug', 0, logContext);
                    helper.log(`session: ${JSON.stringify(session)}`, 'debug', 0, logContext);

                    // do cleanup logic here. (none ATOW 2016/04/07)
                } catch (errFunc) {
                    helper.logError(`errFunc`, errFunc, logContext);
                }

                helper.logFuncComplete(logContext);
            };

            this.intentHandlers = {
                "OpenIbGibIntent": function (intent: ask.Intent, session: ask.Session, response: ask.ResponseClass) {
                    let logContext = `IbGibAlexa.intentHandlers.OpenIbGibIntent`;
                    helper.logFuncStart(logContext);
                    try {
                        helper.log(`intent: ${JSON.stringify(intent)}`, 'debug', 0, logContext);
                        helper.log(`session: ${JSON.stringify(session)}`, 'debug', 0, logContext);
                        helper.log(`response: ${JSON.stringify(response)}`, 'debug', 0, logContext);

                        t.handleOpenIbGibIntent(intent, session, response);
                    } catch (errFunc) {
                        helper.logError(`errFunc`, errFunc, logContext);
                        throw errFunc;
                    }

                    helper.logFuncComplete(logContext);
                },

                "ThankYouIntent": function (intent, session, response: ask.ResponseClass) {
                    let outputSpeech: ask.OutputSpeech = {
                        type: ask.OutputSpeechType.PlainText,
                        text: "You're welcome! Goodbye."
                    };
                    response.tell({ outputSpeech: outputSpeech });
                },

                "AMAZON.HelpIntent": function (intent, session, response: ask.ResponseClass) {
                    let lastRepromptSpeech: ask.OutputSpeech = session.attributes && session.attributes.lastRepromptSpeech ? session.attributes.lastRepromptSpeech : null;

                    let lastRepromptText: string = null;
                    if (lastRepromptSpeech) {
                        if (lastRepromptSpeech.type === ask.OutputSpeechType.PlainText) {
                            lastRepromptText = lastRepromptSpeech.text;
                        } else if (lastRepromptSpeech.type === ask.OutputSpeechType.SSML) {
                            // I can't figure out how to convert ssml to plain text, which is what I need right now. No big deal I don't think.
                            lastRepromptText = null;
                        } else {
                            lastRepromptText = null;
                        }
                    }

                    let repromptText = lastRepromptText ? lastRepromptText : `Would you like to open your shopping list?`;

                    let repromptSpeech: ask.OutputSpeech = lastRepromptSpeech ?
                        lastRepromptSpeech :
                        {
                            type: ask.OutputSpeechType.PlainText,
                            text: repromptText
                        };

                    let helpText = `With ib jib, you can track your lists and other things. For example, you can say "Open my shopping list" or "Read my todo list".`;

                    let outputSpeech: ask.OutputSpeech = {
                        type: ask.OutputSpeechType.PlainText,
                        text: `${helpText} Now, ${repromptText}`
                    };

                    response.askWithCard({ outputSpeech: outputSpeech, repromptSpeech: repromptSpeech, cardTitle: `ibGib`, cardContent: helpText });
                },

                "AMAZON.StopIntent": function (intent, session, response: ask.ResponseClass) {
                    let outputSpeech: ask.OutputSpeech = {
                        type: ask.OutputSpeechType.PlainText,
                        text: "Goodbye."
                    };
                    response.tell({ outputSpeech: outputSpeech });
                },

                "AMAZON.CancelIntent": function (intent, session, response: ask.ResponseClass) {
                    let outputSpeech: ask.OutputSpeech = {
                        type: ask.OutputSpeechType.PlainText,
                        text: "Goodbye."
                    };
                    response.tell({ outputSpeech: outputSpeech });
                }
            };
        } catch (errFunc) {
            this._helper.logError(`errFunc`, errFunc, logContext);
            throw errFunc;
        }

        this._helper.logFuncComplete(logContext);
    }

    /**
     * Opens an ibGib, most likely a shopping or todo list.
     */
    handleOpenIbGibIntent(intent: ask.Intent, session: ask.Session, response: ask.ResponseClass): void {
        let logContext = `handleOpenJibRequest`;
        this._helper.logFuncStart(logContext);

        try {

            let toOpen = "";
            if (intent.slots && intent.slots.length > 0 && intent.slots[0].value) {
                toOpen = intent.slots[0].value;
            }  
            
            // would call the ibGib API here.

            // let passageContent = passage.contentSsml ? passage.contentSsml : passage.content;
            let outputContent = `Howdy. Open jib placeholder speech here.`; 
            let instructions = `Howdy. Instructions placeholder here.`;

            // Create passage content speech output
            let outputSsml = `<speak>${outputContent}</speak>`;
            let outputSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.SSML,
                ssml: outputSsml
            }

            // Create reprompt speech (instructions)
            let repromptSsml = `<speak>${instructions}</speak>`;
            let repromptSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.SSML,
                ssml: outputSsml
            }

            // if (!session.attributes) { session.attributes = {}; }

            // session.attributes.passageIndex = passageIndex;

            // session.attributes.lastOutputSpeech = outputSpeech;
            // session.attributes.lastRepromptSpeech = repromptSpeech;

            response.askWithCard({ outputSpeech: outputSpeech, repromptSpeech: repromptSpeech, cardTitle: "ibGib", cardContent: instructions });

        } catch (errFunc) {
            this._helper.logError(`errFunc`, errFunc, logContext);
            throw errFunc;
        }

        this._helper.logFuncComplete(logContext);
    }

    handleWelcomeRequest(session: ask.Session, response: ask.ResponseClass): void {
        let logContext = `handleWelcomeRequest`;
        this._helper.logFuncStart(logContext);

        try {
            this._helper.currentUserId = session.user.userId;

            // Create passage content speech output
            let welcome = `Howdy, and welcome to ib jib! Your user I.D. length is ${session.user.userId.length}.`;
            let description = `Ib jib can help you organize things. For starters, we can do a shopping list. yada yada yada...`
            let prompt = `How does that sound to you?`;

            let outputSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.PlainText,
                text: `${welcome} ${description} ${prompt}`
            }

            // Create reprompt speech (instructions)
            let repromptSsml = `<speak>${prompt}</speak>`;
            let repromptSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.SSML,
                ssml: repromptSsml
            }

            session.attributes.lastOutputSpeech = outputSpeech;
            session.attributes.lastRepromptSpeech = repromptSpeech;

            response.askWithCard({ outputSpeech: outputSpeech, repromptSpeech: repromptSpeech, cardTitle: "ibGib: Shopping Lists, Todo Lists, and More", cardContent: outputSpeech.text });

        } catch (errFunc) {
            this._helper.logError(`errFunc`, errFunc, logContext);
            throw errFunc;
        }

        this._helper.logFuncComplete(logContext);
    }

    private _helper: Helper;
};



// Create the handler that responds to the Alexa Request.
export var handler = function (event, context) {
    // Create an instance of the IbGibAlexa skill.
    var ibGibAlexa = new IbGibAlexa(APP_ID);
    ibGibAlexa.execute(event, context);
};
