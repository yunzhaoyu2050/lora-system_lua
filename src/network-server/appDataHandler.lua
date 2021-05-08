local consts = require("../lora-lib/constants/constants.lua")
local config = require("../server_cfg.lua")
local DeviceInfoRedis = require("../lora-lib/models/RedisModels/DeviceInfo.lua")

-- 'use strict';

-- const BluebirdPromise = require('bluebird');
-- const _ = require('lodash');
-- const config = require('../../config');
-- const pubToASTopic = config.mqClient_ns.topics.pubToApplicationServer;
-- const pubToCSTopic = config.mqClient_ns.topics.pubToControllerServer;
local fcntCheckEnable = config.GetFcntCheckEnable()
-- const loraLib = require('../lora-lib');
-- const { consts, ERROR } = loraLib;
-- const PubControllerModel = require('./models/pubControllerModel');

-- function AppDataHandler(mqClient, redisConn, mysqlConn, log) {
--   this.DeviceStatus = mysqlConn.DeviceStatus;
--   this.DeviceConfig = mysqlConn.DeviceConfig;
--   this.DeviceRouting = mysqlConn.DeviceRouting;
--   this.DeviceInfoMysql = mysqlConn.DeviceInfo;
--   this.DeviceInfoRedis = redisConn.DeviceInfo;
--   this.mqClient = mqClient;
--   this.log = log;

-- }

local function getFreqPlan(freq, freqList)
  if freq >= freqList[1] and freq < freqList[2] then
    return freqList[1]
  elseif freq >= freqList[2] and freq < freqList[3] then
    return freqList[2]
  elseif freq >= freqList[3] and freq < freqList[4] then
    return freqList[3]
  elseif freq >= freqList[4] then
    return freqList[4]
  else
    p("freq is not int freqList", freq)
    return nil
  end
end

