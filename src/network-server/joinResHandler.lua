-- local mqHandle = require("../src/common/message_queue.lua")
local joinServer = require("../join-server/join.lua")
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
  joinServer.handleMessage(joinResArr) -- 把joinRequest数据推送至join-server模块
  return ret
end

function updateJoinDeviceRouting(deviceStatus)
  local freqPlanOffset
  function getDatr(datr, RX1DROFFSET)
    local dr = consts.DR_PARAM
    local RX1DROFFSETTABLE = dr.RX1DROFFSETTABLE[freqPlanOffset]
    local DRUP = dr.DRUP[freqPlanOffset]
    local DRDOWN = dr.DRDOWN[freqPlanOffset]
    for key, v in pairs(DRDOWN) do
      if RX1DROFFSETTABLE[DRUP[datr]][RX1DROFFSET] == DRDOWN[key] then
        return key
      end
    end
    return datr
  end

  local whereOpts = {DevAddr = deviceStatus.DevAddr}
  -- // return _this.deviceConfig.read(whereOpts.DevAddr).then(function (res) {
  local res = DeviceConfig.readItem(whereOpts)
  if res then
    if res.frequencyPlan == nil then
      p("DevAddr does not exist frequencyPlan in DeviceConfig")
      return -2
    end

    if res.RX1DRoffset == nil and res.RX1DRoffset ~= 0 then
      p("DevAddr does not exist RX1DRoffset in DeviceConfig")
      return -3
    end

    -- freqPlanOffset = consts.FREQUENCY_PLAN_LIST.findIndex(function (value, index, array) { -- ??
    --   return value === res.frequencyPlan;
    -- });

    local updateOpts = {
      DevAddr = buffer:new(deviceStatus.DevAddr, "hex"),
      gatewayId = buffer:new(deviceStatus.gatewayId, "hex"),
      tmst = deviceStatus.tmst + consts.TXPK_CONFIG.TMST_OFFSET_JOIN,
      -- freq= consts.TXPK_CONFIG.FREQ[freqPlanOffset]
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
    local res = DeviceRouting.UpdateItem(updateOpts)
    if res < 0 then
      return -2
    end
    res = DeviceInfoMysql.readItem(query, consts.DEVICEINFO_CACHE_ATTRIBUTES)

    for k, v in pairs(res) do
      devInfo[k] = v
    end
    res = DeviceRouting.readItem(query, consts.DEVICEROUTING_CACHE_ATTRIBUTES)
    for k, v in pairs(res) do
      devInfo[k] = v
    end
    -- // console.log(devInfo);
    return _DeviceInfoRedis.update(updateOpts.DevAddr, devInfo)

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
