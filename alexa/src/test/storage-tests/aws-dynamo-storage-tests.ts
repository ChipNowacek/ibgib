// /**
//  * This is assuming local storage. To run local DynamoDB, go to folder at
//  * ib/Tools/DynamoDB and use command:
//  *     java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar
//  */
// import chai = require('chai');
// let assert = chai.assert;
// let expect = chai.expect;
// let should = chai.should();

// import { IResult } from 'thing-gib';
// import * as rxresult from 'thing-gib';
// import { IHelper, Helper } from 'thing-gib';

// import { AsyncSubject, Subject, Observable, Subscription } from 'rxjs';
// import * as aws from 'aws-sdk';
// import * as _ from 'lodash';
// import { AwsDynamoStorage } from '../../storage/aws.dynamo.storage';
// import * as awsD from '../../storage/aws.dynamo';

// var _helper = new Helper();
// _helper.logPriority = 0;
// _helper.currentUserId = 'not_init_user_id';


// let currentUserId = 'not_initialized_user_id';
// var logContext = 'logContext_not_initialized';
// var storageName = `localtestdb_${_helper.randomLetters(125).toLowerCase()}`;

// describe('aws-dynamo-storage', () => {

//     function initTest(): AsyncSubject<IResult> {

//         logContext = 'logContext_not_initialized';
//         _helper.logFuncStart(logContext);

//         let result = new AsyncSubject<IResult>();
//         try {
//             _helper.currentUserId = 'test_user_yo';
//             _helper.log(`currentUserId: ${_helper.currentUserId}`, 'warn', 3, logContext);
//             storageName = `localtestdb_${_helper.randomLetters(125).toLowerCase()}`;

//             let db = new aws.DynamoDB({
//                 apiVersion: '2012-08-10',
//                 endpoint: 'http://localhost:8000',
//                 region: 'shared-local-instance',
//                 accessKeyId: 'this_is_ignored',
//                 secretAccessKey: 'this-is-ignored-too'
//             });

//             awsD.createTable({ tableName: storageName, db: db, helper: _helper }).
//                 subscribe(resCreateTable => {
//                     _helper.log('created table. waiting for table exists...', 'debug', 0, logContext);
//                     awsD.waitForTableExists({ tableName: storageName, db: db, helper: _helper }).
//                         subscribe(resWaitForTableExists => {

//                         // we're initialized
//                         let msg = `Initialized. Current user table created.`;
//                         _helper.log(msg, 'debug', 0, logContext);
//                         rxresult.setResult(result, { success: true, msg: msg });
//                         },
//                         errWaitForTableExists => {

//                         _helper.logError(`errWaitForTableExists`, errWaitForTableExists, logContext);
//                         rxresult.setAsyncError(result, errWaitForTableExists);

//                         });

//                 },
//                 errCreateTable => {
//                     _helper.logError(`errCreateTable`, errCreateTable, logContext);
//                     rxresult.setAsyncError(result, errCreateTable);
//                 });
//             // rxresult.setResult(result, { success: true, msg: 'initialized' });
//         } catch (errFunc) {
//             rxresult.setAsyncError(result, errFunc);
//         }

//         _helper.logFuncCompleteAsync(logContext);

//         return result;
//     }


//     beforeEach(done => {
//         initTest().subscribe(res => {
//             _helper.log(`init complete`, 'debug', 3, `initTests exec`);
//             done();
//         }, errInit => {
//             _helper.logError(`errInit`, errInit, `initTests exec`);
//             done(errInit);
//         });
//     });
//     afterEach(() => {
//         _helper.currentUserId = undefined;
//         _helper.logPriority = 0;
//     });

//         describe('simple', () => {




// // ---------------------------------------------------------------------------------------
// // Test
// // ---------------------------------------------------------------------------------------
// let testNameInit = `should init storage (${storageName})`;
// it(testNameInit, (done) => {
// logContext = testNameInit;
// _helper.logFuncStart(logContext);

// var storage = new AwsDynamoStorage();
// let storageInit = storage.init(storageName, _helper);

// storageInit.subscribe(initialized => {
//     if (initialized.error) {
//         done(initialized.error);
//     } else if (!initialized.success) {
//         let errInit = new Error(`storage init failed but no error.`);
//         done(errInit);
//     } else {
//         done();
//         // thingRepo = new ThingRepo_UsesStorage(storage, _helper);
//         // rxresult.setResult(thingRepoInit, { success: true, msg: 'initialized' });
//     }
// },
// errInitialized => {
//     done(errInitialized);
//     // rxresult.setAsyncError(thingRepoInit, errInitialized);
// });

// });
// // ---------------------------------------------------------------------------------------
// // End Test
// // ---------------------------------------------------------------------------------------


