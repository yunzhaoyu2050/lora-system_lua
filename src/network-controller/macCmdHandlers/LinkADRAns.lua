local utils = require("../../../utiles/utiles.lua")
local consts = require("../../lora-lib/constants/constants.lua")
local LINKADRANS_PARAM = consts.LINKADRANS
local logger = require("../../log.lua")

return function(devAddr, status)
  logger.info(
    {
      label = "MAC Command Ans",
      message = {
        LinkADRAns = {
          Status = status
        }
      }
    }
  )

  for key, _ in pairs(status) do
    local Status = utils.BufferFrom(status[key])
    local ChannelMaskACK =
      utils.bitwiseFilter(Status, LINKADRANS_PARAM.CHANNELMASKACK_START, LINKADRANS_PARAM.CHANNELMASKACK_LEN)
    local DataRateACK =
      utils.bitwiseFilter(Status, LINKADRANS_PARAM.DATARATEACK_START, LINKADRANS_PARAM.DATARATEACK_LEN)
    local PowerACK = utils.bitwiseFilter(Status, LINKADRANS_PARAM.POWERACK_START, LINKADRANS_PARAM.POWERACK_LEN)

    if ChannelMaskACK == 1 then
      logger.info(
        {
          label = "MAC Command Ans",
          message = {
            LinkADRAns = {
              ChannelMaskACK = "Channel Mask set Success"
            }
          }
        }
      )
    end

    if DataRateACK == 1 then
      logger.info(
        {
          label = "MAC Command Ans",
          message = {
            LinkADRAns = {
              DataRateACK = "Data Rate set Success"
            }
          }
        }
      )
    end

    if PowerACK == 1 then
      logger.info(
        {
          label = "MAC Command Ans",
          message = {
            LinkADRAns = {
              PowerACK = "Power set Success"
            }
          }
        }
      )
    end
  end
end
