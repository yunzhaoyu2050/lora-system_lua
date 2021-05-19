local utils = require("../../../utiles/utiles.lua")
local constants = require("../../lora-lib/constants/constants.lua")
local LINKADRREQ_PARAM = constants.LINKADRREQ
local DownlinkCmdQueue = require("../../lora-lib/models/RedisModels/DownlinkCmdQueue.lua")
local logger = require("../../log.lua")

return function(devAddr, dr, tx, chmask, ChMaskCntl, NbTrans)
  local ChMask = chmask.toString(16)
  if (ChMask.length ~= ((LINKADRREQ_PARAM.CHMASK_LEN) * 2)) then
    logger.error("length of ChMask in LinkADRReq should be ${LINKADRREQ_PARAM.CHMASK_LEN}")
    return nil
  end

  local datarateTxpower = dr * LINKADRREQ_PARAM.DATARATE_BASE + tx * LINKADRREQ_PARAM.TXPOWER_BASE
  local redundancy = ChMaskCntl * LINKADRREQ_PARAM.CHMASKCNTL_BASE + NbTrans * LINKADRREQ_PARAM.NBTRANS_BASE
  local outputObj = {
    [tostring(constants.LINKADR_CID)] = {
      TXPower = utils.numToBuf(datarateTxpower, LINKADRREQ_PARAM.DATARATE_TXPOWER_LEN),
      ChMask = utils.numToBuf(chmask, LINKADRREQ_PARAM.CHMASK_LEN),
      Redundancy = utils.numToBuf(redundancy, LINKADRREQ_PARAM.REDUNDANCY_LEN)
    }
  }

  -- push cmd req into queue
  local mqKey = constants.MACCMDQUEREQ_PREFIX + devAddr
  DownlinkCmdQueue.produce(mqKey, outputObj)

  logger.info(
    {
      label = "MAC Command Req",
      message = {
        LinkADRReq = mqKey,
        payload = outputObj
      }
    }
  )
  return outputObj
end
