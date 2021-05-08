-- local mqHandle = require("../src/common/message_queue.lua")
local joinServer = require("../join-server/join.lua")
local consts = require("../lora-lib/constants/constants.lua")
local MySQLDeviceConfig = require("../lora-lib/models/MySQLModels/DeviceConfig.lua")
local MySQLDeviceInfo = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local MySQLDeviceRouting = require("../lora-lib/models/MySQLModels/DeviceRouting.lua")
local RedisDeviceInfo = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles/utiles.lua")

local function getIndexByVal(table, val)
  for i, v in pairs(table) do
    if v == val then
      return i
    end
  end
  p("no find index")
  return 1 -- 没有找到则返回索引1
end

-- 更新join请求设备路由信息
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

  local whereOpts = {DevAddr = deviceStatus.DevAddr}

  local res = MySQLDeviceConfig.readItem(whereOpts) -- mysql DeviceConfig
  if res then
    if res.frequencyPlan == nil then
      p("DevAddr does not exist frequencyPlan in MySQL DeviceConfig")
      return -2
    end
    if res.RX1DRoffset == nil and res.RX1DRoffset ~= 0 then
      p("DevAddr does not exist RX1DRoffset in MySQL DeviceConfig")
      return -3
    end

    freqPlanOffset = getIndexByVal(consts.FREQUENCY_PLAN_LIST, res.frequencyPlan)

    local updateOpts = {
      DevAddr = deviceStatus.DevAddr,
      gatewayId = deviceStatus.gatewayId,
      tmst = deviceStatus.tmst + consts.TXPK_CONFIG.TMST_OFFSET_JOIN,
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
      codr = deviceStatus.codr,
      imme = false,
      ipol = false
    }
    -- updateOpts.freq = 501.5 -- test TODO:
    -- updateOpts.datr = "SF7BW125" -- test TODO:
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
      devInfo.RX1Delay = 0
    end

    local query = {
      DevAddr = updateOpts.DevAddr
    }

    local res = MySQLDeviceRouting.UpdateItem(query, updateOpts)
    if res < 0 then
      return -2
    end
    res = MySQLDeviceInfo.readItem(query, consts.DEVICEINFO_CACHE_ATTRIBUTES)
    p("function <MySQLDeviceInfo.readItem>:", res)
    for k, v in pairs(res) do
      devInfo[k] = v
    end
    res = MySQLDeviceRouting.readItem(query, consts.DEVICEROUTING_CACHE_ATTRIBUTES)
    for k, v in pairs(res) do
      devInfo[k] = v
    end
    res = RedisDeviceInfo.UpdateItem({DevAddr = updateOpts.DevAddr}, devInfo)
    p("function <RedisDeviceInfo.UpdateItem>:", res)
    return res
  end
  p("DevAddr does not exist in DeviceConfig")
  return -3
end

-- join 下行数据处理
function handler(convertedData)
  -- return BluebirdPromise.all([
  --   _this.DeviceStatus.createItem(convertedData),
  --   _this.updateJoinDeviceRouting(convertedData),
  -- ]);
  return updateJoinDeviceRouting(convertedData) -- 网关与服务器之间的数据
end

-- join request 上行数据处理
function joinRequestHandle(joinResArr)
  return joinServer.handleMessage(joinResArr) -- 把joinRequest数据推送至join-server模块
end

return {
  joinRequestHandle = joinRequestHandle,
  handler = handler
}
