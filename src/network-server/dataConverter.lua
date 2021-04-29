-- 'use strict';

-- const _ = require('lodash');
-- const Ajv = require('ajv');
-- const ajv = new Ajv({ allErrors: true });
-- let uplinkMessageSchema = require('./schema/uplinkMessage.schema.json');
-- ajv.addSchema(uplinkMessageSchema, 'uplinkMessageSchema');
-- const BluebirdPromise = require('bluebird');
-- const GatewayStatHandler = require('./gatewayStatHandler');
-- const DeDuplication = require('./deDuplication');
-- const AppDataHandler = require('./appDataHandler');
local downlinkDataHandler = require("./downlinkDataHandler.lua")
local joinResHandler = require("./joinResHandler.lua")
-- const crypto = require('crypto');
-- const loraLib = require('../lora-lib');
-- const { consts, ERROR, utils } = loraLib;
-- const moment = require('moment');
-- const mongoose = require('mongoose');
-- const mongoSavedSchema = require('./schema/mongoSavedMsg');
-- local mqHandle = require("../src/common/message_queue.lua")
local consts = require("../lora-lib/constants/constants.lua")
-- local joinResHandler = require("./joinResHandler.lua")
local gatewayStatConverter = require("./gatewayStatHandler.lua")
local gatewayInfoRedis = require("../lora-lib/models/RedisModels/GatewayInfo.lua")
local DeviceInfoRedis = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
-- function DataConverter(mqClient, redisConn, mysqlConn, log) {
--   this.deDuplication = new DeDuplication(redisConn.DeDuplication);
--   this.gatewayStatHandler = new GatewayStatHandler(mysqlConn.GatewayStatus);
--   this.DeviceInfoRedis = redisConn.DeviceInfo;
--   this.gatewayInfoRedis = redisConn.GatewayInfo;
--   this.redisConnMsgQue = redisConn.MessageQueue;
--   this.DeviceInfoMysql = mysqlConn.DeviceInfo;
--   this.GatewayInfo = mysqlConn.GatewayInfo;
--   this.appDataHandler = new AppDataHandler(mqClient, redisConn, mysqlConn, log);
--   this.mqClient = mqClient;
--   this.downlinkDataHandler = new DownlinkDataHandler(mqClient, redisConn, mysqlConn, log);
--   this.joinResHandler = new JoinResHandler(mqClient, redisConn, mysqlConn, log);
--   this.log = log;

-- }

-- DataConverter.prototype.gatewayStatConverter = function (uplinkDataJson) {

--   let gatewayStatObject = {};

--   gatewayStatObject = uplinkDataJson.stat;
--   gatewayStatObject.gatewayId = uplinkDataJson.gatewayId;

--   return gatewayStatObject;
-- };

function rxInfoConverter(uplinkDataJson)
  local rfPacketObject = {}
  for k, v in pairs(uplinkDataJson.rxpk) do
    if k ~= "data" and k ~= "raw" then
      rfPacketObject[k] = v
    end
  end
  rfPacketObject.gatewayId = uplinkDataJson.gatewayId
  rfPacketObject.DevAddr = uplinkDataJson.rxpk.data.MACPayload.FHDR.DevAddr
  return rfPacketObject
end

function joinRfConverter(joinDataJson)
  local rfPacketObject = {}
  for k, v in pairs(joinDataJson.rxpk) do
    if k ~= "data" and k ~= "raw" then
      rfPacketObject[k] = v
    end
  end
  rfPacketObject.gatewayId = joinDataJson.gatewayId
  rfPacketObject.DevAddr = joinDataJson.rxpk.data.DevAddr
  return rfPacketObject
end

function appDataConverter(uplinkDataJson)
  local appDataObject = uplinkDataJson.rxpk.data
  appDataObject.version = uplinkDataJson.version
  if uplinkDataJson.srcID then
    appDataObject.srcID = uplinkDataJson.srcID
  else
    appDataObject.srcID = ""
  end
  local appFRMPayloadBuf = appDataObject.MACPayload.FRMPayload
  if appFRMPayloadBuf then
    local ret = DeviceInfoRedis.read(appDataObject.MACPayload.FHDR.DevAddr, {"FCntUp", "AppEUI"})
    if res.FCntUp then
      appDataObject.FCntUp = res.FCntUp
      appDataObject.AppEUI = res.AppEUI
      return appDataObject
    else
      p("DevAddr does not exist in DeviceInfo")
      return nil
    end
  end
  p("The uplink data has no {MACPayload.FRMPayload}")
  return nil
