local consts = require("../lora-lib/constants/constants.lua")
local config = require("../../server_cfg.lua")
local DeviceInfoRedis = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local utiles = require("../../utiles/utiles.lua")
local appServer = require("../application-server/application-server.lua")
local buffer = require("buffer").Buffer
local PubControllerModel = require("./pubControllerModel.lua")
local controllerHandle = require("../network-controller/controller.lua")
local logger = require("../log.lua")

-- app data 上行处理流程 - 更新设备路由信息
local function updateDeviceRouting(deviceStatus)
  local freqPlanOffset

  local devaddr = utiles.BufferToHexString(deviceStatus.DevAddr)

  local res = DeviceInfoRedis.Read(devaddr)
  if res ~= nil then
    if res.frequencyPlan == nil then
      logger.error({"DevAddr does not exist frequencyPlan in DeviceInfo, devaddr:%s", devaddr})
      return nil
    end

    if (res.RX1DRoffset == nil and res.RX1DRoffset ~= 0) then
      logger.error({"DevAddr does not exist RX1DRoffset in DeviceInfo, devaddr:%s", devaddr})
      return nil
    end

    if (res.RX1Delay == nil and res.RX1Delay ~= 0) then
      logger.error({"DevAddr does not exist RX1Delay in DeviceInfo, devaddr:%s", devaddr})
      return nil
    end

    freqPlanOffset = consts.GetISMFreqPLanOffset(deviceStatus.freq)
    if freqPlanOffset == nil then
      return nil
    end

    local tmstOffset  -- DeviceInfoRedis 中 RX1Delay单位1s
    if res.RX1Delay == 0 then
      tmstOffset = 1 * 1000 * 1000 -- 1s
    elseif res.RX1Delay > 15 * 1000 then
      logger.error({"DevAddr RX1Delay more than 15 in DeviceInfo, devaddr:%s", devaddr})
      return nil
    else
      tmstOffset = res.RX1Delay * 1000 -- 转换成ns RX1Delay是按照ms存储的
    end

    local immeVal = false
    local ipolVal = false
    local NcrcVal = nil
    local rfchVal = 0
    if config.GetEnableImme() ~= nil then
      immeVal = config.GetEnableImme()
    end
    if config.GetEnableIpol() ~= nil then
      ipolVal = config.GetEnableIpol()
    end
    if config.GerEnableNcrc() ~= nil then
      NcrcVal = config.GerEnableNcrc()
    end
    if config.GerEnableRfch() ~= nil then
      rfchVal = config.GerEnableRfch()
    end

    local updateOpts = {
      gatewayId = deviceStatus.gatewayId,
      tmst = deviceStatus.tmst + tmstOffset,
      freq = consts.TXPK_CONFIG.FREQ[freqPlanOffset](
        function()
          return deviceStatus.freq
        end
      ),
      powe = consts.TXPK_CONFIG.POWE[freqPlanOffset](),
      datr = consts.GetDatr(deviceStatus.datr, res.RX1DRoffset, freqPlanOffset),
      modu = deviceStatus.modu,
      codr = deviceStatus.codr,
      imme = immeVal,
      ipol = ipolVal,
      rfch = rfchVal
    }
    if NcrcVal ~= nil then
      updateOpts.NcrcVal = NcrcVal
    end

    local query = {
      DevAddr = utiles.BufferToHexString(deviceStatus.DevAddr)
    }

    return DeviceInfoRedis.UpdateItem(query, updateOpts)
  else
    logger.error({"DevAddr does not exist in DeviceConfig, devaddr:", utiles.BufferToHexString(deviceStatus.DevAddr)})
    return nil
  end
end

