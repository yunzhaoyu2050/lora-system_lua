-- const BluebirdPromise = require('bluebird');
-- const { utils, consts } = require('../lora-lib');
-- const REJOINPARAMSETUPANS_PARAM = consts.REJOINPARAMSETUPANS;

return function(devAddr, status)
  -- let _this = this;
  -- return new BluebirdPromise((resolve, reject) => {
  p(
    {
      label = "MAC Command Ans",
      message = {
        RejoinParamSetupAns = {
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
  local TimeOK =
    utils.bitwiseFilter(Status, REJOINPARAMSETUPANS_PARAM.TIMEOK_START, REJOINPARAMSETUPANS_PARAM.TIMEOK_LEN)

  if TimeOK == 1 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          RejoinParamSetupAns = {
            TimeOK = "The device accepted the time and quantity limit"
          }
        }
      }
    )
  end
end