// // ---------------------------------------------------------------------------------------
// // Test
// // ---------------------------------------------------------------------------------------
// let testNamePut = `should put item (${storageName})`;
// let putTests: {
//     testName: string;
//     testJsonSize: number
// }[] = [
//     { testName: `${testNamePut} testJsonSize: ${1}`, testJsonSize: 1 },
//     { testName: `${testNamePut} testJsonSize: ${1024}`, testJsonSize: 1024 },
//     { testName: `${testNamePut} testJsonSize: ${10240}`, testJsonSize: 10240 },
//     { testName: `${testNamePut} testJsonSize: ${409500}`, testJsonSize: 409500 },
// ];

// putTests.forEach(test => {
//     it(test.testName, (done) => {

// logContext = test.testName;
// _helper.logFuncStart(logContext);

// var storage = new AwsDynamoStorage();
// let storageInit = storage.init(storageName, _helper);

// storageInit.subscribe(initialized => {
//     if (initialized.error) {
//         done(initialized.error);
//     } else if (!initialized.success) {
//         let errInit = new Error(`storage init failed but no error.`);
//         done(errInit);
//     } else {
//         let testCategory = 'info';
//         let testKey = `test_key_${_helper.randomLetters(25).toLowerCase()}`;
//         let testJson = _helper.randomLetters(test.testJsonSize);
//         storage.saveData(testCategory, testKey, testJson).
//             subscribe(resSaveData => {
//                 if (!resSaveData.error && resSaveData.success === true) {
//                     done();
//                 } else {
//                     _helper.logError('resSaveData.error', resSaveData.error, logContext);
//                     done(resSaveData.error);
//                 }
//             },
//             errSaveData => {
//                 _helper.logError('errSaveData', errSaveData, logContext);
//                 done(errSaveData);
//             });
//     }
// },
// errInitialized => {
//     done(errInitialized);
//     // rxresult.setAsyncError(thingRepoInit, errInitialized);
// });


//     });
// });

// // ---------------------------------------------------------------------------------------
// // End Test
// // ---------------------------------------------------------------------------------------


// // ---------------------------------------------------------------------------------------
// // Test
// // ---------------------------------------------------------------------------------------
// let testNameGet = 'should get item';
// let getTests: {
//     testName: string;
//     testJsonSize: number
// }[] = [
//     { testName: `${testNameGet} testJsonSize: ${1}`, testJsonSize: 1 },
//     { testName: `${testNameGet} testJsonSize: ${1024}`, testJsonSize: 1024 },
//     { testName: `${testNameGet} testJsonSize: ${10240}`, testJsonSize: 10240 },
//     { testName: `${testNameGet} testJsonSize: ${409500}`, testJsonSize: 409500 },
// ];

// getTests.forEach(test => {
//     it(test.testName, (done) => {

// logContext = test.testName;
// _helper.logFuncStart(logContext);

// var storage = new AwsDynamoStorage();
// let storageInit = storage.init(storageName, _helper);

// storageInit.subscribe(initialized => {
//     if (initialized.error) {
//         done(initialized.error);
//     } else if (!initialized.success) {
//         let errInit = new Error(`storage init failed but no error.`);
//         done(errInit);
//     } else {
//         let testCategory = 'info';
//         let testKey = `test_key_${_helper.randomLetters(25).toLowerCase()}`;
//         let testJson = _helper.randomLetters(test.testJsonSize);
//         storage.saveData(testCategory, testKey, testJson).
//             subscribe(resSaveData => {
//                 if (!resSaveData.error && resSaveData.success === true) {
//                     // now get the data
//                     storage.getData(testCategory, testKey).
//                         subscribe(resGetData => {
//                             if (!resGetData.error && resGetData.success === true) {
//                                 let gottenJson = resGetData.value;
//                                 try {
//                                     expect(gottenJson).to.equal(testJson);
//                                     done();
//                                 } catch (error) {
//                                     done(error);
//                                 }
//                             } else {
//                                 let errYo = resGetData.error || new Error('hmm error getting')
//                                 done(errYo);
//                             }
//                         },
//                         errGetData => {

//                             done(errGetData);
//                         });
//                 } else {
//                     let errYo = resSaveData.error || new Error('hmm error saving')
//                     done(errYo);
//                 }
//             },
//             errSaveData => {
//                 done(errSaveData);
//             });
//     }
// },
// errInitialized => {
//     done(errInitialized);
//     // rxresult.setAsyncError(thingRepoInit, errInitialized);
// });


//     });
// });