local function updateDeviceRouting(deviceStatus)
  local freqPlanOffset
  local function getDatr(datr, RX1DROFFSET)
    local dr = consts.DR_PARAM
    local RX1DROFFSETTABLE = dr.RX1DROFFSETTABLE[freqPlanOffset]
    local DRUP = dr.DRUP[freqPlanOffset]
    local DRDOWN = dr.DRDOWN[freqPlanOffset]

    for key, _ in pairs(DRDOWN) do
      if RX1DROFFSETTABLE[DRUP[datr]][RX1DROFFSET] == DRDOWN[key] then
        return key
      end
    end

    return datr
  end

  -- let whereOpts = { DevAddr: deviceStatus.DevAddr };
  -- return _this.DeviceConfig.readItem(whereOpts).then(function (res) {
  local res = DeviceInfoRedis.Read(deviceStatus.DevAddr)
  if (res) then
    if res.frequencyPlan == nil then
      p("DevAddr does not exist frequencyPlan in DeviceConfig", deviceStatus.DevAddr)
      return nil
    end

    if (res.RX1DRoffset == nil and res.RX1DRoffset ~= 0) then
      p("DevAddr does not exist RX1DRoffset in DeviceConfig", deviceStatus.DevAddr)
      return nil
    end

    if (res.RX1Delay == nil and res.RX1Delay ~= 0) then
      p("DevAddr does not exist RX1Delay in DeviceConfig", deviceStatus.DevAddr)
    end

    freqPlanOffset = getFreqPlan(res.frequencyPlan, consts.FREQUENCY_PLAN_LIST)

    local tmstOffset
    if (res.RX1Delay == 0) then
      tmstOffset = 1 * 1000 * 1000
    elseif (res.RX1Delay > 15) then
      p("DevAddr RX1Delay more than 15 in DeviceConfig", deviceStatus.DevAddr)
      return nil
    else
      tmstOffset = res.RX1Delay * 1000 * 1000
    end
    local updateOpts = {
      gatewayId = deviceStatus.gatewayId,
      tmst = deviceStatus.tmst + tmstOffset,
      freq = consts.TXPK_CONFIG.FREQ[freqPlanOffset](
        function()
          if freqPlanOffset == (consts.PLANOFFSET915 + 1) then
            return deviceStatus.chan
          else
            return deviceStatus.freq
          end
        end
      ),
      powe = consts.TXPK_CONFIG.POWE[freqPlanOffset],
      datr = getDatr(deviceStatus.datr, res.RX1DRoffset),
      modu = deviceStatus.modu,
      codr = deviceStatus.codr
      -- imme = false,
      -- ipol = false
    }

    local query = {
      DevAddr = deviceStatus.DevAddr
    }

    -- return _this.DeviceRouting.upsertItem(updateOpts);
    return DeviceInfoRedis.UpdateItem(query, updateOpts)
  else
    p("DevAddr does not exist in DeviceConfig", deviceStatus.DevAddr)
    return nil
  end
end

function handle(rxInfoArr, appObj)
  local optimalRXInfo = rxInfoArr[0]

  -- console.log('rxInfoArr',rxInfoArr);
  -- console.log('appObj', appObj);

  local uploadDataDevAddr = appObj.MACPayload.FHDR.DevAddr
  local uplinkFCnt = appObj.MACPayload.FHDR.FCnt
  local newFCnt
  if fcntCheckEnable then
    local preFCnt = appObj.FCntUp
    local newUplinkFCntNum = uplinkFCnt:readUInt32BE()
    local mulNum = preFCnt / 65536 -- string to number
    local remainderNum = preFCnt % 65536

    if (newUplinkFCntNum > remainderNum and newUplinkFCntNum - remainderNum < consts.MAX_FCNT_DIFF) then
      newFCnt = mulNum * 65536 + newUplinkFCntNum
    elseif (remainderNum > newUplinkFCntNum and newUplinkFCntNum + 65536 - remainderNum < consts.MAX_FCNT_DIFF) then
      newFCnt = (mulNum + 1) * 65536 + newUplinkFCntNum
    elseif (remainderNum == newUplinkFCntNum) then
      newFCnt = preFCnt
    else
      p("Invalid FCnt", uploadDataDevAddr, preFCnt, newUplinkFCntNum)
      return nil
    end
  else
    newFCnt = uplinkFCnt:readUInt32BE()
  end

  function uploadToAS(appObj)
    local topic = pubToASTopic
    local message = {
      DevAddr = appObj.MACPayload.FHDR.DevAddr,
      FRMPayload = appObj.MACPayload.FRMPayload
    }

    return _this.mqClient.publish(topic, message) -- 推送至app服务器上
  end

  function storeRXInfoToMysql(rxInfoArr)
    -- 存储rxinfo信息
    -- return BluebirdPromise.map(rxInfoArr, function (item) {
    --   return _this.DeviceStatus.createItem(item);
    -- });
    return DeviceStatus.createItem(item) -- 设备状态存储
  end

  function uploadToCS(rxInfoArr, appObj)
    local macCmdArr = {}
    local fport = appObj.MACPayload.FPort:readInt8()
    local fOptsLen = appObj.MACPayload.FHDR.FCtrl.FOptsLen
    if fport == 0 and appObj.MACPayload.FRMPayload then
      macCmdArr = appObj.MACPayload.FRMPayload
    elseif fOptsLen > 0 and appObj.MACPayload.FHDR.FOpts then
      macCmdArr = appObj.MACPayload.FHDR.FOpts
    end

    local adr = appObj.MACPayload.FHDR.FCtrl.ADR
    local pubControllerModel
    if macCmdArr.length > 0 then
      pubControllerModel = new
      PubControllerModel(rxInfoArr, adr, macCmdArr)
    else
      if (adr == 1) then
        pubControllerModel = new
        PubControllerModel(rxInfoArr, adr)
      else
        return BluebirdPromise.resolve()
      end

      local topic = pubToCSTopic
      local message = {
        DevAddr = pubControllerModel.getDevAddr(),
        data = pubControllerModel.getCMDdata(),
        adr = pubControllerModel.getadr(),
        devtx = pubControllerModel.getdevtx(),
        gwrx = pubControllerModel.getgwrx()
      }

      -- _this.log.info({
      --   label: `Pub to ${topic}`,
      --   message: message,
      -- });

      return _this.mqClient.publish(topic, message) -- 推送至控制服务器上
    end

    local res = updateDeviceRouting(optimalRXInfo)
    res = DeviceInfoRedis.update(uploadDataDevAddr, {FCntUp = newFCnt})
    -- DeviceInfoMysql.increaseFcntup(uploadDataDevAddr, newFCnt)
    res = uploadToAS(appObj)
    res = uploadToCS(rxInfoArr, appObj)
    return {rxInfoArr, appObj}
  end
end

return {
  handle = handle
}
