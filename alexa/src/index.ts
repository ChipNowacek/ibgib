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
 * Imports the passages as a hard-coded datastore.
 * Need to take this out 
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
 * Primary class of our Skill called "Bible Seeds and Such".
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

                // This will create a table for the current user
                // t._storage = new AwsDynamoStorage();
                // Todo: Test ibGib API connectivity
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
                "OpenJibIntent": function (intent: ask.Intent, session: ask.Session, response: ask.ResponseClass) {
                    let logContext = `IbGibAlexa.intentHandlers.OpenJibIntent`;
                    helper.logFuncStart(logContext);
                    try {
                        helper.log(`intent: ${JSON.stringify(intent)}`, 'debug', 0, logContext);
                        helper.log(`session: ${JSON.stringify(session)}`, 'debug', 0, logContext);
                        helper.log(`response: ${JSON.stringify(response)}`, 'debug', 0, logContext);

                        t.handleOpenJibRequest(session, response);
                    } catch (errFunc) {
                        helper.logError(`errFunc`, errFunc, logContext);
                        throw errFunc;
                    }

                    helper.logFuncComplete(logContext);
                },

                "ContinueIntent": function (intent, session, response: ask.ResponseClass) {
                    let logContext = `IbGibAlexa.intentHandlers.ContinueIntent`;
                    helper.logFuncStart(logContext);

                    try {
                        helper.log(`${JSON.stringify(session)}`, 'debug', 0, logContext);
                        if (session.attributes && (session.attributes.passageIndex ||
                             session.attributes.passageIndex === 0)) {
                            t.handleContinueRequest(session, response);
                        }
                        else {
                            t.handleOpenJibRequest(session, response);
                        }
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

                "AMAZON.RepeatIntent": function (intent, session, response: ask.ResponseClass) {
                    let logContext = `IbGibAlexa.intentHandlers.RepeatIntent`;
                    helper.logFuncStart(logContext);

                    try {
                        helper.log(`${JSON.stringify(session)}`, 'debug', 0, logContext);

                        if (session.attributes && session.attributes.lastOutputSpeech) {

                            response.tell({ outputSpeech: session.attributes.lastOutputSpeech, repromptSpeech: session.attributes.lastRepromptSpeech,
                                shouldEndSession: false });
                            ;

                        } else {
                            this.handleContinueRequest()
                        }

                        if (session.attributes && (session.attributes.passageIndex ||
                             session.attributes.passageIndex === 0)) {

                            t.handleOpenJibRequest(session, response);
                        }
                        else {
                            t.handleContinueRequest(session, response);
                            t.handleOpenJibRequest(session, response);
                        }
                    } catch (errFunc) {
                        helper.logError(`errFunc`, errFunc, logContext);
                        throw errFunc;
                    }

                    helper.logFuncComplete(logContext);
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

                    let repromptText = lastRepromptText ? lastRepromptText : `Would you like me to give you a passage?`;

                    let repromptSpeech: ask.OutputSpeech = lastRepromptSpeech ?
                        lastRepromptSpeech :
                        {
                            type: ask.OutputSpeechType.PlainText,
                            text: repromptText
                        };

                    let helpText = `With ib jib, you can do a lot of cool stuff. For example, you can say "Open my shopping list". I'll then open that up and you can For example, you can say 'Give me a passage.' I will then give you a location like, 'Luke Chapter 4 Verse 4'. Then, you would review the passage in your mind. When you're ready to hear the passage, say 'Okay' or 'Continue'. If you need more time, say 'Wait'. You can exit at any time when you're are through.`;

                    let outputSpeech: ask.OutputSpeech = {
                        type: ask.OutputSpeechType.PlainText,
                        text: `${helpText} Now, ${repromptText}`
                    };

                    // let repromptSpeech: ask.OutputSpeech = session.attributes && session.attributes.lastRepromptSpeech ?
                    //     session.attributes.lastRepromptSpeech :
                    //     {
                    //         type: ask.OutputSpeechType.PlainText,
                    //         text: "Would you like me to give you a passage?"
                    //     };
                    // let repromptSpeech: ask.OutputSpeech = {
                    //     type: ask.OutputSpeechType.PlainText,
                    //     text: "Would you like me to give you a passage?"
                    // };

                    response.askWithCard({ outputSpeech: outputSpeech, repromptSpeech: repromptSpeech, cardTitle: `Bible Seeds and Such Help`, cardContent: helpText });
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

    getContinueText(): string {
        let options = [
            'Would you like another passage?',
            'Do you want another passage?',
            'Would you like another one?',
            'Do you want another one?'
        ];

        let resultIndex = Math.floor(Math.random() * options.length);

        return options[resultIndex];
    }

    handleContinueRequest(session: ask.Session, response: ask.ResponseClass): void {
        let logContext = `IbGibAlexa.handleContinueRequest`;
        this._helper.logFuncStart(logContext);

        try {
            let index: number = session.attributes.passageIndex;
            // let index = Math.floor(Math.random() * data.PASSAGES.length);
            let passage = data.PASSAGES[index];

            let passageContent = passage.contentSsml ? passage.contentSsml : passage.content;
            let continueText = this.getContinueText();

            let ssml = `<speak><p>${passageContent}.</p><p>${continueText}</p></speak>`;

            // Create speech output
            let outputSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.SSML,
                ssml: ssml
            }

            // Create reprompt speech
            let repromptSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.SSML,
                ssml: `<speak>${continueText}</speak>`
            };

            delete session.attributes.passageIndex;

            session.attributes.lastOutputSpeech = outputSpeech;
            session.attributes.lastRepromptSpeech = repromptSpeech;

            response.tellWithCard({ outputSpeech: outputSpeech, repromptSpeech: repromptSpeech, cardTitle: "Bible Seeds and Such", cardContent: passage.content, shouldEndSession: false });
            // response.tellWithCard({ outputSpeech: speechOutput, cardTitle: "Bible Seeds and Such", cardContent: passage.content, shouldEndSession: false });
        } catch (errFunc) {
            this._helper.logError(`errFunc`, errFunc, logContext);
            throw errFunc;
        }

        this._helper.logFuncComplete(logContext);
    }

    /**
     * Picks a random passage. Tells the user the location, and waits for the user
     * to continue.
     */
    handleOpenJibRequest(session: ask.Session, response: ask.ResponseClass): void {
        let logContext = `handleOpenJibRequest`;
        this._helper.logFuncStart(logContext);

        try {
            // 
            
            let passageIndex = Math.floor(Math.random() * data.PASSAGES.length);
            let passage = data.PASSAGES[passageIndex];

            let passageContent = passage.contentSsml ? passage.contentSsml : passage.content;
            let instructions = `${passage.location}. Try to recall the passage. When you are ready, say "continue" or "ok". If you need more time, say "hold on" or "wait".`;

            // Create passage content speech output
            let passageSsml = `<speak>${passage.location}</speak>`;
            let outputSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.SSML,
                ssml: passageSsml
            }

            // Create reprompt speech (instructions)
            let repromptSsml = `<speak>${instructions}</speak>`;
            let repromptSpeech: ask.OutputSpeech = {
                type: ask.OutputSpeechType.SSML,
                ssml: passageSsml
            }

            if (!session.attributes) { session.attributes = {}; }

            session.attributes.passageIndex = passageIndex;

            session.attributes.lastOutputSpeech = outputSpeech;
            session.attributes.lastRepromptSpeech = repromptSpeech;

            response.askWithCard({ outputSpeech: outputSpeech, repromptSpeech: repromptSpeech, cardTitle: "Bible Seeds and Such", cardContent: instructions });

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
            let welcome = `Howdy, and welcome to thing jib! Your user I.D. length is ${session.user.userId.length}.`;
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
