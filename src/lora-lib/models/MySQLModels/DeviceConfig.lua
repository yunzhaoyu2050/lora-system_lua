-- @info 存储在json文件中的操作方法
local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")
local utiles = require("../../../../utiles/utiles.lua")

local DeviceConfig = {
  timer = timer,
  hashTable = {} -- 以AppEUI为键值 存储着各个app的配置
}

function DeviceConfig.Write(devAddr, info)
  if devAddr == nil then
    p("devAddr is nil")
    return -1
  end
  if DeviceConfig.hashTable[devAddr] == nil then
    DeviceConfig.hashTable[devAddr] = {
      DevAddr = info.DevAddr,
      frequencyPlan = info.frequencyPlan,
      ADR = info.ADR,
      ADR_ACK_LIMIT = info.ADR_ACK_LIMIT,
      ADR_ACK_DELAY = info.ADR_ACK_DELAY,
      ChMask = info.ChMask,
      CFList = info.CFList,
      ChDrRange = info.ChDrRange,
      RX1CFList = info.RX1CFList,
      RX1DRoffset = info.RX1DRoffset,
      RX1Delay = info.RX1Delay,
      RX2Freq = info.RX2Freq,
      RX2DataRate = info.RX2DataRate,
      NbTrans = info.NbTrans,
      MaxDCycle = info.MaxDCycle,
      MaxEIRP = info.MaxEIRP
    }
    p("inster a new DeviceConfig, devAddr:" .. devAddr)
    return 0
  end
  p("devAddr already exists, devAddr:" .. devAddr)
  return -2
end

function DeviceConfig.Read(devAddr)
  if devAddr == nil then
    p("devAddr is nil")
    return -1
  end
  return DeviceConfig.hashTable[devAddr]
end

-- 读取指定成员的值并返回
-- @param devaddr
-- @param item 指定成员集 {'DevEUI', 'DevAddr'}
-- @return -1 失败 成员集合 成功
function DeviceConfig.readItem(devaddr, item)
  if devaddr == nil then
    p("devaddr is nil")
    return -1
  end
  local tmp = {}
  for i = 1, #item do
    if item[i] == "DevAddr" then
      tmp.DevAddr = DeviceConfig.hashTable[devaddr].DevAddr
    end
    if item[i] == "frequencyPlan" then
      tmp.frequencyPlan = DeviceConfig.hashTable[devaddr].frequencyPlan
    end
    if item[i] == "ADR" then
      tmp.ADR = DeviceConfig.hashTable[devaddr].ADR
    end
    if item[i] == "ADR_ACK_LIMIT" then
      tmp.ADR_ACK_LIMIT = DeviceConfig.hashTable[devaddr].ADR_ACK_LIMIT
    end
    if item[i] == "ADR_ACK_DELAY" then
      tmp.ADR_ACK_DELAY = DeviceConfig.hashTable[devaddr].ADR_ACK_DELAY
    end
    if item[i] == "ChMask" then
      tmp.ChMask = DeviceConfig.hashTable[devaddr].ChMask
    end
    if item[i] == "CFList" then
      tmp.CFList = DeviceConfig.hashTable[devaddr].CFList
    end
    if item[i] == "ChDrRange" then
      tmp.ChDrRange = DeviceConfig.hashTable[devaddr].ChDrRange
    end
    if item[i] == "RX1CFList" then
      tmp.RX1CFList = DeviceConfig.hashTable[devaddr].RX1CFList
    end
    if item[i] == "RX1DRoffset" then
      tmp.RX1DRoffset = DeviceConfig.hashTable[devaddr].RX1DRoffset
    end
    if item[i] == "RX1Delay" then
      tmp.RX1Delay = DeviceConfig.hashTable[devaddr].RX1Delay
    end
    if item[i] == "RX2Freq" then
      tmp.RX2Freq = DeviceConfig.hashTable[devaddr].RX2Freq
    end
    if item[i] == "RX2DataRate" then
      tmp.RX2DataRate = DeviceConfig.hashTable[devaddr].RX2DataRate
    end
    if item[i] == "NbTrans" then
      tmp.NbTrans = DeviceConfig.hashTable[devaddr].NbTrans
    end
    if item[i] == "MaxDCycle" then
      tmp.MaxDCycle = DeviceConfig.hashTable[devaddr].MaxDCycle
    end
    if item[i] == "MaxEIRP" then
      tmp.MaxEIRP = DeviceConfig.hashTable[devaddr].MaxEIRP
    end
  end
  return tmp
