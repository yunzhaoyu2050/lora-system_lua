-- @info 存储在json文件中的操作方法
local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")

local GatewayInfo = {
  timer = timer,
  hashTable = {} -- 以gatewayId为键值 存储着各个app的配置
}

function GatewayInfo.Write(gatewayId, info)
  if gatewayId == nil then
    p("gatewayId is nil")
    return -1
  end
  if GatewayInfo.hashTable[gatewayId] == nil then
    GatewayInfo.hashTable[gatewayId] = {
      gatewayId = info.gatewayId,
      userID = info.userID,
      frequencyPlan = info.frequencyPlan,
      location = info.location,
      RFChain = info.RFChain,
      type = info.type,
      model = info.model
    }
    p("inster a new GatewayInfo, gatewayId:" .. gatewayId)
    return 0
  end
  p("gatewayId already exists, gatewayId:" .. gatewayId)
  return -2
end

function GatewayInfo.Read(gatewayId)
  if gatewayId == nil then
    p("gatewayId is nil")
    return -1
  end
  return GatewayInfo.hashTable[gatewayId]
end

function GatewayInfo.Update(gatewayId, info)
  if gatewayId == nil then
    p("gatewayId is nil")
    return -1
  end
  if GatewayInfo.hashTable[gatewayId] ~= nil then
    GatewayInfo.hashTable[gatewayId] = {
      gatewayId = info.gatewayId,
      userID = info.userID,
      frequencyPlan = info.frequencyPlan,
      location = info.location,
      RFChain = info.RFChain,
      type = info.type,
      model = info.model
    }
    p("update GatewayInfo, gatewayId:" .. gatewayId)
    return 0
  end
  p("error :update GatewayInfo is nil, gatewayId:" .. gatewayId)
  return -2
end

-- 定时任务 将GatewayInfo.hashTable中的数据写入到GatewayInfo.data文件中
local function SynchronousData()
  if GatewayInfo.hashTable == nil then
    p("GatewayInfo.hashTable is nil")
    return -1
  end
  local tmp = json.stringify(GatewayInfo.hashTable)
  if tmp ~= nil then
    fs.writeFileSync(serCfgInfo.GetDataPath() .. "/GatewayInfo.data", tmp)
    return 0
  end
  return -1
end

function GatewayInfo.Init()
  local gatewayInfoPath = serCfgInfo.GetDataPath() .. "/GatewayInfo.data"
  -- 没有文件则创建一个空文件
  local fd, err = fs.openSync(gatewayInfoPath, "r+")
  if err ~= nil then
    fd, err = fs.openSync(gatewayInfoPath, "w+")
    if err ~= nil then
      p(err, fd)
      return -1
    end
    p("create a new empty DeviceInfo.data")
  end
  local stat = fs.statSync(gatewayInfoPath)
  local chunk, err = fs.readSync(fd, stat.size, 0)
  if err ~= nil or chunk == nil then
    p(err, chunk)
    return -1
  end
  -- 将文件中的数据读取到GatewayInfo.hashTable中
  GatewayInfo.hashTable = json.parse(chunk)
  -- 定时5s写入文件一次
  timer.setInterval(
    5000,
    function()
      SynchronousData()
    end
  )
  return 0
end

function GatewayInfo.GetuserID(gatewayId)
  if GatewayInfo.hashTable[gatewayId] == nil then
    p("MySql GatewayInfo.hashTable[gatewayId] is nil")
    return 0
  end
  return GatewayInfo.hashTable[gatewayId].userID
end

return GatewayInfo
