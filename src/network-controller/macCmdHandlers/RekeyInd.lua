-- const BluebirdPromise = require('bluebird');
-- const { consts, utils } = require('../lora-lib');
-- const REKEYIND_PARAM = consts.REKEYIND;
-- const MacCommandIssuers = require('../macCmdIssuers');

return function(devAddr, status)
  -- let _this = this;
  -- return new BluebirdPromise((resolve, reject) => {
  p(
    {
      label = "MAC Command Ans",
      message = {
        RekeyInd = {
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
  local minor = utils.bitwiseFilter(Status, REKEYIND_PARAM.MINOR_START, REKEYIND_PARAM.MINOR_LEN)
  if minor == 1 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          RekeyInd = {
            Minor = "Minor=1 set Success"
          }
        }
      }
    )
  end

  local MacCommandIssuer = MacCommandIssuers[consts.REKEY_CID].bind(_this, devAddr, minor)
  return MacCommandIssuer()
end
