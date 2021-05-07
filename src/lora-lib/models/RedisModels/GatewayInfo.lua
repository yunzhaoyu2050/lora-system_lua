-- @info 用于存储网关信息的缓存区
local consts = require("../../constants/constants.lua")
local MySQLModelsGatewayInfo = require("../MySQLModels/GatewayInfo.lua")

local GatewayInfo = {
  hashTable = {}
}

-- 5、GatewayInfo.lua,		key: gatewayId
--  "gatewayId",	新增
--  "pullPort",
--  "pushPort",
--  "version",
--  "address",
--  "userID"

local function SynchronousMysqlData()
  if GatewayInfo.hashTable == nil then
    p("redis gatewayInfo function <SynchronousMySqlData>, GatewayInfo.hashTable is nil")
    return -1
  end
  if MySQLModelsGatewayInfo.hashTable == nil then
    p("redis gatewayInfo function <SynchronousMySqlData>,  MySQLModelsGatewayInfo.hashTable is nil")
    return -1
  end
  for k, v in pairs(MySQLModelsGatewayInfo.hashTable) do
    GatewayInfo.hashTable[k] = {}
    for i, j in pairs(MySQLModelsGatewayInfo.hashTable[k]) do
      if i == "pullPort" then
        GatewayInfo.hashTable[k].pullPort = j
      elseif i == "pushPort" then
        GatewayInfo.hashTable[k].pushPort = j
      elseif i == "version" then
        GatewayInfo.hashTable[k].version = j
      elseif i == "address" then
        GatewayInfo.hashTable[k].address = j
      elseif i == "userID" then
        GatewayInfo.hashTable[k].userID = j
      end
    end
  end
  p("redis gatewayInfo function <SynchronousMySqlData>, synchronous mysql data end")
  return 0
end

function GatewayInfo.Init()
  GatewayInfo.hashTable = {}
  return SynchronousMysqlData() -- mysql中的对应值写入redis中
end

function GatewayInfo.Read(gatewayId)
  if gatewayId == nil then
    p("redis gatewayInfo function <GatewayInfo.Read>, gatewayId is nil")
    return -1
  end
  return GatewayInfo.hashTable[gatewayId]
end

function GatewayInfo.Write(gatewayId, info)
  if gatewayId == nil then
    p("redis gatewayInfo function <GatewayInfo.Write>, gatewayId is nil")
    return -1
  end
  if GatewayInfo.hashTable[gatewayId] == nil then
    GatewayInfo.hashTable[gatewayId] = {
      pullPort = info.pullPort,
      pushPort = info.pushPort,
      version = info.version,
      address = info.address,
      userID = info.userID
    }
    p("redis gatewayInfo function <GatewayInfo.Write>, inster a new device info, gatewayId:" .. gatewayId)
    return 0
  end
  p("redis gatewayInfo function <GatewayInfo.Write>, devaddr already exists, gatewayId:" .. gatewayId)
  return -2
end

function GatewayInfo.Update(gatewayId, info)
  if gatewayId == nil then
    p("redis gatewayInfo function <GatewayInfo.Update>, gatewayId is nil")
    return -1
  end
  if GatewayInfo.hashTable[gatewayId] ~= nil then
    -- GatewayInfo.hashTable[gatewayId]:update(info)
    p("redis gatewayInfo function <GatewayInfo.Update>, update device info, gatewayId:" .. gatewayId)
    return 0
  end
  p("redis gatewayInfo function <GatewayInfo.Update>, error :update device info is nil, gatewayId:" .. gatewayId)
  return -2
end

function GatewayInfo.Clear()
  GatewayInfo.hashTable = nil
end

-- @info 获取各个元素的方法

-- 读取userID
-- @param gatewayId
-- @return 成功：指定gatewayId的userID值, 失败：nil
function GatewayInfo.GetuserID(gatewayId)
  if GatewayInfo.hashTable[gatewayId] == nil then
    p("redis gatewayInfo function <GatewayInfo.GetuserID>, gatewayId does not exist, please register.")
    return nil
  end
  return GatewayInfo.hashTable[gatewayId].userID
end

-- 更新userID
-- @param gatewayId , data 要更新的数据
-- @return 入参错误：-1, 成功：0， 其他错误：<0
function GatewayInfo.UpdateuserID(gatewayId, data)
  if gatewayId == nil or data == nil then
    p("redis gatewayInfo function <GatewayInfo.UpdateuserID>, input param is nil")
    return -1
  end
  if GatewayInfo.hashTable[gatewayId] == nil then
    p("redis gatewayInfo function <GatewayInfo.UpdateuserID>, Redis GatewayInfo.hashTable[gatewayId] is nil")
    return -2
  end
  GatewayInfo.hashTable[gatewayId].userID = data
  return 0
end

-- 更新address
-- @param gatewayConfig 要更新的数据
-- @return 入参错误：-1, 成功：0， 其他错误：<0
function GatewayInfo.updateGatewayAddress(gatewayConfig)
  if gatewayConfig == nil then
    p("redis gatewayInfo function <GatewayInfo.updateGatewayAddress>, gatewayConfig param is nil")
    return -1
  end
  if GatewayInfo.hashTable[gatewayConfig.gatewayId] == nil then
    p(
      "redis gatewayInfo function <GatewayInfo.updateGatewayAddress>, gatewayId does not exist, please register. gatewayId:" ..
        gatewayConfig.gatewayId
    )
    return -2
  end
  if gatewayConfig.ip ~= nil then
    GatewayInfo.hashTable[gatewayConfig.gatewayId].address = gatewayConfig.ip
  end
  if gatewayConfig.identifier == consts.UDP_ID_PULL_DATA then
    GatewayInfo.hashTable[gatewayConfig.gatewayId].pullPort = gatewayConfig.port
  elseif gatewayConfig.identifier == consts.UDP_ID_PUSH_DATA then
    GatewayInfo.hashTable[gatewayConfig.gatewayId].pushPort = gatewayConfig.port
  else
    p(
      "redis gatewayInfo function <GatewayInfo.updateGatewayAddress>, Unknown value, identifier:" ..
        gatewayConfig.identifier
    )
  end
  return 0
end

return GatewayInfo
