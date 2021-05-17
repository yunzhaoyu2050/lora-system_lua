local Object = require("core").Object
local PubControllerModel = Object:extend()
local utiles = require("../../utiles/utiles.lua")

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

  -- rxInfoArr 当前只包含一个成员
  local i = 1
  local oneGwrx = {}
  for k, v in pairs(rxInfoArr) do
    utiles.switch(k) {
      ["gatewayId"] = function()
        oneGwrx.gatewayId = v
      end,
      ["time"] = function()
        oneGwrx.time = v
      end,
      ["tmms"] = function()
        oneGwrx.tmms = v
      end,
      ["tmst"] = function()
        oneGwrx.tmst = v
      end,
      ["chan"] = function()
        oneGwrx.chan = v
      end,
      ["rfch"] = function()
        oneGwrx.rfch = v
      end,
      ["stat"] = function()
        oneGwrx.stat = v
      end,
      ["modu"] = function()
        oneGwrx.modu = v
      end,
      ["rssi"] = function()
        oneGwrx.rssi = v
      end,
      ["lsnr"] = function()
        oneGwrx.lsnr = v
      end,
      ["size"] = function()
        oneGwrx.size = v
      end,
      [utiles.Default] = function()
        p("item is other, please check it.", k)
      end
    }
  end

  self.gwrx[i] = oneGwrx
  i = i + 1
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
