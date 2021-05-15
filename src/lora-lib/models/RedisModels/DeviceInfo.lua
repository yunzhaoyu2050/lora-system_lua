-- @info 用于存储设备信息的缓存区
local utiles = require("../../../../utiles/utiles.lua")
local mysqlDeviceInfo = require("../MySQLModels/DeviceInfo.lua")
local fs = require("fs")

local DeviceInfo = {
  hashTable = {}
}

-- 2、DeviceInfo.lua,		key: DevAddr
-- 	"DevAddr",	新增
-- 	"frequencyPlan",
--  "RX1DRoffset",
--  "RX1Delay",
--  "FCntUp",
--  "NFCntDown",
--  "AFCntDown",
--  "tmst",
--  "rfch",
--  "powe",
--  "freq",
--  "ADR",
--  "imme",
--  "ipol"

-- redis同步mysql数据
local function SynchronousMySqlData()
  if DeviceInfo.hashTable == nil then
    p("redis deviceInfo function <SynchronousMySqlData>, deviceInfo.hashTable is nil")
    return -1
  end
  if mysqlDeviceInfo.hashTable == nil then
    p("redis deviceInfo function <SynchronousMySqlData>, mysqlDeviceInfo.hashTable is nil")
    return -1
  end
  DeviceInfo.hashTable = {}
  for k, _ in pairs(mysqlDeviceInfo.hashTable) do
    if mysqlDeviceInfo.hashTable[k].DevAddr ~= nil then
      DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr] = {}
      -- TODO: 同步数据时需要从多个mysql中同步数据
      DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].DevAddr = mysqlDeviceInfo.hashTable[k].DevAddr
      for a, b in pairs(mysqlDeviceInfo.hashTable[k]) do
        utiles.switch(a) {
          ["frequencyPlan"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].frequencyPlan = b
          end,
          ["RX1DRoffset"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].RX1DRoffset = b
          end,
          ["RX1Delay"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].RX1Delay = b
          end,
          ["FCntUp"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].FCntUp = b
          end,
          ["NFCntDown"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].NFCntDown = b
          end,
          ["AFCntDown"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].AFCntDown = b
          end,
          ["tmst"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].tmst = b
          end,
          ["rfch"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].rfch = b
          end,
          ["powe"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].powe = b
          end,
          ["freq"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].freq = b
          end,
          ["ADR"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].ADR = b
          end,
          ["imme"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].imme = b
          end,
          ["ipol"] = function()
            DeviceInfo.hashTable[mysqlDeviceInfo.hashTable[k].DevAddr].ipol = b
          end,
          [utiles.Nil] = function()
            p("a is nil")
          end
          -- [utiles.Default] = function()
          --   p("item is other, please check it.", a)
          -- end
        }
      end
    end
  end
  p("redis deviceInfo function <SynchronousMySqlData>, synchronous mysql data end")
  return 0
end

function DeviceInfo.Init()
  DeviceInfo.hashTable = {}
  -- 将mysql中的指定内容写入到redis中
  return SynchronousMySqlData() -- 初始化时同步一次
end

local function GetItemHandle(kVal, table)
  if kVal == nil or table == nil then
    p("redis deviceInfo function <GetItemHandle>, input param is nil")
    return 0
  end
  return utiles.switch(kVal) {
    ["DevAddr"] = function()
      return table.DevAddr
    end,
    ["frequencyPlan"] = function()
      return table.frequencyPlan
    end,
    ["RX1DRoffset"] = function()
      return table.RX1DRoffset
    end,
    ["RX1Delay"] = function()
      return table.RX1Delay
    end,
    ["FCntUp"] = function()
      return table.FCntUp
    end,
    ["NFCntDown"] = function()
      return table.NFCntDown
    end,
    ["AFCntDown"] = function()
      return table.AFCntDown
    end,
    ["tmst"] = function()
      return table.tmst
    end,
    ["rfch"] = function()
      return table.rfch
    end,
    ["powe"] = function()
      return table.powe
    end,
    ["freq"] = function()
      return table.freq
    end,
    ["ADR"] = function()
      return table.ADR
    end,
    ["imme"] = function()
      return table.imme
    end,
    ["ipol"] = function()
      return table.ipol
    end,
    [utiles.Nil] = function()
      p("redis deviceInfo function <GetItemHandle>, kVal is nil")
      return 0
    end,
    [utiles.Default] = function()
      p("redis deviceInfo function <GetItemHandle>, item is other, please check it.", kVal)
      return 0
    end
  }
