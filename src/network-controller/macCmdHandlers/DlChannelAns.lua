-- const BluebirdPromise = require('bluebird');
-- const { utils, consts } = require('../lora-lib');
local consts = require("../../lora-lib/constants/constants.lua")
local DLCHANNELANS_PARAM = consts.DLCHANNELANS

return function(devAddr, status)
  p(
    {
      label = "MAC Command Ans",
      message = {
        DlChannelAns = {
          Status = status
        }
      }
    }
  )

  local key_in = new
  Array()
  for key, _ in pairs(status) do
    key_in.push(key)
  end
  local Status = Buffer.from(status[key_in[0]])
  local channelFrequency =
    utils.bitwiseFilter(Status, DLCHANNELANS_PARAM.CHANNELFREQUENCY_START, DLCHANNELANS_PARAM.CHANNELFREQUENCY_LEN)
  local uplinkFrequency =
    utils.bitwiseFilter(Status, DLCHANNELANS_PARAM.UPLINKFREQUENCY_START, DLCHANNELANS_PARAM.UPLINKFREQUENCY_LEN)

  if channelFrequency == 1 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          DlChannelAns = {
            ChannelFrequency = "Device can use the setted frequency"
          }
        }
      }
    )
  end

  if uplinkFrequency == 1 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          DlChannelAns = {
            uplinkFrequency = "The channel uplink frequency is legal"
          }
        }
      }
    )
  end
end
