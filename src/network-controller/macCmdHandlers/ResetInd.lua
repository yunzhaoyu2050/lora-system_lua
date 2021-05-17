-- const BluebirdPromise = require('bluebird');
-- const { consts, utils } = require('../lora-lib');
-- const RESTIND_PARAM = consts.RESETIND;
-- const MacCommandIssuers = require('../macCmdIssuers');

return function(devAddr, status)
  -- let _this = this;
  -- return new BluebirdPromise((resolve, reject) => {
  p(
    {
      label = "MAC Command Ans",
      message = {
        ResetInd = {
          Status = status
        }
      }
    }
  )

  for key, _ in pairs(status) do
    local version = status[key]
    local Status = Buffer.from(version)
    local Minor = utils.bitwiseFilter(Status, RESTIND_PARAM.MINOR_START, RESTIND_PARAM.MINOR_LEN)

    if Minor == 1 then
      p(
        {
          label = "MAC Command Ans",
          message = {
            ResetInd = {
              Minor = "Minor=1 set Success"
            }
          }
        }
      )
    end

    local MacCommandIssuer = MacCommandIssuers[consts.RESET_CID].bind(_this, devAddr, Minor)
    return MacCommandIssuer()
  end
end