end

local function GetInputVal(index)
  for k, v in pairs(index) do
    return k, v -- 按照输入逻辑只为一个成员
  end
end

-- 读取指定devaddr的信息
-- @param devaddr
-- @return 返回指定devaddr项的所有信息
function DeviceInfo.Read(devaddr)
  if devaddr == nil then
    p("redis deviceInfo function <DeviceInfo.Read>, devaddr is nil")
    return -1
  end
  return DeviceInfo.hashTable[devaddr]
end

-- 读取指定成员的值并返回
-- @param devaddr
-- @param item 指定成员集 {'frequencyPlan', 'RX1DRoffset'}
-- @return -1 失败 成员集合 成功
function DeviceInfo.readItem(devaddr, item)
  if devaddr == nil then
    p("redis deviceInfo function <DeviceInfo.readItem>, devaddr is nil")
    return -1
  end
  if item == nil then
    item = {
      "DevAddr",
      "frequencyPlan",
      "RX1DRoffset",
      "RX1Delay",
      "FCntUp",
      "NFCntDown",
      "AFCntDown",
      "tmst",
      "rfch",
      "powe",
      "freq",
      "ADR",
      "imme",
      "ipol"
    }
  end
  local tmp = {}
  local inK, inV = GetInputVal(devaddr)
  for k, v in pairs(DeviceInfo.hashTable) do
    if GetItemHandle(inK, DeviceInfo.hashTable[k]) == inV then
      for i = 1, #item do
        utiles.switch(item[i]) {
          ["DevAddr"] = function()
            tmp.DevAddr = DeviceInfo.hashTable[k].DevAddr
          end,
          ["frequencyPlan"] = function()
            tmp.frequencyPlan = DeviceInfo.hashTable[k].frequencyPlan
          end,
          ["RX1DRoffset"] = function()
            tmp.RX1DRoffset = DeviceInfo.hashTable[k].RX1DRoffset
          end,
          ["RX1Delay"] = function()
            tmp.RX1Delay = DeviceInfo.hashTable[k].RX1Delay
          end,
          ["FCntUp"] = function()
            tmp.FCntUp = DeviceInfo.hashTable[k].FCntUp
          end,
          ["NFCntDown"] = function()
            tmp.NFCntDown = DeviceInfo.hashTable[k].NFCntDown
          end,
          ["AFCntDown"] = function()
            tmp.AFCntDown = DeviceInfo.hashTable[k].AFCntDown
          end,
          ["tmst"] = function()
            tmp.tmst = DeviceInfo.hashTable[k].tmst
          end,
          ["rfch"] = function()
            tmp.rfch = DeviceInfo.hashTable[k].rfch
          end,
          ["powe"] = function()
            tmp.powe = DeviceInfo.hashTable[k].powe
          end,
          ["freq"] = function()
            tmp.freq = DeviceInfo.hashTable[k].freq
          end,
          ["ADR"] = function()
            tmp.ADR = DeviceInfo.hashTable[k].ADR
          end,
          ["imme"] = function()
            tmp.imme = DeviceInfo.hashTable[k].imme
          end,
          ["ipol"] = function()
            tmp.ipol = DeviceInfo.hashTable[k].ipol
          end,
          [utiles.Nil] = function()
            p("redis deviceInfo function <DeviceInfo.readItem>, item[i] is nil")
          end,
          [utiles.Default] = function()
            p("redis deviceInfo function <DeviceInfo.readItem>, item is other, please check it.", item[i])
          end
        }
      end
    end
  end
  return tmp
