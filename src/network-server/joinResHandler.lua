local joinServer = require("../join-server/join.lua")
local consts = require("../lora-lib/constants/constants.lua")
local MySQLDeviceConfig = require("../lora-lib/models/MySQLModels/DeviceConfig.lua")
local MySQLDeviceInfo = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local MySQLDeviceRouting = require("../lora-lib/models/MySQLModels/DeviceRouting.lua")
local RedisDeviceInfo = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local config = require("../../server_cfg.lua")

-- join请求流程 - 下行处理 - 更新设备路由信息
local function updateJoinDeviceRouting(deviceStatus)
  -- "time":"2013-03-31T16:21:17.528002Z",
  -- "tmst":3512348611,
  -- "chan":2,
  -- "rfch":0,
  -- "freq":866.349812,
  -- "stat":1,
  -- "modu":"LORA",
  -- "datr":"SF7BW125",
  -- "codr":"4/6",
  -- "rssi":-35,
  -- "lsnr":5.1,
  -- "size":32,

  local freqPlanOffset
  local whereOpts = {DevAddr = deviceStatus.DevAddr}

  local res = MySQLDeviceConfig.readItem(whereOpts) -- mysql DeviceConfig
  if res then
    if res.frequencyPlan == nil then
      p("DevAddr does not exist frequencyPlan in MySQL DeviceConfig")
      return nil
    end

    if res.RX1DRoffset == nil and res.RX1DRoffset ~= 0 then
      p("DevAddr does not exist RX1DRoffset in MySQL DeviceConfig")
      return nil
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

    freqPlanOffset = consts.GetISMFreqPLanOffset(deviceStatus.freq)
    if freqPlanOffset == "" then
      return nil
    end

    local updateOpts = {
      DevAddr = deviceStatus.DevAddr,
      gatewayId = deviceStatus.gatewayId,
      tmst = deviceStatus.tmst + consts.TXPK_CONFIG.TMST_OFFSET_JOIN,
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
    updateOpts.brd = 0
    updateOpts.ant = 0

    if NcrcVal ~= nil then
      updateOpts.NcrcVal = NcrcVal
    end

    local devInfo = {
      frequencyPlan = res.frequencyPlan,
      ADR = res.ADR,
      RX1DRoffset = res.RX1DRoffset,
      RX1Delay = res.RX1Delay
    }
    if res.ADR == nil then
      devInfo.ADR = false
    end

    if res.RX1Delay == nil then
      devInfo.RX1Delay = consts.DEFAULT_RX1DELAY -- 1s
    end

    local query = {
      DevAddr = updateOpts.DevAddr
    }

    p("   update mysql device routing info:", updateOpts)
    local res = MySQLDeviceRouting.UpdateItem(query, updateOpts)
    if res < 0 then
      return nil
    end

    res = MySQLDeviceInfo.readItem(query, consts.DEVICEINFO_CACHE_ATTRIBUTES)
    for k, v in pairs(res) do
      devInfo[k] = v
    end

    res = MySQLDeviceRouting.readItem(query, consts.DEVICEROUTING_CACHE_ATTRIBUTES)
    for k, v in pairs(res) do
      devInfo[k] = v
    end

    res = RedisDeviceInfo.UpdateItem({DevAddr = updateOpts.DevAddr}, devInfo)
    -- p("function <RedisDeviceInfo.UpdateItem>:", res)
    return res
  end
  p("DevAddr does not exist in DeviceConfig")
  return nil
end

-- join请求流程 - 下行数据处理
function handler(convertedData)
  -- return
  --   _this.DeviceStatus.createItem(convertedData),
  --   _this.updateJoinDeviceRouting(convertedData),
  return updateJoinDeviceRouting(convertedData) -- 网关与服务器之间的数据
end

-- join request 上行数据处理
function joinRequestHandle(joinResArr)
  p("server module _> join module, send join request message")
  return joinServer.handleMessage(joinResArr) -- 把joinRequest数据推送至join-server模块
end

return {
  joinRequestHandle = joinRequestHandle,
  handler = handler
}
