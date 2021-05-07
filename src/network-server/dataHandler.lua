-- network-server 数据处理部分
local DataConverter = require("./dataConverter.lua")
local utiles = require("../../utiles/utiles.lua")

function process(data)
  if data == nil then
    p("data is nil")
    return nil
  end
  p("Data handler started...")
  if data.type == nil or type(data.type) ~= "string" then
    p("data.type is nil", data)
    return nil
  end
  if data.data == nil then
    p("data.data is nil", data)
    return nil
  end
  local ret = nil
  local retIndex = data.type
  local retData = data.data
  while true do
    retIndex, retData =
      utiles.switch(retIndex) {
      ["ConnectorPubToServer"] = function()
        return DataConverter.uplinkDataHandler(retData) -- Network Connector --> Network Server
      end,
      ["ControllerPubToServer"] = function()
        -- Control Server --> Network Server
      end,
      ["JoinPubToServer"] = function()
        return DataConverter.joinAcceptHandler(retData) -- Join Server --> Network Server
      end,
      ["AppPubToServer"] = function()
        -- Application Server ---> Network Server
      end,
      [utiles.Default] = function()
        p("data.type is error", retData)
      end
    }
    p("retIndex, retData:", retIndex, retData)
    if retData == nil or retIndex == "other" then
      break
    end
  end
  ret = retData
  return ret
end
return {
  process = process
}
