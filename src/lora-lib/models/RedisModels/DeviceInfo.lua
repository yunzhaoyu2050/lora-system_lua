-- @info 用于存储设备信息的缓存区
local DeviceInfo = {
  hashTable = {} -- 根据键值存储着设备信息
}

function DeviceInfo.Init()
  DeviceInfo.hashTable = nil
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

return DeviceInfo