end

-- 上行数据处理
function uplinkDataHandler(jsonData)
  local ret = nil
  local uplinkDataJson = jsonData
  local uplinkDataId = jsonData.identifier
  if uplinkDataId == consts.UDP_ID_PUSH_DATA then
    -- Recive PUSH data
    if uplinkDataJson.rxpk ~= nil then
      -- Recive PUSH data from Node
      if uplinkDataJson.rxpk.data == nil then
        p('Uplink Json has no "data" in rxpk')
        return -2
      end
      local messageType = uplinkDataJson.rxpk.data.MHDR.MType
      if messageType == consts.JS_MSG_TYPE.request then
        -- Join request message
        ret = joinResHandler.joinRequestHandle(uplinkDataJson) -- 把业务数据推送至join-server模块
        p("Receive repeated join request message")
        -- TODO update downlink routing
        return 0
      end

      if messageType == consts.UNCONFIRMED_DATA_UP or messageType == consts.CONFIRMED_DATA_UP then
        -- Application message
        ret = appDataConverter(uplinkDataJson)
        if ret ~= nil then
          p("Receive repeated app data message")
          return _this.appDataHandler.handle(rxInfoArr, appObj)
        end
      end
    elseif uplinkDataJson.stat ~= nil then
      -- });
      -- // });
      -- Recive PUSH data from Gateway
      -- TODO: 网关状态数据统计
      local gatawaySata = gatewayStatConverter.handle(uplinkDataJson)
      -- // return _this.gatewayStatHandler.handle(gatawaySata)
      -- //   .then(function () {
      -- // const whereOpts = {
      -- //   gatewayId: uplinkDataJson.gatewayId,
      -- // };
      local resuserID = gatewayInfoRedis.GetuserID(uplinkDataJson.gatewayId)

      if resuserID then
        -- local collectionName = consts.MONGO_USERCOLLECTION_PREFIX + resuserID
        p("recv gateway stat data", uplinkDataJson)
        return 0
      else
        p("No UserID in Reids about the gateway")
        return -4
      end
    else
      p('Error key value of received JSON (NO "rxpk" or "stat")')
      return -2
    end
  elseif uplinkDataId == consts.UDP_ID_PULL_DATA then
    -- TODO:
    p("Recive UDP Pull Data")
    return 0
  elseif uplinkDataId == consts.UDP_ID_TX_ACK then
    -- TODO:
    p("Recive UDP TX_ACK")
    return 0
  else
    p("Error UDP package identifier")
    return -3
  end
end

