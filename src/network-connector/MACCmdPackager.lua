local utiles = require("../../utiles/utiles.lua")
local buffer = require("buffer").Buffer
local consts = require("../lora-lib/constants/constants.lua")
local logger = require("../log.lua")

-- mac命令打包
function packager(macCmdArray)
  local macCommand = buffer:new(0)
  for _, macCmdJSON in pairs(macCmdArray) do
    for key, _ in pairs(macCmdJSON) do
      local cid = buffer:new(consts.CID_LEN)
      cid[1] = tonumber(key)
      local payloadJSON = macCmdJSON[key]

      utiles.switch(cid:readInt8(1)) {
        [consts.RESET_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.Version
            }
          )
        end,
        [consts.LINKCHECK_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.Margin,
              payloadJSON.GwCnt
            }
          )
        end,
        [consts.LINKADR_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.TXPower,
              payloadJSON.ChMask,
              payloadJSON.Redundancy
            }
          )
        end,
        [consts.DUTYCYCLE_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.DutyCyclePL
            }
          )
        end,
        [consts.RXPARAMSETUP_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.DLSettings,
              payloadJSON.Frequency
            }
          )
        end,
        [consts.DEVSTATUS_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid
            }
          )
        end,
        [consts.NEWCHANNEL_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.ChIndex,
              payloadJSON.Freq,
              payloadJSON.DrRange
            }
          )
        end,
        [consts.RXTIMINGSETUP_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.Settings
            }
          )
        end,
        [consts.TXPARAMSETUP_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.DwellTime
            }
          )
        end,
        [consts.DLCHANNEL_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.ChIndex,
              payloadJSON.Freq
            }
          )
        end,
        [consts.REKEY_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.Version
            }
          )
        end,
        [consts.ADRPARAMSETUP_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.ADRParam
            }
          )
        end,
        [consts.DEVICETIME_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.Seconds,
              payloadJSON.FractionalSec
            }
          )
        end,
        [consts.FORCEREJOIN_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.ForceRejoinReq
            }
          )
        end,
        [consts.REJOINPARAMSETUP_CID] = function()
          macCommand =
            utiles.BufferConcat(
            {
              cid,
              payloadJSON.RejoinParamSetupReq
            }
          )
        end,
        [utiles.Default] = function()
          logger.error({"Bad cid of MACCommand, cid:", cid})
        end
      }
    end
  end
  logger.info({"macCommand:", utiles.BufferToHexString(macCommand)})
  return macCommand
end

return {
  packager = packager
}
