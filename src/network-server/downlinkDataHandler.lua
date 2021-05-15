local RedisDeviceInfo = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local consts = require("../lora-lib/constants/constants.lua")
local buffer = require("buffer").Buffer
local MysqlDeviceInfo = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
-- 'use strict';

-- const BluebirdPromise = require('bluebird');
-- const consts = require('../lora-lib/constants');
-- const config = require('../../config');
-- const pubNCTopic = config.mqClient_ns.topics.pubToConnector;

-- function DownlinkDataHandler(mqClient, redisConn, mysqlConn, log, options) {
--   let _this = this;

--   /* properties */
--   this.options = options || {};

--   this.redisConnMsgQue = redisConn.MessageQueue;
--   this.redisConnMacCmdQue = redisConn.MacCmdQueue;
--   this.DeviceInfoRedis = redisConn.DeviceInfo;
--   this.mysqlConn = mysqlConn;
--   this.mqClient = mqClient;
--   this.log = log;

-- }

-- app-data下行数据处理
function appDataDownlink(uplinkData, convertFn)
  p("<-------uplinkData Info------------>")
  p("   uplinkData:", uplinkData)
  local uplinkInfo = uplinkData
  local DevAddr = uplinkInfo.MACPayload.FHDR.DevAddr
  local ret = nil

  local generateDownlink = function(txJson, downlinkJson) -- 生成下行数据包
    local dlkObj = convertFn(txJson, downlinkJson, uplinkInfo) -- 下行数据打包
    if dlkObj == nil then
      p("Generate downlink object failed")
      return nil
    end
    p("<-------Downlink Object------------>")
    p("   dlkObj:", dlkObj)
    -- publish schema-valid downlink data to NC-sub
    -- TODO : increaseNfcntdown (for MAC Command)
    ret = RedisDeviceInfo.IncreaseAfcntdown(DevAddr)
    -- return _this.mysqlConn.DeviceInfo.increaseAfcntdown(DevAddr);
    -- 将数据推送至network connector模块
    return dlkObj
  end

  local downlinkDataHandler = function(resolve, reject)
    -- local macCmdQueAnsKey = consts.MACCMDQUEANS_PREFIX + DevAddr.toString('hex');
    -- local macCmdQueReqKey = consts.MACCMDQUEREQ_PREFIX + DevAddr.toString('hex');
    -- local msgQueKey = consts.DOWNLINK_MQ_PREFIX + DevAddr.toString('hex');

    local downlinkJson = {
      FPending = 0,
      FOptsLen = 0,
      FOpts = buffer:new(0),
      FRMPayload = buffer:new(0),
      isMacCmdInFRM = false,
      ackbit = 0
    }

    local messageType = uplinkInfo.MHDR.MType
    local messageFPort = uplinkInfo.MACPayload.FPort

    if messageType == consts.CONFIRMED_DATA_UP then
      downlinkJson.ackbit = 1
    end

    -- Get txpk config from db
    -- return _this.mysqlConn.getTxpkInfo(DevAddr).then(function (txJson) {
    local txJson = RedisDeviceInfo.read(DevAddr)

    -- const frequencyPlan = txJson.DeviceConfig.frequencyPlan;
    local frequencyPlan = txJson.frequencyPlan
    local downlinkDatr = txJson.datr
    local repeaterCompatible = false
    -- const protocolVersion = txJson.DeviceInfo.ProtocolVersion;
    local protocolVersion = txJson.ProtocolVersion
    local maxFRMPayloadAndFOptSize =
      getMaxFRMPayloadAndFOptByteLength(frequencyPlan, txJson.datr, repeaterCompatible, protocolVersion)

    if maxFRMPayloadAndFOptSize == 0 then
      p(
        "Get max FRMPayload & FOpt Byte Length Error",
        {
          DevAddr = DevAddr,
          frequencyPlan = frequencyPlan,
          downlinkDatr = downlinkDatr
        }
      )
    end

    -- Consume mac cmd answer queue
    local cmdAnsArr = redisConnMacCmdQue.consumeAll(macCmdQueAnsKey)
    if cmdAnsArr then
      -- Mac cmd answer queue has data
      if cmdAnsArr and cmdAnsArr.length > 0 then
        downlinkJson.ackbit = 1
        local macCmdDownLen = getMacCmdDownByteLength(cmdAnsArr)

        if macCmdDownLen > consts.FOPTS_MAXLEN then
          downlinkJson.isMacCmdInFRM = true
          downlinkJson.FRMPayload = cmdAnsArr

          local remainSize = maxFRMPayloadAndFOptSize - macCmdDownLen

          if remainSize < 0 then
            p(
              "RemainSize less than 0",
              {
                DevAddr = DevAddr,
                macCmdAns = cmdAnsArr,
                macCmdDownLen = macCmdDownLen,
                maxSize = maxFRMPayloadAndFOptSize
              }
            )
            return nil
          end

          local cmdReqArr = redisConnMacCmdQue.read(macCmdQueReqKey)
          if (cmdReqArr and cmdReqArr.length > 0) then
            for i = 1, cmdReqArr.length do
              local macByteLen = 0
              for key, _ in pairs(cmdReqArr[i]) do
                local cid = parseInt(key, 16)
                if (cid == consts.MACCMD_DOWNLINK_LIST) then
                  macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_DOWNLINK_LIST[cid]
                end
              end

              remainSize = remainSize - macByteLen
              if remainSize >= 0 then
                downlinkJson.FRMPayload.push(cmdReqArr[i])
              else
                if i < cmdReqArr.length - 1 then
                  downlinkJson.FPending = 1
                end

                break
              end
            end
          end

          res = redisConnMsgQue.checkQueueLength(msgQueKey)

          if (res and res > 0) then
            downlinkJson.FPending = 1
          end
          return generateDownlink(txJson, downlinkJson)
        elseif macCmdDownLen <= consts.FOPTS_MAXLEN then
          downlinkJson.FOptsLen = macCmdDownLen
          downlinkJson.FOpts = cmdAnsArr

          cmdReqArr = redisConnMacCmdQue.read(macCmdQueReqKey)

          if (cmdReqArr and cmdReqArr.length > 0) then
            for i = 0, cmdReqArr.length do
              local macByteLen = 0
              for key, _ in pairs(cmdReqArr[i]) do
                local cid = parseInt(key, 16)
                if (cid == consts.MACCMD_DOWNLINK_LIST) then
                  macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_DOWNLINK_LIST[cid]
                end
              end

              if macByteLen + downlinkJson.FOptsLen <= consts.FOPTS_MAXLEN then
                downlinkJson.FOptsLen = macByteLen + downlinkJson.FOptsLen
                downlinkJson.FOpts.push(cmdReqArr[i])
              else
                if (i < cmdReqArr.length - 1) then
                  downlinkJson.FPending = 1
                end

                break
              end
            end
          end

          res = redisConnMsgQue.consume(msgQueKey)

          if (res and res.hasOwnProperty("pbdata")) then
            downlinkJson.FRMPayload = Buffer.from(res.pbdata, "hex")
          end

          if (downlinkJson.FRMPayload.length > maxFRMPayloadAndFOptSize) then
            p(
              "App data Length exceeds the maximum length in FRMPayload",
              {
                DevAddr = DevAddr,
                maxFRMPayloadAndFOptSize = maxFRMPayloadAndFOptSize,
                appDataLength = downlinkJson.FRMPayload.length
              }
            )
            return nil
          end

          return generateDownlink(txJson, downlinkJson)
        end

        -- Mac cmd answer queue has NO data
        -- Read Mac cmd request queue
        cmdReqArr = redisConnMacCmdQue.read(macCmdQueReqKey)

        -- //Mac cmd request queue has data
        if (cmdReqArr and cmdReqArr.length > 0) then
          downlinkJson.ackbit = 1
          local macCmdDownLen = getMacCmdDownByteLength(cmdReqArr)
          if (macCmdDownLen > consts.FOPTS_MAXLEN) then
            local macCmdDownLen = getMacCmdDownByteLength(cmdReqArr)

            downlinkJson.isMacCmdInFRM = true
            downlinkJson.FRMPayload = cmdReqArr.concat()

            if (macCmdDownLen > maxFRMPayloadAndFOptSize) then
              p(
                "MAC commands request Length exceeds the maximum length  in FRMPayload && delete reqest queue",
                {
                  DevAddr = DevAddr,
                  maxFRMPayloadAndFOptSize = maxFRMPayloadAndFOptSize,
                  macReqLength = downlinkJson.FRMPayload.length
                }
              )
            end

            res = redisConnMsgQue.checkQueueLength(msgQueKey)
            if (res and res > 0) then
              downlinkJson.FPending = 1
            end

            return generateDownlink(txJson, downlinkJson)
          elseif (macCmdDownLen <= consts.FOPTS_MAXLEN) then
            downlinkJson.FOptsLen = macCmdDownLen
            downlinkJson.FOpts = cmdReqArr.concat()
          end
        end

        -- Mac cmd request queue has data || Mac cmd request queue length <= FOPTS_MAXLEN
        res = redisConnMsgQue.consume(msgQueKey)

        if (res == nil and downlinkJson.ackbit == nil) then
          p("The message has no downlink object:")
          return nil
        end

        if (res and res.hasOwnProperty("pbdata")) then
          downlinkJson.FRMPayload = Buffer.from(res.pbdata, "hex")
        end

        if (downlinkJson.FRMPayload.length > maxFRMPayloadAndFOptSize) then
          p(
            "App data Length exceeds the maximum length in FRMPayload",
            {
              DevAddr = DevAddr,
              maxFRMPayloadAndFOptSize = maxFRMPayloadAndFOptSize,
              appDataLength = downlinkJson.FRMPayload.length
            }
          )
        end

        return generateDownlink(txJson, downlinkJson)
      end
    end
  end

  local UpdateData = function(downlinkData) -- 更新数据库
    -- Persist Redis data to Mysql
    local res = RedisDeviceInfo.read(DevAddr)
    if res == nil then
      p("Failed to persist Redis data to Mysql. No data in Redis", {DevAddr = DevAddr})
      return nil
    end
    if downlinkData then
      -- return _this.mysqlConn.DeviceRouting.upsertItem(persistDataToDeviceRouting);
      local persistDataToDeviceInfo = {
        FCntUp = res.FCntUp,
        AFCntDown = res.AFCntDown,
        NFCntDown = res.NFCntDown
      }
      local persistDataToDeviceRouting = {
        DevAddr = DevAddr,
        gatewayId = res.gatewayId,
        imme = res.imme,
        tmst = res.tmst,
        freq = res.freq,
        powe = res.powe,
        datr = res.datr,
        modu = res.modu,
        codr = res.codr
      }
      return MysqlDeviceInfo.updateItem({DevAddr = DevAddr}, persistDataToDeviceInfo)
    else
      local persistDataToDeviceInfo = {
        FCntUp = res.FCntUp
      }
      return MysqlDeviceInfo.updateItem({DevAddr = DevAddr}, persistDataToDeviceInfo)
    end
  end

  -- main
  uv.sleep(config.GetDownlinkDataDelay()) -- delay 500 ms from config
  local downlinkData = downlinkDataHandler(resolve, reject)
  ret = UpdateData(downlinkData)
  return downlinkData
end

function getMacCmdDownByteLength(macCmdArr)
  local macByteLen = 0
  -- macCmdArr.forEach(element => {
  --   local cid;
  --   for (local key in element) {
  --     cid = parseInt(key, 16);
  --   }

  --   if (cid in consts.MACCMD_DOWNLINK_LIST) then
  --     macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_DOWNLINK_LIST[cid];
  --   end
  -- });
  return macByteLen
end

function getMacCmdUpByteLength(macCmdArr)
  local macByteLen = 0
  -- macCmdArr.forEach(element => {
  --   local cid;
  --   for (local key in element) {
  --     cid = parseInt(key, 16);
  --   }

  --   if (cid in consts.MACCMD_UPLINK_LIST) {
  --     macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_UPLINK_LIST[cid];
  --   }
  -- });
  return macByteLen
end

function getMaxFRMPayloadAndFOptByteLength(frequencyPlan, datr, repeaterCompatible, protocolVersion)
  -- let _this = this;
  local maxByteLen = 0
  -- TODO Add protocolVersion Check
  if (repeaterCompatible == false) then
    maxByteLen = consts.MAX_FRMPAYLOAD_SIZE_NOREPEATER[frequencyPlan][datr]
  else
    maxByteLen = consts.MAX_FRMPAYLOAD_SIZE_REPEATER[frequencyPlan][datr]
  end
  return maxByteLen
end

-- 下行join-accept数据处理
function joinAcceptDownlink(joinAcceptJson, convertFn)
  local devAddr = joinAcceptJson.rxpk.data.DevAddr
  -- local query = {
  --   DevAddr = devAddr
  -- }
  local res = RedisDeviceInfo.Read(devAddr) -- 读取存储的所有内容
  if res == nil then
    p("get txpk config from db failed.")
    return -2
  end
  local dlkObj = convertFn(res, joinAcceptJson)
  -- 把数据推送至connector模块处理
  return dlkObj
end

return {
  joinAcceptDownlink = joinAcceptDownlink,
  appDataDownlink = appDataDownlink
}
