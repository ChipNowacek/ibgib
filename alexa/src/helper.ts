export type LogType = 'debug' | 'info' | 'warn' | 'error';
export const LogType = {
    debug: 'debug' as LogType,
    info: 'info' as LogType,
    warn: 'warn' as LogType,
    error: 'error' as LogType,
};

export interface IHelper {
    // ---------------------------------------
    // Logging
    // ---------------------------------------
    log(
        msg: string,
        type: LogType,
        priority: number,
        context?: string
    ): void;

    logFuncStart(logContext: string, addlMsg?: string);
    logFuncComplete(logContext: string, addlMsg?: string);
    logFuncCompleteAsync(logContext: string, addlMsg?: string);
    logFuncAsyncAllDone(logContext: string, addlMsg?: string);
    logError(errName: string, error: any, logContext: string, priority?: number, addlMsg?: string);

    logPriority: number;

    // ---------------------------------------
    // Utils
    // ---------------------------------------
    generateUUID(): string;
    getFormattedDate(dateNumber: number, formatType?: string, withTime?: boolean, sep?: string): string;
    randomLetters(howMany: number): string;

    // ---------------------------------------
    // User Identification
    // ---------------------------------------
    locationId: string;
    currentUserId: string;
    currentDeviceId: string;
}

export class Helper implements IHelper {
    // ---------------------------------------
    // Logging
    // ---------------------------------------
    /**Errors are always logged regardless of priority.
     *
     * @param msg The msg to log.
     * @param type error, info, debug, warn.
     * @param priority 0=silly-ish, 1= verbose-ish, 2=normal-ish, 3=terse-ish, etc.
     * @param context */
    log(
        msg: string,
        type: LogType,
        priority: number,
        context?: string
    ): void {
        if (priority < this.logPriority && type !== 'error') {
            return;
        }

        var timestamp = this.getFormattedDate(
            /*when*/ Date.now(),
           /*month format*/ 'num',
           /*withTime*/ true,
           /*sep*/ '');

        let contextSegment = `[${context}] `;
        let formattedMsg = `[${timestamp}][${type}]${contextSegment}${msg}`;

        switch (type) {
            case 'error': {
                console.error(formattedMsg);
                break;
            }
            case 'info': {
                console.info(formattedMsg);
                break;
            }
            case 'debug': {
                // console.debug throws error on node server
                // console.debug(timestamp + '[debug] ' + msg);
                // colors in javascript...thanks SO people:
                // http://stackoverflow.com/questions/7505623/colors-in-javascript-console
                // let randomColor = this._getRandomColorFromContext(context);
                // if (randomColor) {
                //     let css = `color: ${randomColor}`;
                //     console.log(`%c ${formattedMsg}`, css);
                // } else {
                    console.info(formattedMsg);
                // }
                break;
            }
            case 'warning': {
                console.warn(formattedMsg);
                break;
            }
            case 'warn': {
                console.warn(formattedMsg);
                break;
            }
            default: {
                console.info(formattedMsg);
                break;
            }
        }
    }

    logFuncStart(logContext: string, addlMsg?: string) {
        let msg = addlMsg ? `${this.MSG_FUNC_START} ${addlMsg}` : this.MSG_FUNC_START;
        this.log(msg, 'debug', 0, logContext);
    }

    logFuncComplete(logContext: string, addlMsg?: string) {
        let msg = addlMsg ? `${this.MSG_FUNC_COMP} ${addlMsg}` : this.MSG_FUNC_COMP;
        this.log(msg, 'debug', 0, logContext);
    }

    logFuncCompleteAsync(logContext: string, addlMsg?: string) {
        let msg = addlMsg ? `${this.MSG_FUNC_COMP_ASYNC} ${addlMsg}` : this.MSG_FUNC_COMP_ASYNC;
        this.log(msg, 'debug', 0, logContext);
    }

    logFuncAsyncAllDone(logContext: string, addlMsg?: string) {
        let msg = addlMsg ? `${this.MSG_FUNC_COMP_ASYNC_ALLDONE} ${addlMsg}` : this.MSG_FUNC_COMP_ASYNC_ALLDONE;
        this.log(msg, 'debug', 0, logContext);
    }

    /**Wrapper for this.log for most common error logging that I seem to be doing.
     *
     * @example logError('errFunc', errFunc, logContext);
     */
    logError(errName: string, error: any, logContext: string, priority: number = 2, addlMsg: string = null) {
        let msg = addlMsg ?
            `${addlMsg}>> ${errName}: ${error.message}` :
            `${errName}: ${error.message}`;

        this.log(msg, 'error', priority, logContext);
    }


    get MSG_FUNC_START(): string { return `Starting...`; }
    get MSG_FUNC_COMP(): string { return `Complete.`; }
    get MSG_FUNC_COMP_ASYNC(): string { return `Complete. Async tasks may still be running.`; }
    get MSG_FUNC_COMP_ASYNC_ALLDONE(): string { return `Async task(s) Complete.`; }

    logPriority: number = 0;

    // ---------------------------------------
    // Utils
    // ---------------------------------------

    // /**Thanks SO!
    //  * http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript */
    generateUUID(): string {
        var d = new Date().getTime();
        var uuid = 'xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = (d + Math.random()*16)%16 | 0;
            d = Math.floor(d/16);
            return (c=='x' ? r : (r&0x3|0x8)).toString(16);
        });
        return uuid;
    }

    getFormattedDate(dateNumber: number, formatType: string = 'short', withTime: boolean = true, sep: string = ' '): string {
        var date = new Date(dateNumber);
        var result = <string>'';

        var monthNames = <string[]>[];

        switch (formatType) {
            case 'short': {
                monthNames = [
                    "Jan", "Feb", "Mar",
                    "Apr", "May", "Jun", "Jul",
                    "Aug", "Sep", "Oct",
                    "Nov", "Dec"
                ];
                break;
            }
            case 'long': {
                monthNames = [
                    "January", "February", "March",
                    "April", "May", "June", "July",
                    "August", "September", "October",
                    "November", "December"
                ];
                break;
            }
            case 'num': {
                monthNames = [
                    "1", "2", "3",
                    "4", "5", "6", "7",
                    "8", "9", "10",
                    "11", "12"
                ];
                break;
            }
            default: {
                monthNames = [
                    "1", "2", "3",
                    "4", "5", "6", "7",
                    "8", "9", "10",
                    "11", "12"
                ];
                break;
            }
        }

        var day = date.getDate();
        var month = monthNames[date.getMonth()];
        var year = date.getFullYear();

        result += year + sep + month + sep + day;

        if (withTime === true) {
            result += ' ' + date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds() + '.' + date.getMilliseconds();
        }

        return result;
    }

    randomLetters(howMany: number) {
        var text = "";
        var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

        for (var i=0; i < howMany; i++)
            text += possible.charAt(Math.floor(Math.random() * possible.length));

        return text;
    }

    // ---------------------------------------
    // User Identification
    // ---------------------------------------
    locationId: string;
    currentUserId: string;
    currentDeviceId: string;
}
