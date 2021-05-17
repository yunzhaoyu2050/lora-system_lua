-- const BluebirdPromise = require('bluebird');
-- const { consts, utils } = require('../lora-lib');
local consts = require("../../lora-lib/constants/constants.lua")
local LINKADRANS_PARAM = consts.LINKADRANS

return function(devAddr, status)
  p(
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
    local Status = Buffer.from(status[key], "hex")
    local ChannelMaskACK =
      utils.bitwiseFilter(Status, LINKADRANS_PARAM.CHANNELMASKACK_START, LINKADRANS_PARAM.CHANNELMASKACK_LEN)
    local DataRateACK =
      utils.bitwiseFilter(Status, LINKADRANS_PARAM.DATARATEACK_START, LINKADRANS_PARAM.DATARATEACK_LEN)
    local PowerACK = utils.bitwiseFilter(Status, LINKADRANS_PARAM.POWERACK_START, LINKADRANS_PARAM.POWERACK_LEN)

    if ChannelMaskACK == 1 then
      p(
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
      p(
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
      p(
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