-- DataConverter.prototype.downlinkAppConverter = function (txJson, downlinkJson, uplinkInfo) {
--   let _this = this;
--   const outputObject = {};
--   outputObject.version = uplinkInfo.version;
--   if (uplinkInfo.srcID && uplinkInfo.srcID.length > 0) {
--     outputObject.dstID = uplinkInfo.srcID;
--   }

--   outputObject.token = crypto.randomBytes(consts.UDP_TOKEN_LEN);
--   outputObject.identifier = Buffer.alloc(consts.UDP_IDENTIFIER_LEN);
--   outputObject.identifier.writeUInt8(consts.UDP_ID_PULL_RESP, 'hex');
--   outputObject.gatewayId = txJson.gatewayId;

--   function generateTxpkJson() {
--     let tempdata = {};
--     let MHDRJson = {};
--     let MACPayloadJson = {};
--     let FHDRJson = {};
--     let FCtrlJson = {};
--     const messageType = uplinkInfo.MHDR.MType;

--     if (messageType === consts.CONFIRMED_DATA_UP) {
--       MHDRJson.MType = consts.CONFIRMED_DATA_DOWN;
--       FCtrlJson.ACK = 1;
--     }

--     if (messageType === consts.UNCONFIRMED_DATA_UP) {
--       MHDRJson.MType = consts.UNCONFIRMED_DATA_DOWN;
--       FCtrlJson.ACK = 0;
--     }

--     MHDRJson.Major = uplinkInfo.MHDR.Major;
--     tempdata.MHDR = MHDRJson;

--     // if (txJson.DeviceConfig.ADR || txJson.DeviceConfig.ADR === false) {
--     //   FCtrlJson.ADR = txJson.DeviceConfig.ADR;
--     if (txJson.ADR || txJson.ADR === false) {
--       FCtrlJson.ADR = txJson.ADR;
--     } else {
--       FCtrlJson.ADR = uplinkInfo.MACPayload.FHDR.FCtrl.ADR;
--     }

--     FCtrlJson.FPending = downlinkJson.FPending ? downlinkJson.FPending : 0;
--     FCtrlJson.FOptsLen = downlinkJson.FOptsLen ? downlinkJson.FOptsLen : 0;

--     FHDRJson.DevAddr = uplinkInfo.MACPayload.FHDR.DevAddr;
--     FHDRJson.FCtrl = FCtrlJson;
--     FHDRJson.FCnt = Buffer.alloc(consts.FCNT_LEN);
--     // FHDRJson.FCnt.writeUInt32BE(txJson.DeviceInfo.AFCntDown);
--     FHDRJson.FCnt.writeUInt32BE(txJson.AFCntDown);

--     FHDRJson.FOpts = downlinkJson.FOpts ? downlinkJson.FOpts : [];

--     MACPayloadJson.FHDR = FHDRJson;

--     if (downlinkJson.isMacCmdInFRM && downlinkJson.FRMPayload.length > 0) {
--       MACPayloadJson.FPort = consts.MACCOMMANDPORT;
--       MACPayloadJson.FRMPayload = downlinkJson.FRMPayload;
--     } else if (downlinkJson.FRMPayload.length > 0) {
--       MACPayloadJson.FPort = uplinkInfo.MACPayload.FPort;
--       MACPayloadJson.FRMPayload = downlinkJson.FRMPayload;
--     } else {
--       MACPayloadJson.FPort = uplinkInfo.MACPayload.FPort;
--     }

--     tempdata.MACPayload = MACPayloadJson;

--     return {
--       imme: txJson.imme,
--       tmst: txJson.tmst,
--       freq: txJson.freq,
--       rfch: txJson.rfch,
--       powe: txJson.powe,
--       datr: txJson.datr,
--       modu: txJson.modu,
--       codr: txJson.codr,
--       ipol: txJson.ipol,
--       data: tempdata,
--     };
--   }

--   outputObject.txpk = generateTxpkJson();

--   return BluebirdPromise.resolve(outputObject);
-- };

function joinAcceptHandler(joinAcceptJson)
  local joinAcceptObj = joinAcceptJson
  local joinRfData = joinRfConverter(joinAcceptObj)
  local res = joinResHandler.handler(joinRfData)
  return downlinkDataHandler.joinAcceptDownlink(joinAcceptObj, joinAcceptConverter)
end

function joinAcceptConverter(rfJson, joinReqJson)
  local outputObject = {}
  outputObject.version = joinReqJson.version
  outputObject.token = crypto.randomBytes(consts.UDP_TOKEN_LEN)
  outputObject.identifier = Buffer:new(consts.UDP_IDENTIFIER_LEN)
  outputObject.identifier.writeUInt8(consts.UDP_ID_PULL_RESP, "hex")
  outputObject.gatewayId = rfJson.gatewayId

  function generateTxpkJson()
    return {
      imme = rfJson.imme,
      tmst = rfJson.tmst,
      freq = rfJson.freq,
      rfch = rfJson.rfch,
      powe = rfJson.powe,
      datr = rfJson.datr,
      modu = rfJson.modu,
      codr = rfJson.codr,
      ipol = rfJson.ipol,
      data = joinReqJson.rxpk.data
    }
  end

  outputObject.txpk = generateTxpkJson()

  return outputObject
end

-- DataConverter.prototype.applicationAcceptHandler = function (applicationAcceptJson) {
--   let _this = this;
--   let devAddr = applicationAcceptJson.DevAddr.toString('hex');
--   let FRMPayload = applicationAcceptJson.FRMPayload.toString('hex');
--   const msgQueKey = consts.DOWNLINK_MQ_PREFIX + devAddr;
--   return _this.redisConnMsgQue.produceByHTTP(msgQueKey, FRMPayload);
-- }

-- DataConverter.prototype.mongooseSave = function (collectionName, mongoSavedObj) {

--   //The message is saved in mongo db
--   let msgModel;

--   switch (collectionName) {

--     //TODO
--     default:
--       break;
--   }

--   try {
--     msgModel = mongoose.model(collectionName);
--   } catch (err) {
--     msgModel = mongoose.model(collectionName, mongoSavedSchema, collectionName);
--   }

--   return msgModel.create(mongoSavedObj);
-- };
-- module.exports = DataConverter;
return {
  uplinkDataHandler = uplinkDataHandler
}