end

function DeviceConfig.Update(devAddr, info)
  if devAddr == nil then
    p("devAddr is nil")
    return -1
  end
  if DeviceConfig.hashTable[devAddr] ~= nil then
    DeviceConfig.hashTable[devAddr] = {
      DevAddr = info.DevAddr,
      frequencyPlan = info.frequencyPlan,
      ADR = info.ADR,
      ADR_ACK_LIMIT = info.ADR_ACK_LIMIT,
      ADR_ACK_DELAY = info.ADR_ACK_DELAY,
      ChMask = info.ChMask,
      CFList = info.CFList,
      ChDrRange = info.ChDrRange,
      RX1CFList = info.RX1CFList,
      RX1DRoffset = info.RX1DRoffset,
      RX1Delay = info.RX1Delay,
      RX2Freq = info.RX2Freq,
      RX2DataRate = info.RX2DataRate,
      NbTrans = info.NbTrans,
      MaxDCycle = info.MaxDCycle,
      MaxEIRP = info.MaxEIRP
    }
    p("update DeviceConfig, devAddr:" .. devAddr)
    return 0
  end
  p("error :update DeviceConfig is nil, devAddr:" .. devAddr)
  return -2
end

function DeviceConfig.Update(devAddr, info)
  if devAddr == nil then
    p("devAddr is nil")
    return -1
  end
  if DeviceConfig.hashTable[devAddr] ~= nil then
    DeviceConfig.hashTable[devAddr] = {
      DevAddr = info.DevAddr,
      frequencyPlan = info.frequencyPlan,
      ADR = info.ADR,
      ADR_ACK_LIMIT = info.ADR_ACK_LIMIT,
      ADR_ACK_DELAY = info.ADR_ACK_DELAY,
      ChMask = info.ChMask,
      CFList = info.CFList,
      ChDrRange = info.ChDrRange,
      RX1CFList = info.RX1CFList,
      RX1DRoffset = info.RX1DRoffset,
      RX1Delay = info.RX1Delay,
      RX2Freq = info.RX2Freq,
      RX2DataRate = info.RX2DataRate,
      NbTrans = info.NbTrans,
      MaxDCycle = info.MaxDCycle,
      MaxEIRP = info.MaxEIRP
    }
    p("update DeviceConfig, devAddr:" .. devAddr)
    return 0
  end
  p("error :update DeviceConfig is nil, devAddr:" .. devAddr)
  return -2
end

local function GetItemHandle(kVal, table)
  return utiles.switch(kVal) {
    ["DevAddr"] = function()
      return info.DevAddr
    end,
    ["frequencyPlan"] = function()
      return info.frequencyPlan
    end,
    ["ADR"] = function()
      return info.ADR
    end,
    ["ADR_ACK_LIMIT"] = function()
      return info.ADR_ACK_LIMIT
    end,
    ["ADR_ACK_DELAY"] = function()
      return info.ADR_ACK_DELAY
    end,
    ["ChMask"] = function()
      return info.ChMask
    end,
    ["CFList"] = function()
      return info.CFList
    end,
    ["ChDrRange"] = function()
      return info.ChDrRange
    end,
    ["RX1CFList"] = function()
      return info.RX1CFList
    end,
    ["RX1DRoffset"] = function()
      return info.RX1DRoffset
    end,
    ["RX1Delay"] = function()
      return info.RX1Delay
    end,
    ["RX2Freq"] = function()
      return info.RX2Freq
    end,
    ["RX2DataRate"] = function()
      return info.RX2DataRate
    end,
    ["NbTrans"] = function()
      return info.NbTrans
    end,
    ["MaxDCycle"] = function()
      return info.MaxDCycle
    end,
    ["MaxEIRP"] = function()
      return info.MaxEIRP
    end,
    [utiles.Nil] = function()
      return 0
    end,
    [utiles.Default] = function()
      return 0
    end
  }
