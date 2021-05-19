local logger = require("../../log.lua")

return function(devAddr, status, gwrx)
  logger.info(
    {
      label = "MAC Command Ans",
      message = {
        DeviceTimeReq = {
          Status = status
        }
      }
    }
  )

  local time = Date.now() / 1000
  local seconds = parseInt(time)
  local fractional_time = time - parseInt(time)
  local fractionalsec = parseInt(fractional_time * 256)
  local MacCommandIssuer = MacCommandIssuers[consts.DEVICETIME_CID].bind(_this, devAddr, seconds, fractionalsec)
  return MacCommandIssuer()
end
