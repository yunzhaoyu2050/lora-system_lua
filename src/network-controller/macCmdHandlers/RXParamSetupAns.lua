-- const BluebirdPromise = require('bluebird');
-- const { utils, consts } = require('../lora-lib');
-- const RXPARAMSETUPANS_PARAM = consts.RXPARAMSETUPANS;

return function(devAddr, status)
  -- let _this = this;
  -- return new BluebirdPromise((resolve, reject) => {
  p(
    {
      label = "MAC Command Ans",
      message = {
        RXParamSetupAns = {
          Status = status
        }
      }
    }
  )

  for key, _ in pairs(status) do
    local Status = Buffer.from(status[key])
    local RX1DRoffsetACK =
      utils.bitwiseFilter(Status, RXPARAMSETUPANS_PARAM.RX1DROFFSETACK_START, RXPARAMSETUPANS_PARAM.RX1DROFFSETACK_LEN)
    local RX2DataRateACK =
      utils.bitwiseFilter(Status, RXPARAMSETUPANS_PARAM.RX2DATARATEACK_START, RXPARAMSETUPANS_PARAM.RX2DATARATEACK_LEN)
    local ChannelACK =
      utils.bitwiseFilter(Status, RXPARAMSETUPANS_PARAM.CHANNELACK_START, RXPARAMSETUPANS_PARAM.CHANNELACK_LEN)

    if RX1DRoffsetACK == 1 then
      p(
        {
          label = "MAC Command Ans",
          message = {
            RXParamSetupAns = {
              RX1DRoffsetACK = "RX1DRoffset set Success"
            }
          }
        }
      )
    end

    if RX2DataRateACK == 1 then
      p(
        {
          label = "MAC Command Ans",
          message = {
            RXParamSetupAns = {
              RX2DataRateACK = "RX2DataRate set Success"
            }
          }
        }
      )
    end

    if ChannelACK == 1 then
      p(
        {
          label = "MAC Command Ans",
          message = {
            RXParamSetupAns = {
              ChannelACK = "Channel set Success"
            }
          }
        }
      )
    end
  end
end
