local Object = require("core").Object
local PubControllerModel = Object:extend()

function PubControllerModel:initialize(rxInfoArr, adr, macCmdArr)
  self.DevAddr = rxInfoArr.DevAddr
  if (macCmdArr) then
    self.data = macCmdArr
  end

  self.devtx = {
    freq = rxInfoArr.freq,
    datr = rxInfoArr.datr,
    codr = rxInfoArr.codr
  }
  self.adr = adr
  self.gwrx = {}

  local i = 1
  for _, v in pairs(rxInfoArr) do
    local oneGwrx = {}
    oneGwrx.gatewayId = v.gatewayId
    oneGwrx.time = v.time
    oneGwrx.tmms = v.tmms
    oneGwrx.tmst = v.tmst
    oneGwrx.chan = v.chan
    oneGwrx.rfch = v.rfch
    oneGwrx.stat = v.stat
    oneGwrx.modu = v.modu
    oneGwrx.rssi = v.rssi
    oneGwrx.lsnr = v.lsnr
    oneGwrx.size = v.size
    self.gwrx[i] = oneGwrx
    i = i + 1
  end
end

function PubControllerModel:getDevAddr()
  return self.DevAddr
end

function PubControllerModel:getCMDdata()
  if self.data ~= nil then
    return self.data
  else
    return nil
  end
end

function PubControllerModel:getadr()
  return self.adr
end

function PubControllerModel:getdevtx()
  return self.devtx
end

function PubControllerModel:getgwrx()
  return self.gwrx
end

return PubControllerModel