end

-- 写入指定devaddr的信息
-- @param devaddr
-- @param info 要写入的信息
-- @return 0 成功 -1 参数错误 -2 设备已经存在
function DeviceInfo.Write(devaddr, info)
  if devaddr == nil then
    p("redis deviceInfo function <DeviceInfo.Write>, devaddr is nil")
    return -1
  end
  if DeviceInfo.hashTable[devaddr] == nil then
    -- DeviceInfo.hashTable[devaddr] = {}
    -- DeviceInfo.hashTable[devaddr].DevAddr = info.DevAddr
    -- DeviceInfo.hashTable[devaddr].frequencyPlan = info.frequencyPlan
    -- DeviceInfo.hashTable[devaddr].RX1DRoffset = info.RX1DRoffset
    -- DeviceInfo.hashTable[devaddr].RX1Delay = info.RX1Delay
    -- DeviceInfo.hashTable[devaddr].FCntUp = info.FCntUp -- 而在1.0之前版本只需要两个，差别在于原来计数分上行下行两个FCntUp和FCntDown
    -- DeviceInfo.hashTable[devaddr].NFCntDown = info.NFCntDown -- 而在1.1后的版本采用单独的用于MAC交互的port0和Fport未存在的时刻
    -- DeviceInfo.hashTable[devaddr].AFCntDown = info.AFCntDown -- 用于其他port
    -- DeviceInfo.hashTable[devaddr].tmst = info.tmst
    -- DeviceInfo.hashTable[devaddr].rfch = info.rfch
    -- DeviceInfo.hashTable[devaddr].powe = info.powe
    -- DeviceInfo.hashTable[devaddr].freq = info.freq
    -- DeviceInfo.hashTable[devaddr].ADR = info.ADR
    -- DeviceInfo.hashTable[devaddr].imme = info.imme
    -- DeviceInfo.hashTable[devaddr].ipol = info.ipol
    DeviceInfo.hashTable[devaddr] = {}
    for k, v in pairs(info) do
      DeviceInfo.hashTable[devaddr][k] = v
    end
    p("redis deviceInfo function <DeviceInfo.Write>, inster a new device info, devaddr:" .. devaddr)
    return 0
  end
  p("redis deviceInfo function <DeviceInfo.Write>, devaddr already exists, devaddr:" .. devaddr)
  return -2
end

local function CheckIsDefualtItem(k)
  return utiles.switch(k) {
    ["DevAddr"] = function()
      return true
    end,
    ["frequencyPlan"] = function()
      return true
    end,
    ["RX1DRoffset"] = function()
      return true
    end,
    ["RX1Delay"] = function()
      return true
    end,
    ["FCntUp"] = function()
      return true
    end,
    ["NFCntDown"] = function()
      return true
    end,
    ["AFCntDown"] = function()
      return true
    end,
    ["tmst"] = function()
      return true
    end,
    ["rfch"] = function()
      return true
    end,
    ["powe"] = function()
      return true
    end,
    ["freq"] = function()
      return true
    end,
    ["ADR"] = function()
      return true
    end,
    ["imme"] = function()
      return true
    end,
    ["ipol"] = function()
      return true
    end,
    [utiles.Nil] = function()
      return false
    end,
    [utiles.Default] = function()
      return false
    end
  }
end