-- app data处理
function handle(rxInfoArr, appObj)
  local optimalRXInfo = rxInfoArr -- 包括gatewayId、DevAddr

  local uploadDataDevAddr = utiles.BufferToHexString(appObj.MACPayload.FHDR.DevAddr)
  local uplinkFCnt = appObj.MACPayload.FHDR.FCnt

  local newFCnt

  local isEnable = config.GetFcntCheckEnable()
  if isEnable == true then -- 查看服务器配置是否使能fcnt统计
    -- local preFCnt = appObj.FCntUp -- TODO:
    -- local newUplinkFCntNum = uplinkFCnt:readUInt16BE(1)
    -- local mulNum = preFCnt / 65536
    -- local remainderNum = preFCnt % 65536

    -- if newUplinkFCntNum > remainderNum and newUplinkFCntNum - remainderNum < consts.MAX_FCNT_DIFF then
    --   newFCnt = mulNum * 65536 + newUplinkFCntNum
    -- elseif remainderNum > newUplinkFCntNum and newUplinkFCntNum + 65536 - remainderNum < consts.MAX_FCNT_DIFF then
    --   newFCnt = (mulNum + 1) * 65536 + newUplinkFCntNum
    -- elseif remainderNum == newUplinkFCntNum then
    --   newFCnt = preFCnt
    -- else
    --   p("Invalid FCnt", uploadDataDevAddr, preFCnt, newUplinkFCntNum)
    --   return nil
    -- end
  else
    newFCnt = uplinkFCnt:readUInt16BE(1)
  end

  local function uploadToAS(appObj) -- 推送至app模块处理
    local message = {
      DevAddr = appObj.MACPayload.FHDR.DevAddr,
      FRMPayload = appObj.MACPayload.FRMPayload
    }
    -- p(appObj)
    logger.info("server module _> app module, send app message")
    return appServer.Process("ServerPubToApp", message)
  end

  -- local function storeRXInfoToMysql(rxInfoArr)
  --   -- 存储rxinfo信息
  --   -- return BluebirdPromise.map(rxInfoArr, function (item) {
  --   --   return _this.DeviceStatus.createItem(item);
  --   -- });
  --   return DeviceStatus.createItem(item) -- 设备状态存储
  -- end

  local function uploadToCS(rxInfoArr, appObj) -- 推送至control模块处理
    local macCmdArr = buffer:new(0)

    local fport = appObj.MACPayload.FPort:readUInt8(1)
    local fOptsLen = appObj.MACPayload.FHDR.FCtrl.FOptsLen
    if fport == 0 and appObj.MACPayload.FRMPayload then
      macCmdArr = appObj.MACPayload.FRMPayload
    elseif fOptsLen > 0 and appObj.MACPayload.FHDR.FOpts then
      macCmdArr = appObj.MACPayload.FHDR.FOpts
    end

    local adr = appObj.MACPayload.FHDR.FCtrl.ADR
    local pubControllerModel
    if #macCmdArr > 0 then
      pubControllerModel = PubControllerModel:new(rxInfoArr, adr, macCmdArr)
    elseif adr == 1 then
      pubControllerModel = PubControllerModel:new(rxInfoArr, adr)
    else
      logger.error("   Business data does not require mac command processing")
      return nil
    end

    -- 推送至control模块处理
    -- local topic = pubToCSTopic
    local message = {
      DevAddr = pubControllerModel:getDevAddr(),
      data = pubControllerModel:getCMDdata(),
      adr = pubControllerModel:getadr(),
      devtx = pubControllerModel:getdevtx(),
      gwrx = pubControllerModel:getgwrx()
    }

    logger.info("server module _> controller module, send mac cmd message")
    return controllerHandle.Process(message) -- _this.mqClient.publish(topic, message);
  end
  -- end

  -- main
  local res = updateDeviceRouting(optimalRXInfo)
  if res == nil then
    return nil
  end
  res = DeviceInfoRedis.UpdateItem({DevAddr = uploadDataDevAddr}, {FCntUp = newFCnt})
  if res == nil then
    return nil
  end
  -- DeviceInfoMysql.increaseFcntup(uploadDataDevAddr, newFCnt)
  -- TODO:需要对业务数据及mac数据进行分类处理

  if appObj.MACPayload.FPort:readUInt8(1) ~= 0 and appObj.MACPayload.FRMPayload ~= nil then
    res = uploadToAS(appObj) -- 应用数据上传
  end
  res = uploadToCS(rxInfoArr, appObj) -- mac命令传至control模块

  return {rxInfoArr = rxInfoArr, appObj = appObj}
end

return {
  handle = handle
}
