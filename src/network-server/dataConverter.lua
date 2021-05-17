local downlinkDataHandler = require("./downlinkDataHandler.lua")
local joinResHandler = require("./joinResHandler.lua")
local consts = require("../lora-lib/constants/constants.lua")
-- local joinResHandler = require("./joinResHandler.lua")
local gatewayStatConverter = require("./gatewayStatHandler.lua")
local gatewayInfoRedis = require("../lora-lib/models/RedisModels/GatewayInfo.lua")
local DeviceInfoRedis = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local connector = require("../network-connector/connector.lua")
local buffer = require("buffer").Buffer
local crypto = require("../../deps/lua-openssl/lib/crypto.lua")
local utiles = require("../../utiles/utiles.lua")
local DeviceInfoMysql = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")

local appDataHandler = require("./appDataHandler.lua")
-- local lcrypto = require("../../deps/luvit-github/deps/tls/lcrypto.lua")
-- local appDataHandler = require("./appDataHandler.lua")

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

local function rxInfoConverter(uplinkDataJson)
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

-- app数据对象
local function appDataConverter(uplinkDataJson)
  local appDataObject = uplinkDataJson.rxpk.data
  appDataObject.version = uplinkDataJson.version
  if uplinkDataJson.srcID then
    appDataObject.srcID = uplinkDataJson.srcID
  else
    appDataObject.srcID = ""
  end
  local appFRMPayloadBuf = appDataObject.MACPayload.FRMPayload
  if appFRMPayloadBuf ~= nil then
    local devaddr = utiles.BufferToHexString(appDataObject.MACPayload.FHDR.DevAddr)
    local res = DeviceInfoRedis.readItem({DevAddr = devaddr}, {"FCntUp"})
    if res.FCntUp ~= nil then
      appDataObject.FCntUp = res.FCntUp
      res = DeviceInfoMysql.readItem({DevAddr = devaddr}, {"AppEUI"})
      if res.AppEUI ~= nil then
        appDataObject.AppEUI = res.AppEUI
        return appDataObject
      else
        p("DevAddr AppEUI does not exist in mysql DeviceInfo")
        return nil
      end
    else
      p("DevAddr FCntUp does not exist in redis DeviceInfo")
      return nil
    end
  end
  p("The uplink data has no {MACPayload.FRMPayload}")
  return nil
end

-- 上行数据处理单元
-- @return 状态, 处理后的数据
function uplinkDataHandler(jsonData)
  local ret = nil
  local uplinkDataJson = jsonData
  local uplinkDataId = jsonData.identifier
  if uplinkDataId == consts.UDP_ID_PUSH_DATA then
    if uplinkDataJson.rxpk ~= nil then -- Recive PUSH data
      -- Recive PUSH data from Node
      if uplinkDataJson.rxpk.data == nil then
        p('Uplink Json has no "data" in rxpk')
        return "other", nil
      end

      local messageType = uplinkDataJson.rxpk.data.MHDR.MType

      if messageType == consts.UNCONFIRMED_DATA_UP or messageType == consts.CONFIRMED_DATA_UP then -- Application message
        p("receive App data message")
        local rxInfoArr = rxInfoConverter(uplinkDataJson)
        local appObj = appDataConverter(uplinkDataJson)
        if appObj ~= nil then
          -- p("uplinkDataJson",uplinkDataJson)
          local uplinkInfo = appDataHandler.handle(rxInfoArr, appObj) -- 将Application message推送至app模块处理
          if uplinkInfo == nil then
            return "other", nil
          end
          -- Data messages 用来传输MAC命令和应用数据， 这两种命令也可以放在单个消息中发送。
          -- Confirmed-data message 接收者需要应答。 Unconfirmed-data message 接收者则不需要应
          -- 答。 Proprietary messages 用来处理非标准的消息格式， 不能和标准消息互通， 只能用来和
          -- 具有相同拓展格式的消息进行通信。
          if messageType == consts.UNCONFIRMED_DATA_UP then
            p("MType is UNCONFIRMED_DATA_UP, No need to send downstream data")
            return "other", nil
          elseif messageType == consts.CONFIRMED_DATA_UP then
            p("MType is CONFIRMED_DATA_UP ...")
          end

          if uplinkInfo and uplinkInfo.appObj then
            local uplinkInfoAppObj = uplinkInfo.appObj
            local appEUIStr = uplinkInfoAppObj.AppEUI
            ret = downlinkDataHandler.appDataDownlink(uplinkInfoAppObj, downlinkAppConverter)
          end
          p("app module _> server module, send app accept message")
          return "AppPubToServer", ret
        end
        return "other", nil
      end

      if messageType == consts.JS_MSG_TYPE.request then -- Join request message
        p("receive Join request message")
        ret = joinResHandler.joinRequestHandle(uplinkDataJson) -- 将Join request message推送至join-server模块
        if ret == nil then
          return "other", nil
        end
        p("join module _> server module, send join accept message")
        return "JoinPubToServer", ret -- 把数据推送至network-connector模块
      end
    elseif uplinkDataJson.stat ~= nil then -- Recive Stat data
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
        return "other", nil
      else
        p("No UserID in Reids about the gateway")
        return "other", nil
      end
    else
      p('Error key value of received JSON (NO "rxpk" or "stat")')
      return "other", nil
    end
  elseif uplinkDataId == consts.UDP_ID_PULL_DATA then
    -- TODO:
    p("Recive UDP Pull Data")
    return "other", nil
  elseif uplinkDataId == consts.UDP_ID_TX_ACK then
    -- TODO:
    p("Recive UDP TX_ACK")
    return "other", nil
  else
    p("Error UDP package identifier")
    return "other", nil
  end
end

