local nsMsgHandler = require("./nsMsgHandler.lua")
local logger = require("../log.lua")
function _process(messageTopic, message)
  if (messageTopic == "CloudPubToApp") then
  elseif (messageTopic == "ServerPubToApp") then
    return nsMsgHandler.handler(message)
  elseif (messageTopic == "HttpPubToApp") then
    -- protoBufUnit.loadAllData()
  else
    logger.error("Error topic ${message.topic}, Message ${message.value}", messageTopic, message)
  end
end
return {
  Process = _process
}
