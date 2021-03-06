local utiles = require("../../utiles/utiles.lua")
local logger = require("../log.lua")
-- const pubToCloudKafkaTopic = require('../config').mqClient_as.topics.pubToCloud;
-- const _ = require('lodash');
-- const BluebirdPromise = require('bluebird');
-- const ERROR = require('./lora-lib/ERROR');
-- const schema = require('./mongoSchema');
-- const moment = require('moment');

-- class NsMsgHandler {
--   constructor(mqClient, mysqlModels, mongoConn, protoBufUnit, log) {
--     this.mqClient = mqClient;
--     this.mongoConn = mongoConn;
--     this.DeviceInfo = mysqlModels.DeviceInfo;
--     this.protoBufUnit = protoBufUnit;
--     this.log = log;
--   }

-- app数据处理
function handler(message)
  logger.info(" app module handle...")
  -- TODO:Json schema
  -- local appDataObject = {}
  -- local whereOpts = {
  --   DevAddr = message.DevAddr
  -- }
  if message.FRMPayload ~= nil then
    logger.info({"message.FRMPayload:", utiles.BufferToHexString(message.FRMPayload)})
    local appFRMPayloadBuf = utiles.BufferFrom(message.FRMPayload)
    logger.info({" >>>> appFRMPayloadBuf:", appFRMPayloadBuf:toString()})
  end
  -- TODO
  -- According to the needs, customize the way of data processing.
  -- Such as publish the data to Cloud's topic

  -- //return BluebirdPromise.resolve();

  --   return DeviceInfo.readItem(whereOpts, ['AppEUI'])
  --     .then((res) => {

  --       -- //Link data to Protocol Buffer configuration file via AppEUI
  --       -- //This needs to be configured in the config.js file
  --       if (!_.isEmpty(res.AppEUI)) {
  --         const AppEUI_Str = res.AppEUI.toString('hex');
  --         return this.protoBufUnit.PBToJSONUnit(appFRMPayloadBuf, AppEUI_Str)
  --           .then((appJsonObject) => {

  --             if (Buffer.isBuffer(appJsonObject)) {

  --               -- //Have Protocol Buffer configuration
  --               appDataObject.appData = appJsonObject.toString('hex');
  --             } else {

  --               -- //No Protocol Buffer configuration
  --               appDataObject.appData = appJsonObject;
  --             }

  --             return this.saveToMongo(message.DevAddr, AppEUI_Str, appDataObject.appData)
  --               .then(() => {
  --                   return BluebirdPromise.resolve(appDataObject);
  --               }
  --             );
  --           });
  --       }
  --       return BluebirdPromise.reject(
  --         new ERROR.DeviceNotExistError('Invalid DevAddr in DeviceInfo'));
  --     }).then((appObj) => {

  --       -- //TODO
  --       -- //this.log.debug({
  --       -- //  label: `Uplink object to ${pubToCloudKafkaTopic}`,
  --       -- //  message: appObj,
  --       -- //});
  --       //return this.mqClient.publish(pubToCloudKafkaTopic, appObj);
  --       return BluebirdPromise.resolve(null);
  --     });
  -- }
  return message
end
--   saveToMongo (DevAddr, AppEUI, appDataObj){
--     const COLLECTION_PREFIX = 'appeui_';
--     const collectionName = COLLECTION_PREFIX + AppEUI;
--     const uplinkMsgModel = this.getModel(collectionName);

--     const saveObj = {
--       DevAddr: DevAddr.toString('hex'),
--       operation: 'Update',
--       payload: {
--         state: {
--           reported:{
--             data: appDataObj
--           }
--         }
--       },
--       timestamp: moment().unix(),
--     };

--     return uplinkMsgModel.create(saveObj);
--   }

--   getModel(collectionName, inputSchema) {
--     let useSchema = inputSchema ? inputSchema : schema.uplinkMsg;
--     try {
--       return this.mongoConn.model(collectionName);
--     } catch (err) {
--       return this.mongoConn.model(collectionName, useSchema, collectionName);
--     }
--   }

-- }

-- module.exports = NsMsgHandler;
return {
  handler = handler
}
