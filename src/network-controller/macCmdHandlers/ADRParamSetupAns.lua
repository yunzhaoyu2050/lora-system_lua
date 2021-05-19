local logger = require("../../log.lua")

return function(devAddr, status)
  logger.info(
    {
      label = "MAC Command Ans",
      message = {
        ADRParamSetupAns = {
          Status = "The payload is null"
        }
      }
    }
  )
end
