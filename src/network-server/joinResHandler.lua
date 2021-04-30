-- local mqHandle = require("../src/common/message_queue.lua")
local joinServer = require("../join-server/join.lua")
local consts = require("../lora-lib/constants/constants.lua")
local MySQLDeviceConfig = require("../lora-lib/models/MySQLModels/DeviceConfig.lua")
local MySQLDeviceInfo = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local MySQLDeviceRouting = require("../lora-lib/models/MySQLModels/DeviceRouting.lua")
local RedisDeviceInfo = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles/utiles.lua")

-- join下行数据处理
function handler(convertedData)
  -- // return BluebirdPromise.all([
  -- //   _this.DeviceStatus.createItem(convertedData),
  -- //   _this.updateJoinDeviceRouting(convertedData),
  -- // ]);
  return updateJoinDeviceRouting(convertedData)
end

-- join request 处理句柄
function joinRequestHandle(joinResArr)
  p("Send join message to JS-sub")
  local ret = joinServer.handleMessage(joinResArr) -- 把joinRequest数据推送至join-server模块
  return ret
end

function getIndexByVal(table, val)
  for i, v in pairs(table) do
    if v == val then
      return i
    end
  end
  p("no find index")
  return 0
end

-- 更新join请求设备路由信息
function updateJoinDeviceRouting(deviceStatus)
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

  local res = MySQLDeviceConfig.readItem(whereOpts) -- mysql
  if res then
    if res.frequencyPlan == nil then
      p("DevAddr does not exist frequencyPlan in DeviceConfig")
      return -2
    end

    if res.RX1DRoffset == nil and res.RX1DRoffset ~= 0 then
      p("DevAddr does not exist RX1DRoffset in DeviceConfig")
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
      --   (freqPlanOffset === consts.PLANOFFSET915 ? deviceStatus.chan : deviceStatus.freq),
      powe = consts.TXPK_CONFIG.POWE[freqPlanOffset],
      datr = getDatr(deviceStatus.datr, res.RX1DRoffset),
      modu = deviceStatus.modu,
      codr = deviceStatus.codr
    }

    local devInfo = {
      frequencyPlan = res.frequencyPlan,
      ADR = res.ADR,
      RX1DRoffset = res.RX1DRoffset,
      RX1Delay = res.RX1Delay
    }

    local query = {
      DevAddr = updateOpts.DevAddr
    }

    -- // updateOpts.DevAddr = Buffer.from(deviceStatus.DevAddr, 'hex');
    local res = MySQLDeviceRouting.UpdateItem(query, updateOpts)
    if res < 0 then
      return -2
    end
    res = MySQLDeviceInfo.readItem(query, consts.DEVICEINFO_CACHE_ATTRIBUTES)
    for k, v in pairs(res) do
      devInfo[k] = v
    end
    res = MySQLDeviceRouting.readItem(query, consts.DEVICEROUTING_CACHE_ATTRIBUTES)
    for k, v in pairs(res) do
      devInfo[k] = v
    end
    -- // console.log(devInfo);
    return RedisDeviceInfo.UpdateItem({DevAddr = updateOpts.DevAddr}, devInfo)

  -- // .then(() => {
  -- //   return _this.DeviceInfoRedis.read(updateOpts.DevAddr)
  -- //     .then((res) => {
  -- //       console.log('from redis');
  -- //       console.log(res);
  -- //     });
  -- // });
  end
  p("DevAddr does not exist in DeviceConfig")
  return -3
end

return {
  joinRequestHandle = joinRequestHandle,
  handler = handler
}