-- 更新指定devaddr的信息
-- @param devaddr
-- @param info 要写入的信息
-- @return 0 成功 -1 参数错误 -2 设备已经存在
function DeviceInfo.Update(devaddr, info)
  if devaddr == nil then
    p("redis deviceInfo function <DeviceInfo.Update>, devaddr is nil")
    return -1
  end
  if DeviceInfo.hashTable[devaddr] ~= nil then
    for k, v in pairs(info) do
      -- TODO: 检查表项是否与固定存储的表项匹配匹配则更新，反之略过
      -- if CheckIsDefualtItem(k) then
      DeviceInfo.hashTable[devaddr][k] = v
      -- end
    end
    p("redis deviceInfo function <DeviceInfo.Update>, update device info, devaddr:" .. devaddr)
    return 0
  end
  p("redis deviceInfo function <DeviceInfo.Update>, error :update device info is nil, devaddr:" .. devaddr)
  return -2
end

-- 指定成员更新
-- @param appoint {DevEUI=DevEUI}
-- @param item {AppEUI=AppEUI,FCntUp=FCntUp}
-- @return 0:成功 <0:失败
function DeviceInfo.UpdateItem(appoint, item)
  if appoint == nil then
    p("redis deviceInfo function <DeviceInfo.UpdateItem>, index or item is nil")
    return -1
  end
  if item == nil then
    item = {
      "DevAddr",
      "frequencyPlan",
      "RX1DRoffset",
      "RX1Delay",
      "FCntUp",
      "NFCntDown",
      "AFCntDown",
      "tmst",
      "rfch",
      "powe",
      "freq",
      "ADR",
      "imme",
      "ipol"
    }
  end
  local inK, inV = GetInputVal(appoint)
  for k, v in pairs(DeviceInfo.hashTable) do
    if GetItemHandle(inK, DeviceInfo.hashTable[k]) == inV then
      for i, v in pairs(item) do
        utiles.switch(i) {
          ["frequencyPlan"] = function()
            DeviceInfo.hashTable[k].frequencyPlan = v
          end,
          ["RX1DRoffset"] = function()
            DeviceInfo.hashTable[k].RX1DRoffset = v
          end,
          ["RX1Delay"] = function()
            DeviceInfo.hashTable[k].RX1Delay = v
          end,
          ["FCntUp"] = function()
            DeviceInfo.hashTable[k].FCntUp = v
          end,
          ["NFCntDown"] = function()
            DeviceInfo.hashTable[k].NFCntDown = v
          end,
          ["AFCntDown"] = function()
            DeviceInfo.hashTable[k].AFCntDown = v
          end,
          ["tmst"] = function()
            DeviceInfo.hashTable[k].tmst = v
          end,
          ["rfch"] = function()
            DeviceInfo.hashTable[k].rfch = v
          end,
          ["powe"] = function()
            DeviceInfo.hashTable[k].powe = v
          end,
          ["freq"] = function()
            DeviceInfo.hashTable[k].freq = v
          end,
          ["ADR"] = function()
            DeviceInfo.hashTable[k].ADR = v
          end,
          ["imme"] = function()
            DeviceInfo.hashTable[k].imme = v
          end,
          ["ipol"] = function()
            DeviceInfo.hashTable[k].ipol = v
          end,
          [utiles.Nil] = function()
            p("redis deviceInfo function <DeviceInfo.UpdateItem>, i is nil")
          end,
          [utiles.Default] = function()
            p("redis deviceInfo, item is other, add it.", i, v)
            DeviceInfo.hashTable[k][i] = v -- 不存在该条目需要将其新添加进去
          end
        }
      end
      break
    else
      -- TODO: 检测inV为devaddr
      DeviceInfo.Update(inV, item) -- 不存在该条目需要将其新添加进去
      break
    end
  end
  return 0
end

function DeviceInfo.IncreaseAfcntdown(devAddr)
  local res = DeviceInfo.readItem({DevAddr = devAddr}, {"AFCntDown"})
  res.AFCntDown = res.AFCntDown + 1
  return DeviceInfo.UpdateItem({DevAddr = devAddr}, {AFCntDown = res.AFCntDown})
end

-- 清空hash表
function DeviceInfo.Clear()
  DeviceInfo.hashTable = nil
end

return DeviceInfo
