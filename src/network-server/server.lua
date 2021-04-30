local dataHandler = require("./dataHandler.lua")
function _process(recvData)
  if recvData ~= nil then
    p("network server recv:", recvData)
    dataHandler.process(recvData)
  else
    -- uv.sleep(math.random(1000))
  end
end
return {
  Process = _process
}
