-- const BluebirdPromise = require('bluebird');
-- const { utils, consts } = require('../lora-lib');
-- const NEWCHANNLANS_PARAM = consts.NEWCHANNELANS;

return function(devAddr, status)
  -- let _this = this;
  -- return new BluebirdPromise((resolve, reject) => {
  p(
    {
      label = "MAC Command Ans",
      message = {
        NewChannelAns = {
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
    utils.bitwiseFilter(Status, NEWCHANNLANS_PARAM.CHANNELFREQUENCY_START, NEWCHANNLANS_PARAM.CHANNEKFREQUENCY_LEN)
  local dataRateRange =
    utils.bitwiseFilter(Status, NEWCHANNLANS_PARAM.DATARATERANGE_START, NEWCHANNLANS_PARAM.DATARATERANGE_LEN)

  if channelFrequency == 1 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          NewChannelAns = {
            ChannelFrequency = "Device can use the setted frequency"
          }
        }
      }
    )
  end

  if dataRateRange == 1 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          NewChannelAns = {
            DataRateRange = "The data rate range is consistent with the device"
          }
        }
      }
    )
  end

  if channelFrequency == 0 or dataRateRange == 0 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          NewChannelAns = "NewChannelReq not carry out "
        }
      }
    )
  end
end
