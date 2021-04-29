-- @info 存储在json文件中的操作方法
local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")

local DeviceRouting = {
  timer = timer,
  hashTable = {} -- 以AppEUI为键值 存储着各个app的配置
}

function DeviceRouting.Write(devAddr, info)
  if devAddr == nil then
    p("devAddr is nil")
    return -1
  end
  if DeviceRouting.hashTable[devAddr] == nil then
    DeviceRouting.hashTable[devAddr] = {
      DevAddr = info.DevAddr,
      gatewayId = info.gatewayId,
      imme = info.imme,
      tmst = info.tmst,
      freq = info.freq,
      rfch = info.rfch,
      powe = info.powe,
      datr = info.datr,
      modu = info.modu,
      codr = info.codr,
      ipol = info.ipol
    }
    p("inster a new DeviceRouting, devAddr:" .. devAddr)
    return 0
  end
  p("devAddr already exists, devAddr:" .. devAddr)
  return -2
end

function DeviceRouting.Read(devAddr)
  if devAddr == nil then
    p("devAddr is nil")
    return -1
  end
  return DeviceRouting.hashTable[devAddr]
end

function DeviceRouting.readItem(devaddr, item)
  if devaddr == nil then
    p("devaddr is nil")
    return -1
  end
  local tmp = {}
  for i = 1, #item do
    if item[i] == "DevAddr" then
      tmp.DevAddr = DeviceRouting.hashTable[devaddr].DevAddr
    end
    if item[i] == "gatewayId" then
      tmp.gatewayId = DeviceRouting.hashTable[devaddr].gatewayId
    end
    if item[i] == "imme" then
      tmp.imme = DeviceRouting.hashTable[devaddr].imme
    end
    if item[i] == "tmst" then
      tmp.tmst = DeviceRouting.hashTable[devaddr].tmst
    end
    if item[i] == "freq" then
      tmp.freq = DeviceRouting.hashTable[devaddr].freq
    end
    if item[i] == "rfch" then
      tmp.rfch = DeviceRouting.hashTable[devaddr].rfch
    end
    if item[i] == "powe" then
      tmp.powe = DeviceRouting.hashTable[devaddr].powe
    end
    if item[i] == "datr" then
      tmp.datr = DeviceRouting.hashTable[devaddr].datr
    end
    if item[i] == "modu" then
      tmp.modu = DeviceRouting.hashTable[devaddr].modu
    end
    if item[i] == "codr" then
      tmp.codr = DeviceRouting.hashTable[devaddr].codr
    end
    if item[i] == "ipol" then
      tmp.ipol = DeviceRouting.hashTable[devaddr].ipol
    end
  end
  return tmp
end

function DeviceRouting.Update(devAddr, info)
  if devAddr == nil then
    p("devAddr is nil")
    return -1
  end
  if DeviceRouting.hashTable[devAddr] ~= nil then
    DeviceRouting.hashTable[devAddr] = {
      DevAddr = info.DevAddr,
      gatewayId = info.gatewayId,
      imme = info.imme,
      tmst = info.tmst,
      freq = info.freq,
      rfch = info.rfch,
      powe = info.powe,
      datr = info.datr,
      modu = info.modu,
      codr = info.codr,
      ipol = info.ipol
    }
    p("update DeviceRouting, devAddr:" .. devAddr)
    return 0
  end
  p("error :update DeviceRouting is nil, devAddr:" .. devAddr)
  return -2
end

-- 定时任务 将DeviceRouting.hashTable中的数据写入到DeviceRouting.data文件中
local function SynchronousData()
  if DeviceRouting.hashTable == nil then
    p("DeviceRouting.hashTable is nil")
    return -1
  end
  local tmp = json.stringify(DeviceRouting.hashTable)
  if tmp ~= nil then
    fs.writeFileSync(serCfgInfo.GetDataPath() .. "/DeviceRouting.data", tmp)
    return 0
  end
  return -1
end

function DeviceRouting.Init()
  local deviceRoutingPath = serCfgInfo.GetDataPath() .. "/DeviceRouting.data"
  -- 没有文件则创建一个空文件
  local fd, err = fs.openSync(deviceRoutingPath, "r+")
  if err ~= nil then
    p(err, fd)
    return -1
  end
  local stat = fs.statSync(deviceRoutingPath)
  local chunk, err = fs.readSync(fd, stat.size, 0)
  if err ~= nil or chunk == nil then
    p(err, chunk)
    return -1
  end
  -- 将文件中的数据读取到DeviceRouting.hashTable中
  DeviceRouting.hashTable = json.parse(chunk)
  -- 定时5s写入文件一次
  timer.setInterval(
    5000,
    function()
      SynchronousData()
    end
  )
  return 0
end

return DeviceRouting