function downlinkAppConverter(txJson, downlinkJson, uplinkInfo)
  local outputObject = {}
  outputObject.version = uplinkInfo.version
  if uplinkInfo.srcID and uplinkInfo.srcID.length > 0 then
    outputObject.dstID = uplinkInfo.srcID
  end

  outputObject.token = crypto.randomBytes(consts.UDP_TOKEN_LEN)
  outputObject.identifier = buffer:new(consts.UDP_IDENTIFIER_LEN)
  outputObject.identifier.writeUInt8(consts.UDP_ID_PULL_RESP, "hex")
  outputObject.gatewayId = txJson.gatewayId

  local function generateTxpkJson()
    local tempdata = {}
    local MHDRJson = {}
    local MACPayloadJson = {}
    local FHDRJson = {}
    local FCtrlJson = {}
    local messageType = uplinkInfo.MHDR.MType

    if messageType == consts.CONFIRMED_DATA_UP then
      MHDRJson.MType = consts.CONFIRMED_DATA_DOWN
      FCtrlJson.ACK = 1
    end

    if messageType == consts.UNCONFIRMED_DATA_UP then
      MHDRJson.MType = consts.UNCONFIRMED_DATA_DOWN
      FCtrlJson.ACK = 0
    end

    MHDRJson.Major = uplinkInfo.MHDR.Major
    tempdata.MHDR = MHDRJson

    if txJson.ADR or txJson.ADR == false then
      FCtrlJson.ADR = txJson.ADR
    else
      FCtrlJson.ADR = uplinkInfo.MACPayload.FHDR.FCtrl.ADR
    end

    if downlinkJson.FPending > 0 then
      FCtrlJson.FPending = downlinkJson.FPending
    else
      FCtrlJson.FPending = 0
    end
    if downlinkJson.FOptsLen > 0 then
      FCtrlJson.FOptsLen = downlinkJson.FOptsLen
    else
      FCtrlJson.FOptsLen = 0
    end

    FHDRJson.DevAddr = uplinkInfo.MACPayload.FHDR.DevAddr
    FHDRJson.FCtrl = FCtrlJson
    FHDRJson.FCnt = buffer:new(consts.FCNT_LEN)
    -- // FHDRJson.FCnt.writeUInt32BE(txJson.DeviceInfo.AFCntDown);
    FHDRJson.FCnt.writeUInt16BE(1, txJson.AFCntDown) -- writeUInt32BE

    if downlinkJson.FOpts then
      FHDRJson.FOpts = downlinkJson.FOpts
    else
      FHDRJson.FOpts = buffer:new(0)
    end

    MACPayloadJson.FHDR = FHDRJson

    if downlinkJson.isMacCmdInFRM and downlinkJson.FRMPayload.length > 0 then
      MACPayloadJson.FPort = consts.MACCOMMANDPORT
      MACPayloadJson.FRMPayload = downlinkJson.FRMPayload
    elseif downlinkJson.FRMPayload.length > 0 then
      MACPayloadJson.FPort = uplinkInfo.MACPayload.FPort
      MACPayloadJson.FRMPayload = downlinkJson.FRMPayload
    else
      MACPayloadJson.FPort = uplinkInfo.MACPayload.FPort
    end

    tempdata.MACPayload = MACPayloadJson

    return {
      imme = txJson.imme,
      tmst = txJson.tmst,
      freq = txJson.freq,
      rfch = txJson.rfch,
      powe = txJson.powe,
      datr = txJson.datr,
      modu = txJson.modu,
      codr = txJson.codr,
      ipol = txJson.ipol,
      data = tempdata
    }
  end

  outputObject.txpk = generateTxpkJson()

  return outputObject
end

local function joinRfConverter(joinDataJson) -- 取出rf层数据信息
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

-- join-accept消息下行数据打包
local function joinAcceptConverter(rfJson, joinReqJson)
  local outputObject = {}
  outputObject.version = joinReqJson.version
  outputObject.token = crypto.rand.bytes(consts.UDP_TOKEN_LEN)
  -- p("token:", crypto.hex(outputObject.token))
  outputObject.token = crypto.hex(outputObject.token)
  -- outputObject.identifier = buffer:new(consts.UDP_IDENTIFIER_LEN)
  -- outputObject.identifier:writeUInt8(1, consts.UDP_ID_PULL_RESP) -- UDP_ID_PULL_RESP
  outputObject.identifier = consts.UDP_ID_PULL_RESP -- UDP_ID_PULL_RESP
  outputObject.gatewayId = rfJson.gatewayId
  local generateTxpkJson = function()
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

-- join-accept消息下行数据处理单元
function joinAcceptHandler(joinAcceptJson)
  local joinAcceptObj = joinAcceptJson
  local joinRfData = joinRfConverter(joinAcceptObj) -- 网关与服务器之间的通讯数据
  local res = joinResHandler.handler(joinRfData) -- 下行数据统计数据库更新
  res = downlinkDataHandler.joinAcceptDownlink(joinAcceptObj, joinAcceptConverter)
  return "other", res
end

-- app-accept消息下行数据处理单元
function applicationAcceptHandler(applicationAcceptJson)
  -- let _this = this;
  local devAddr = utiles.BufferToHexString(applicationAcceptJson.DevAddr)
  local FRMPayload = applicationAcceptJson.FRMPayload
  -- const msgQueKey = consts.DOWNLINK_MQ_PREFIX + devAddr;
  return _this.redisConnMsgQue.produceByHTTP(msgQueKey, FRMPayload) -- 将处理好的数据发给connector模块
end

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
  uplinkDataHandler = uplinkDataHandler,
  joinAcceptHandler = joinAcceptHandler,
  applicationAcceptHandler = applicationAcceptHandler
}
