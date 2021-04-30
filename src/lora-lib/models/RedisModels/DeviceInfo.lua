-- @info 用于存储设备信息的缓存区
local utiles = require("../../../../utiles/utiles.lua")

local DeviceInfo = {
  hashTable = {} -- 根据键值存储着设备信息
}

function DeviceInfo.Init()
  DeviceInfo.hashTable = {}
  -- 将mysql中的指定内容写入到redis中
end

-- 读取指定devaddr的信息
-- @param devaddr
function DeviceInfo.Read(devaddr)
  if devaddr == nil then
    p("devaddr is nil")
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
    p("devaddr is nil")
    return -1
  end
  local tmp = {}
  for i = 1, #item do
    if item[i] == "frequencyPlan" then
      tmp.frequencyPlan = DeviceInfo.hashTable[devaddr].frequencyPlan
    end
    if item[i] == "RX1DRoffset" then
      tmp.RX1DRoffset = DeviceInfo.hashTable[devaddr].RX1DRoffset
    end
    if item[i] == "RX1Delay" then
      tmp.RX1Delay = DeviceInfo.hashTable[devaddr].RX1Delay
    end
    if item[i] == "FCntUp" then
      tmp.FCntUp = DeviceInfo.hashTable[devaddr].FCntUp
    end
    if item[i] == "NFCntDown" then
      tmp.NFCntDown = DeviceInfo.hashTable[devaddr].NFCntDown
    end
    if item[i] == "AFCntDown" then
      tmp.AFCntDown = DeviceInfo.hashTable[devaddr].AFCntDown
    end
    if item[i] == "tmst" then
      tmp.tmst = DeviceInfo.hashTable[devaddr].tmst
    end
    if item[i] == "rfch" then
      tmp.rfch = DeviceInfo.hashTable[devaddr].rfch
    end
    if item[i] == "powe" then
      tmp.powe = DeviceInfo.hashTable[devaddr].powe
    end
    if item[i] == "freq" then
      tmp.freq = DeviceInfo.hashTable[devaddr].freq
    end
    if item[i] == "ADR" then
      tmp.ADR = DeviceInfo.hashTable[devaddr].ADR
    end
    if item[i] == "imme" then
      tmp.imme = DeviceInfo.hashTable[devaddr].imme
    end
    if item[i] == "ipol" then
      tmp.ipol = DeviceInfo.hashTable[devaddr].ipol
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
    p("devaddr is nil")
    return -1
  end
  if DeviceInfo.hashTable[devaddr] == nil then
    DeviceInfo.hashTable[devaddr] = {}
    DeviceInfo.hashTable[devaddr].frequencyPlan = info.frequencyPlan
    DeviceInfo.hashTable[devaddr].RX1DRoffset = info.RX1DRoffset
    DeviceInfo.hashTable[devaddr].RX1Delay = info.RX1Delay
    DeviceInfo.hashTable[devaddr].FCntUp = info.FCntUp -- 而在1.0之前版本只需要两个，差别在于原来计数分上行下行两个FCntUp和FCntDown
    DeviceInfo.hashTable[devaddr].NFCntDown = info.NFCntDown -- 而在1.1后的版本采用单独的用于MAC交互的port0和Fport未存在的时刻
    DeviceInfo.hashTable[devaddr].AFCntDown = info.AFCntDown -- 用于其他port
    DeviceInfo.hashTable[devaddr].tmst = info.tmst
    DeviceInfo.hashTable[devaddr].rfch = info.rfch
    DeviceInfo.hashTable[devaddr].powe = info.powe
    DeviceInfo.hashTable[devaddr].freq = info.freq
    DeviceInfo.hashTable[devaddr].ADR = info.ADR
    DeviceInfo.hashTable[devaddr].imme = info.imme
    DeviceInfo.hashTable[devaddr].ipol = info.ipol
    -- DeviceInfo.hashTable[devaddr] = {}
    -- for k,v in pairs(info) do
    --     DeviceInfo.hashTable[devaddr][k] = v;
    -- end
    p("inster a new device info, devaddr:" .. devaddr)
    return 0
  end
  p("devaddr already exists, devaddr:" .. devaddr)
  return -2
end

-- 更新指定devaddr的信息
-- @param devaddr
-- @param info 要写入的信息
-- @return 0 成功 -1 参数错误 -2 设备已经存在
function DeviceInfo.Update(devaddr, info)
  if devaddr == nil then
    p("devaddr is nil")
    return -1
  end
  if DeviceInfo.hashTable[devaddr] ~= nil then
    for k, v in pairs(info) do
      DeviceInfo.hashTable[devaddr][k] = v -- 更新指定devaddr的表 表中不存在的表项则新增
    end
    p("update device info, devaddr:" .. devaddr)
    return 0
  end
  p("error :update device info is nil, devaddr:" .. devaddr)
  return -2
end

function DeviceInfo.Clear()
  DeviceInfo.hashTable = nil
end

local function GetItemHandle(kVal, table)
  if kVal == "frequencyPlan" then
    return table.frequencyPlan
  elseif kVal == "RX1DRoffset" then
    return table.RX1DRoffset
  elseif kVal == "RX1Delay" then
    return table.RX1Delay
  elseif kVal == "FCntUp" then
    return table.FCntUp
  elseif kVal == "NFCntDown" then
    return table.NFCntDown
  elseif kVal == "AFCntDown" then
    return table.AFCntDown
  elseif kVal == "tmst" then
    return table.tmst
  elseif kVal == "rfch" then
    return table.rfch
  elseif kVal == "powe" then
    return table.powe
  elseif kVal == "freq" then
    return table.freq
  elseif kVal == "ADR" then
    return table.ADR
  elseif kVal == "imme" then
    return table.imme
  elseif kVal == "ipol" then
    return table.ipol
  else
    return 0
  end
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
function DeviceInfo.UpdateItem(appoint, item)
  if appoint == nil or item == nil then
    p("index or item is nil")
    return -1
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
            p("i is nil")
          end,
          [utiles.Default] = function()
            p("item is other, please check it.", i)
          end
        }
      end
    end
  end
end

return DeviceInfo