// // ---------------------------------------------------------------------------------------
// // Test
// // ---------------------------------------------------------------------------------------
// let testNameExists = 'should exists item';
// let existTests: {
//     testName: string;
//     testJsonSize: number
// }[] = [
//     { testName: `${testNameExists} testJsonSize: ${1}`, testJsonSize: 1 },
//     { testName: `${testNameExists} testJsonSize: ${1024}`, testJsonSize: 1024 },
//     { testName: `${testNameExists} testJsonSize: ${10240}`, testJsonSize: 10240 },
//     { testName: `${testNameExists} testJsonSize: ${409500}`, testJsonSize: 409500 },
// ];

// existTests.forEach(test => {
//     it(test.testName, (done) => {

// logContext = test.testName;
// _helper.logFuncStart(logContext);

// var storage = new AwsDynamoStorage();
// let storageInit = storage.init(storageName, _helper);

// storageInit.subscribe(initialized => {
//     if (initialized.error) {
//         done(initialized.error);
//     } else if (!initialized.success) {
//         let errInit = new Error(`storage init failed but no error.`);
//         done(errInit);
//     } else {
//         let testCategory = 'info';
//         let testKey = `test_key_${_helper.randomLetters(25).toLowerCase()}`;
//         let testJson = _helper.randomLetters(test.testJsonSize);
//         storage.saveData(testCategory, testKey, testJson).
//             subscribe(resSaveData => {
//                 if (!resSaveData.error && resSaveData.success === true) {
//                     // now get the data
//                     storage.exists(testCategory, testKey).
//                         subscribe(resExistsData => {
//                             if (!resExistsData.error && resExistsData.success === true) {
//                                 if (resExistsData.value === 'true') {
//                                     done();
//                                 } else {
//                                     done(new Error('data does not exist'));
//                                 }
//                                 // let gottenJson = resExistsData.value;
//                                 // try {
//                                 //     expect(gottenJson).to.equal(testJson);
//                                 //     done();
//                                 // } catch (error) {
//                                 //     done(error);
//                                 // }
//                             } else {
//                                 let errYo = resExistsData.error || new Error('hmm error in exists')
//                                 done(errYo);
//                             }
//                         },
//                         errGetData => {

//                             done(errGetData);
//                         });
//                 } else {
//                     let errYo = resSaveData.error || new Error('hmm error saving')
//                     done(errYo);
//                 }
//             },
//             errSaveData => {
//                 done(errSaveData);
//             });
//     }
// },
// errInitialized => {
//     done(errInitialized);
//     // rxresult.setAsyncError(thingRepoInit, errInitialized);
// });


//     });
// });
// // ---------------------------------------------------------------------------------------
// // End Test
// // ---------------------------------------------------------------------------------------

// // ---------------------------------------------------------------------------------------
// // Test
// // ---------------------------------------------------------------------------------------
// let testNameNotExists = `should not exist item (${storageName})`;
// let notExistTests: {
//     testName: string;
// }[] = [
//     { testName: `${testNameNotExists}` },
// ];

// notExistTests.forEach(test => {
//     it(test.testName, (done) => {

// logContext = test.testName;
// _helper.logFuncStart(logContext);

// var storage = new AwsDynamoStorage();
// let storageInit = storage.init(storageName, _helper);

// storageInit.subscribe(initialized => {
//     if (initialized.error) {
//         done(initialized.error);
//     } else if (!initialized.success) {
//         let errInit = new Error(`storage init failed but no error.`);
//         done(errInit);
//     } else {
//         let testCategory = 'info';
//         let testKey = `test_key_${_helper.randomLetters(25).toLowerCase()}`;
//         storage.exists(testCategory, testKey).
//             subscribe(resExistsData => {
//                 if (!resExistsData.error && resExistsData.success === true) {
//                     if (resExistsData.value === 'false') {
//                         done();
//                     } else {
//                         done(new Error('data does exist...wth?'));
//                     }
//                 } else {
//                     let errYo = resExistsData.error || new Error('hmm error in exists')
//                     done(errYo);
//                 }
//             },
//             errSaveData => {
//                 done(errSaveData);
//             });
//     }
// },
// errInitialized => {
//     done(errInitialized);
//     // rxresult.setAsyncError(thingRepoInit, errInitialized);
// });


//     });
// });
// // ---------------------------------------------------------------------------------------
// // End Test
// // ---------------------------------------------------------------------------------------

// // let tests: {
// //     text: string;
// //     data: boolean
// // }[] = [
// //     { text: 'test 1', data: true },
// //     { text: 'test 2', data: false },
// //     { text: 'test 3', data: true },
// // ];

// // tests.forEach(test => {
// //     it(test.text, () => {
// //         console.log(`hi from a ${test.text}!`);
// //         assert.isTrue(test.data);
// //     });
// // });


//     });
// });
