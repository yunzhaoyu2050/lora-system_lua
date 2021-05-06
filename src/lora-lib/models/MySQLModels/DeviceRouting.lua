-- @info 存储在json文件中的操作方法
local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")
local utiles = require("../../../../utiles/utiles.lua")

local DeviceRouting = {
  timer = timer,
  hashTable = {} -- 以AppEUI为键值 存储着各个app的配置
}

-- "DevAddr",
-- "gatewayId",
-- "imme",
-- "tmst",
-- "freq",
-- "rfch",
-- "powe",
-- "datr",
-- "modu",
-- "codr",
-- "ipol"

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

local function GetItemHandle(kVal, table)
  if kVal == "DevAddr" then
    return table.DevAddr
  elseif kVal == "gatewayId" then
    return table.gatewayId
  elseif kVal == "imme" then
    return table.imme
  elseif kVal == "tmst" then
    return table.tmst
  elseif kVal == "freq" then
    return table.freq
  elseif kVal == "rfch" then
    return table.rfch
  elseif kVal == "powe" then
    return table.powe
  elseif kVal == "datr" then
    return table.datr
  elseif kVal == "modu" then
    return table.modu
  elseif kVal == "codr" then
    return table.codr
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

function DeviceRouting.readItem(devaddr, item)
  if devaddr == nil then
    p("devaddr is nil")
    return -1
  end
  if item == nil then
    item = {
      "DevAddr",
      "gatewayId",
      "imme",
      "tmst",
      "freq",
      "rfch",
      "powe",
      "datr",
      "modu",
      "codr",
      "ipol"
    }
  end
  local tmp = {}
  local inK, inV = GetInputVal(devaddr)
  for k, v in pairs(DeviceRouting.hashTable) do
    if GetItemHandle(inK, DeviceRouting.hashTable[k]) == inV then
      for i = 1, #item do
        if item[i] == "DevAddr" then
          tmp.DevAddr = DeviceRouting.hashTable[k].DevAddr
        end
        if item[i] == "gatewayId" then
          tmp.gatewayId = DeviceRouting.hashTable[k].gatewayId
        end
        if item[i] == "imme" then
          tmp.imme = DeviceRouting.hashTable[k].imme
        end
        if item[i] == "tmst" then
          tmp.tmst = DeviceRouting.hashTable[k].tmst
        end
        if item[i] == "freq" then
          tmp.freq = DeviceRouting.hashTable[k].freq
        end
        if item[i] == "rfch" then
          tmp.rfch = DeviceRouting.hashTable[k].rfch
        end
        if item[i] == "powe" then
          tmp.powe = DeviceRouting.hashTable[k].powe
        end
        if item[i] == "datr" then
          tmp.datr = DeviceRouting.hashTable[k].datr
        end
        if item[i] == "modu" then
          tmp.modu = DeviceRouting.hashTable[k].modu
        end
        if item[i] == "codr" then
          tmp.codr = DeviceRouting.hashTable[k].codr
        end
        if item[i] == "ipol" then
          tmp.ipol = DeviceRouting.hashTable[k].ipol
        end
      end
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

-- 指定成员更新
-- @param devAddr {DevEUI=DevEUI}
-- @param info {AppEUI=AppEUI,FCntUp=FCntUp}
-- @return 0:成功 <0:失败
function DeviceRouting.UpdateItem(appoint, item)
  if appoint == nil or item == nil then
    p("index or item is nil")
    return -1
  end
  local inK, inV = GetInputVal(appoint)
  for k, v in pairs(DeviceRouting.hashTable) do
    if GetItemHandle(inK, DeviceRouting.hashTable[k]) == inV then
      for i, v in pairs(item) do
        utiles.switch(i) {
          ["DevAddr"] = function()
            DeviceRouting.hashTable[k].DevAddr = v
          end,
          ["gatewayId"] = function()
            DeviceRouting.hashTable[k].gatewayId = v
          end,
          ["imme"] = function()
            DeviceRouting.hashTable[k].imme = v
          end,
          ["tmst"] = function()
            DeviceRouting.hashTable[k].tmst = v
          end,
          ["freq"] = function()
            DeviceRouting.hashTable[k].freq = v
          end,
          ["rfch"] = function()
            DeviceRouting.hashTable[k].rfch = v
          end,
          ["powe"] = function()
            DeviceRouting.hashTable[k].powe = v
          end,
          ["datr"] = function()
            DeviceRouting.hashTable[k].datr = v
          end,
          ["modu"] = function()
            DeviceRouting.hashTable[k].modu = v
          end,
          ["codr"] = function()
            DeviceRouting.hashTable[k].codr = v
          end,
          ["ipol"] = function()
            DeviceRouting.hashTable[k].ipol = v
          end,
          [utiles.Nil] = function()
            p("i is nil")
          end,
          [utiles.Default] = function()
            p("item is other, please check it.", i)
          end
        }
      end
      break
    else
      DeviceRouting.Write(inV,item)
      break
    end
  end
  return 0
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
    -- 没有文件则创建一个空文件
    fd, err = fs.openSync(deviceRoutingPath, "w+")
    if err ~= nil then
      p(err, fd)
      return -1
    end
    p("create a new empty DeviceRouting.data")
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
