-- const BluebirdPromise = require('bluebird');
-- const { utils, consts } = require('../lora-lib');
local consts = require("../../lora-lib/constants/constants.lua")
local DEVSTATUSANS_PARAM = consts.DEVSTATUSANS

return function(devAddr, status)
  p(
    {
      label = "MAC Command Ans",
      message = {
        DevStatusAns = {
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
  local battery = Buffer.from(status[key_in[0]])
  local margin = Buffer.from(status[key_in[1]])
  local Battery = utils.bitwiseFilter(battery, 0, 7) -- change buffer to num
  local Margin = utils.bitwiseFilter(margin, 0, 5) -- change buffer to num

  if Battery == 0 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          DevStatusAns = {
            Battery = "Device had connect to extra battery",
            Margin = "Margin is " + Margin
          }
        }
      }
    )
  end

  if Battery == 255 then
    p(
      {
        label = "MAC Command Ans",
        message = {
          DevStatusAns = {
            Battery = "Device can not measure the battery",
            Margin = "Margin is " + Margin
          }
        }
      }
    )
  end
end