end

local function GetInputVal(index)
  for k, v in pairs(index) do
    return k, v -- 按照输入逻辑只为一个成员
  end
end

-- 指定成员更新
-- @param devAddr {DevEUI=DevEUI}
-- @param info {AppEUI=AppEUI,FCntUp=FCntUp}
-- @return 0:成功 <0:失败
function DeviceConfig.UpdateItem(appoint, item)
  if appoint == nil or item == nil then
    p("index or item is nil")
    return -1
  end
  local inK, inV = GetInputVal(appoint)
  for k, v in pairs(DeviceConfig.hashTable) do
    if GetItemHandle(inK, DeviceConfig.hashTable[k]) == inV then
      for i, v in pairs(item) do
        utiles.switch(i) {
          ["DevAddr"] = function()
            DeviceConfig.hashTable[k].DevAddr = v
          end,
          ["frequencyPlan"] = function()
            DeviceConfig.hashTable[k].frequencyPlan = v
          end,
          ["ADR"] = function()
            DeviceConfig.hashTable[k].ADR = v
          end,
          ["ADR_ACK_LIMIT"] = function()
            DeviceConfig.hashTable[k].ADR_ACK_LIMIT = v
          end,
          ["ADR_ACK_DELAY"] = function()
            DeviceConfig.hashTable[k].ADR_ACK_DELAY = v
          end,
          ["ChMask"] = function()
            DeviceConfig.hashTable[k].ChMask = v
          end,
          ["CFList"] = function()
            DeviceConfig.hashTable[k].CFList = v
          end,
          ["ChDrRange"] = function()
            DeviceConfig.hashTable[k].ChDrRange = v
          end,
          ["RX1CFList"] = function()
            DeviceConfig.hashTable[k].RX1CFList = v
          end,
          ["RX1DRoffset"] = function()
            DeviceConfig.hashTable[k].RX1DRoffset = v
          end,
          ["RX1Delay"] = function()
            DeviceConfig.hashTable[k].RX1Delay = v
          end,
          ["RX2Freq"] = function()
            DeviceConfig.hashTable[k].RX2Freq = v
          end,
          ["RX2DataRate"] = function()
            DeviceConfig.hashTable[k].RX2DataRate = v
          end,
          ["NbTrans"] = function()
            DeviceConfig.hashTable[k].NbTrans = v
          end,
          ["MaxDCycle"] = function()
            DeviceConfig.hashTable[k].MaxDCycle = v
          end,
          ["MaxEIRP"] = function()
            DeviceConfig.hashTable[k].MaxEIRP = v
          end,
          [utiles.Nil] = function()
            return p("i is nil")
          end,
          [utiles.Default] = function()
            return p("item is other, please check it.", i)
          end
        }
      end
    end
  end
end

-- 同步数据
local function SynchronousData()
  if DeviceConfig.hashTable == nil then
    p("DeviceConfig.hashTable is nil")
    return -1
  end
  local tmp = json.stringify(DeviceConfig.hashTable)
  if tmp ~= nil then
    fs.writeFileSync(serCfgInfo.GetDataPath() .. "/DeviceConfig.data", tmp)
    return 0
  end
  return -1
end

function DeviceConfig.Init()
  local deviceConfigPath = serCfgInfo.GetDataPath() .. "/DeviceConfig.data"
  -- 没有文件则创建一个空文件
  local fd, err = fs.openSync(deviceConfigPath, "r+")
  if err ~= nil then
    -- 没有文件则创建一个空文件
    fd, err = fs.openSync(deviceConfigPath, "w+")
    if err ~= nil then
      p(err, fd)
      return -1
    end
    p("create a new empty DeviceConfig.data")
  end
  local stat = fs.statSync(deviceConfigPath)
  local chunk, err = fs.readSync(fd, stat.size, 0)
  if err ~= nil or chunk == nil then
    p(err, chunk)
    return -1
  end
  -- 将文件中的数据读取到DeviceConfig.hashTable中
  DeviceConfig.hashTable = json.parse(chunk)
  -- 定时5s写入文件一次
  timer.setInterval(
    5000,
    function()
      SynchronousData()
    end
  )
  return 0
end

return DeviceConfig
