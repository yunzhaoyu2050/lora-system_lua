local utiles = require("../../utiles/utiles.lua")

-- mac命令打包
function packager(macCmdArray)
  local macCommand = Buffer:new(0)
  -- macCmdArray.forEach((macCmdJSON) => {
  for _, macCmdJSON in pairs(macCmdArray) do
    for key, _ in pairs(macCmdJSON) do
      local cid = Buffer.from(key, "hex")
      local payloadJSON = macCmdJSON[key]

      utiles.switch(cid.readInt8()) {
        [consts.RESET_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.Version
            }
          )
        end,
        [consts.LINKCHECK_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.Margin,
              payloadJSON.GwCnt
            }
          )
        end,
        [consts.LINKADR_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.TXPower,
              payloadJSON.ChMask,
              payloadJSON.Redundancy
            }
          )
        end,
        [consts.DUTYCYCLE_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.DutyCyclePL
            }
          )
        end,
        [consts.RXPARAMSETUP_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.DLSettings,
              payloadJSON.Frequency
            }
          )
        end,
        [consts.DEVSTATUS_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid
            }
          )
        end,
        [consts.NEWCHANNEL_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.ChIndex,
              payloadJSON.Freq,
              payloadJSON.DrRange
            }
          )
        end,
        [consts.RXTIMINGSETUP_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.Settings
            }
          )
        end,
        [consts.TXPARAMSETUP_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.DwellTime
            }
          )
        end,
        [consts.DLCHANNEL_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.ChIndex,
              payloadJSON.Freq
            }
          )
        end,
        [consts.REKEY_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.Version
            }
          )
        end,
        [consts.ADRPARAMSETUP_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.ADRParam
            }
          )
        end,
        [consts.DEVICETIME_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.Seconds,
              payloadJSON.FractionalSec
            }
          )
        end,
        [consts.FORCEREJOIN_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.ForceRejoinReq
            }
          )
        end,
        [consts.REJOINPARAMSETUP_CID] = function()
          macCommand =
            Buffer.concat(
            {
              macCommand,
              cid,
              payloadJSON.RejoinParamSetupReq
            }
          )
        end,
        [default] = function()
          p("Bad cid of MACCommand", cid)
        end
      }
    end
  end
  return macCommand
end

return {
  packager = packager
}
