local dataHandler = require("./dataHandler.lua")
function _process(recvData)
  if recvData ~= nil then
    return dataHandler.process(recvData)
  end
end
return {
  Process = _process
}
