local constants = require("../../lora-lib/constants/constants.lua")
local LinkADRReqIssuer = require("../macCmdIssuers/macCmdIssuers.lua")[constants.LINKADR_CID]
local mysqlConnDeviceConfig = require("../../lora-lib/models/MySQLModels/DeviceInfo.lua")
local logger = require("../../log.lua")

function adrHandler(devAddr, devtx)
  -- local DeviceStatus = mysqlConnDeviceStatus;
  local DeviceConfig = mysqlConnDeviceConfig

  local freqPlan
  local freqPlanOffset
  local datr = devtx.datr -- get device tx data
  local sf = string.sub(devtx.datr, string.len("SF") + 1, string.find(devtx.datr, "BW", 1) - 1)
  local bandwith = string.sub(devtx.datr, string.find(devtx.datr, "BW", 1), -1)
   -- e.g. 'BW125'

  local res = DeviceConfig.readItem({DevAddr = devAddr}, {"frequencyPlan"})
  if res ~= nil then
    freqPlan = res.frequencyPlan
    freqPlanOffset = constants.GetISMFreqPLanOffset(freqPlan)

    -- res = DeviceStatus.orderItem(
    --   { DevAddr= devAddr },
    --   {'lsnr'},
    --   {'id', 'DESC'},
    --   constants.ADR_CONTROLSCHEME_PARAM.LATEST_SNR_NO);

    local linkAdrParam = __baseAdr(freqPlan, sf, res)

    local DataRate = constants.LINKADRREQ.DATARATE_DEFAULT
    local TXPower = constants.LINKADRREQ.TXPOWER_DEFAULT

    if linkAdrParam.DataRate ~= nil then
      local drStr = "SF" + linkAdrParam.DataRate + bandwith
      local drVal = constants.DR_PARAM.DRUP[freqPlanOffset][drStr]
      DataRate = string.sub(drVal, string.len("DR") + 1, -1)
    end

    if linkAdrParam.TXPower ~= nil then
      TXPower = linkAdrParam.TXPower
    end

    if linkAdrParam.DataRate == nil and linkAdrParam.TXPower == nil then
      logger.error("adr device remains unchanged.")
      return nil
    end

    -- remain unchanged
    local chmask = constants.ADR_CONTROLSCHEME_PARAM.CHMASK_DEFAULT
    local ChMaskCntl = constants.ADR_CONTROLSCHEME_PARAM.CHMASKCNTL_DEFAULT[freqPlanOffset]
    local NbTrans = constants.ADR_CONTROLSCHEME_PARAM.NBTRANS_DEFAULT

    local arguArr = {devAddr, DataRate, TXPower, chmask, ChMaskCntl, NbTrans}
    return LinkADRReqIssuer(arguArr)
  else
    logger.error("")
  end
end

-- Base ADR Algorithm
function __baseAdr(freqPlan, sf, snrArr)
  local minSF = constants.SPREADFACTOR_MIN
  local minTP = constants.TXPOWER_MIN
  local maxTP = constants.TXPOWER_MAX_LIST[freqPlan]

  local tp = maxTP

  function getSum(pre, cur)
    return pre + cur.lsnr
  end

  local snrAvg = snrArr.reduce(getSum, 0) / snrArr.length

  local snrReq = constants.SF_REQUIREDSNR[sf]
  local deviceMargin = constants.ADR_CONTROLSCHEME_PARAM.DEVICEMARGIN
  local snrMargin = snrAvg - snrReq - deviceMargin

  local steps = math.floor(snrMargin / constants.ADR_CONTROLSCHEME_PARAM.STEPS_DIVISOR)

  local DataRateKeep = true
  local TXPowerKeep = true

  while (steps > 0 and sf > minSF) do
    sf = sf - constants.ADR_CONTROLSCHEME_PARAM.SF_STEP
    DataRateKeep = false
    steps = steps - 1
  end

  -- // devices using 1.1 dont have certain 'tp'
  -- // devices using 1.0.2 cannot modify 'tp' it self, only be modified by server
  -- // but we dont keep the 'tp' item in 'DeviceConfig' table
  -- /*
  -- while (steps > 0 && tp > minTP) {
  --   tp -= constants.ADR_CONTROLSCHEME_PARAM.TXPOWER_STEP;
  --   TXPowerKeep = false;
  --   steps --;
  -- }

  -- if (steps < 0 && tp < maxTP) {
  --   tp = maxTP;
  --   TXPowerKeep = false;
  -- }
  -- */

  local res = {}
  if DataRateKeep == nil then
    res.DataRate = sf
  end

  if TXPowerKeep == nil then
    res.TXPower = tp
  end

  return res
end

return {
  adrHandler = adrHandler
}
