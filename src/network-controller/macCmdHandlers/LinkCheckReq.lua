local utils = require("../../../utiles/utiles.lua")
-- const BluebirdPromise = require('bluebird');
local constants = require("../../lora-lib/constants/constants.lua")
local buffer = require("buffer").Buffer
local DownlinkCmdQueue = require("../../lora-lib/models/RedisModels/DownlinkCmdQueue.lua")
return function(devAddr, devtx, gwrx)
  p(
    {
      label = "MAC Command Req",
      message = {
        LinkCheckReq = {
          devAddr = devAddr,
          devtx = devtx,
          gwrx = gwrx
        }
      }
    }
  )
  local sf = string.sub(devtx.datr, string.len("SF") + 1, string.find(devtx.datr, "BW", 1) - 1)
  local requireSNR = constants.SF_REQUIREDSNR[sf]
  local maxLSNR = constants.SF_REQUIREDSNR[sf]

  for k, element in pairs(gwrx) do
    if element.lsnr > maxLSNR then
      maxLSNR = element.lsnr
    end
  end

  if requireSNR == nil then
    p("sf ${devtx.datr} not in sf to required snr table")
    return nil
  end

  local Margin = maxLSNR - requireSNR
  if Margin < 0 then
    Margin = 0
  end

  local outputObj = {
    [tostring(constants.LINKCHECK_CID)] = {
      Margin = utils.numToBuf(math.ceil(Margin), constants.LINKCHECKANS.MARGIN_LEN),
      GwCnt = utils.numToBuf(#gwrx, constants.LINKCHECKANS.GWCNT_LEN)
    }
  }

  -- push cmd ans into queue
  local mqKey = constants.MACCMDQUEANS_PREFIX .. devAddr;
  DownlinkCmdQueue.produce(mqKey, outputObj)
  p(
    {
      label = "MAC Command Ans",
      message = {
        LinkCheckAns = mqKey,
        payload = outputObj
      }
    }
  )
end
