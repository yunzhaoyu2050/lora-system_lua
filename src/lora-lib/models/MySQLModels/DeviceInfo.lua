-- @info 存储在json文件中的操作方法
local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")
local utiles = require("../../../../utiles/utiles.lua")
local logger = require("../../../log.lua")

local DeviceInfo = {
  timer = timer,
  hashTable = {} -- 以AppEUI为键值 存储着各个app的配置
}

-- "DevEUI",
-- "DevAddr",
-- "AppKey"
-- "AppEUI",
-- "DevNonce",
-- "AppNonce",
-- "NwkSKey",
-- "AppSKey",
-- "activationMode",
-- "ProtocolVersion",
-- "FCntUp",
-- "NFCntDown",
-- "AFCntDown"

function DeviceInfo.Write(devAddr, info)
  if devAddr == nil then
    logger.error("devAddr is nil")
    return -1
  end
  if DeviceInfo.hashTable[devAddr] == nil then
    DeviceInfo.hashTable[devAddr] = {
      DevEUI = info.DevEUI,
      DevAddr = info.DevAddr,
      AppKey = info.AppKey,
      AppEUI = info.AppEUI,
      DevNonce = info.DevNonce,
      AppNonce = info.AppNonce,
      NwkSKey = info.NwkSKey,
      AppSKey = info.AppSKey,
      activationMode = info.activationMode,
      ProtocolVersion = info.ProtocolVersion,
      FCntUp = info.FCntUp,
      NFCntDown = info.NFCntDown,
      AFCntDown = info.AFCntDown
    }
    logger.info("inster a new DeviceInfo, devAddr:", devAddr)
    return 0
  end
  logger.warn("devAddr already exists, devAddr:%s", devAddr)
  return -2
end

function DeviceInfo.Read(devAddr)
  if devAddr == nil then
    logger.error("devAddr is nil")
    return -1
  end
  return DeviceInfo.hashTable[devAddr]
end

local function GetItemHandle(kVal, table)
  if kVal == "DevEUI" then
    return table.DevEUI
  elseif kVal == "DevAddr" then
    return table.DevAddr
  elseif kVal == "AppKey" then
    return table.AppKey
  elseif kVal == "AppEUI" then
    return table.AppEUI
  elseif kVal == "DevNonce" then
    return table.DevNonce
  elseif kVal == "AppNonce" then
    return table.AppNonce
  elseif kVal == "NwkSKey" then
    return table.NwkSKey
  elseif kVal == "AppSKey" then
    return table.AppSKey
  elseif kVal == "activationMode" then
    return table.activationMode
  elseif kVal == "ProtocolVersion" then
    return table.ProtocolVersion
  elseif kVal == "FCntUp" then
    return table.FCntUp
  elseif kVal == "NFCntDown" then
    return table.NFCntDown
  elseif kVal == "AFCntDown" then
    return table.AFCntDown
  else
    return 0
  end
end

local function GetInputVal(index)
  for k, v in pairs(index) do
    return k, v -- 按照输入逻辑只为一个成员
  end
end

-- 读取指定成员的值并返回 并按照指定索引搜索
-- @param devaddr
-- @param item 指定成员集 {'DevEUI'="sg2j335d8jk"} {'DevEUI', 'DevAddr'}
-- @return -1 失败 成员集合 成功
function DeviceInfo.readItem(index, item)
  if index == nil or item == nil then
    logger.error("index or item is nil")
    return -1
  end
  local tmp = {}
  local inK, inV = GetInputVal(index)
  for k, v in pairs(DeviceInfo.hashTable) do
    if GetItemHandle(inK, DeviceInfo.hashTable[k]) == inV then
      -- 如果与索引的值相等 则把此k中的 指定成员返回
      for i = 1, #item do
        if item[i] == "DevEUI" then
          tmp.DevEUI = DeviceInfo.hashTable[k].DevEUI
        end
        if item[i] == "DevAddr" then
          tmp.DevAddr = DeviceInfo.hashTable[k].DevAddr
        end
        if item[i] == "AppKey" then
          tmp.AppKey = DeviceInfo.hashTable[k].AppKey
        end
        if item[i] == "AppEUI" then
          tmp.AppEUI = DeviceInfo.hashTable[k].AppEUI
        end
        if item[i] == "DevNonce" then
          tmp.DevNonce = DeviceInfo.hashTable[k].DevNonce
        end
        if item[i] == "AppNonce" then
          tmp.AppNonce = DeviceInfo.hashTable[k].AppNonce
        end
        if item[i] == "NwkSKey" then
          tmp.NwkSKey = DeviceInfo.hashTable[k].NwkSKey
        end
        if item[i] == "AppSKey" then
          tmp.AppSKey = DeviceInfo.hashTable[k].AppSKey
        end
        if item[i] == "activationMode" then
          tmp.activationMode = DeviceInfo.hashTable[k].activationMode
        end
        if item[i] == "ProtocolVersion" then
          tmp.ProtocolVersion = DeviceInfo.hashTable[k].ProtocolVersion
        end
        if item[i] == "FCntUp" then
          tmp.FCntUp = DeviceInfo.hashTable[k].FCntUp
        end
        if item[i] == "NFCntDown" then
          tmp.NFCntDown = DeviceInfo.hashTable[k].NFCntDown
        end
        if item[i] == "AFCntDown" then
          tmp.AFCntDown = DeviceInfo.hashTable[k].AFCntDown
        end
      end
    end
  end
  return tmp
end

function DeviceInfo.Update(devAddr, info)
  if devAddr == nil then
    logger.error("devAddr is nil")
    return -1
  end
  if DeviceInfo.hashTable[devAddr] ~= nil then
    DeviceInfo.hashTable[devAddr] = {
      -- 表中的表项固定
      DevEUI = info.DevEUI,
      DevAddr = info.DevAddr,
      AppKey = info.AppKey,
      AppEUI = info.AppEUI,
      DevNonce = info.DevNonce,
      AppNonce = info.AppNonce,
      NwkSKey = info.NwkSKey,
      AppSKey = info.AppSKey,
      activationMode = info.activationMode,
      ProtocolVersion = info.ProtocolVersion,
      FCntUp = info.FCntUp,
      NFCntDown = info.NFCntDown,
      AFCntDown = info.AFCntDown
    }
    logger.info("update DeviceInfo, devAddr:%s", devAddr)
    return 0
  end
  logger.warn("update DeviceInfo is nil, devAddr:%s", devAddr)
  return -2
end

-- 指定成员更新
-- @param devAddr {DevEUI=DevEUI}
-- @param info {AppEUI=AppEUI,FCntUp=FCntUp}
-- @return 0:成功 <0:失败
function DeviceInfo.UpdateItem(appoint, item)
  if appoint == nil or item == nil then
    logger.error("index or item is nil")
    return -1
  end
  local inK, inV = GetInputVal(appoint)
  for k, v in pairs(DeviceInfo.hashTable) do
    if GetItemHandle(inK, DeviceInfo.hashTable[k]) == inV then
      for i, v in pairs(item) do
        utiles.switch(i) {
          ["DevEUI"] = function()
            DeviceInfo.hashTable[k].DevEUI = v
          end,
          ["DevAddr"] = function()
            DeviceInfo.hashTable[k].DevAddr = v
          end,
          ["AppKey"] = function()
            DeviceInfo.hashTable[k].AppKey = v
          end,
          ["AppEUI"] = function()
            DeviceInfo.hashTable[k].AppEUI = v
          end,
          ["DevNonce"] = function()
            DeviceInfo.hashTable[k].DevNonce = v
          end,
          ["AppNonce"] = function()
            DeviceInfo.hashTable[k].AppNonce = v
          end,
          ["NwkSKey"] = function()
            DeviceInfo.hashTable[k].NwkSKey = v
          end,
          ["AppSKey"] = function()
            DeviceInfo.hashTable[k].AppSKey = v
          end,
          ["activationMode"] = function()
            DeviceInfo.hashTable[k].activationMode = v
          end,
          ["ProtocolVersion"] = function()
            DeviceInfo.hashTable[k].ProtocolVersion = v
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
          [utiles.Nil] = function()
            logger.error("i is nil")
          end,
          [utiles.Default] = function()
            logger.warn({"item is other, please check it.", i})
          end
        }
      end
    end
  end
end

-- 定时任务 将DeviceInfo.hashTable中的数据写入到DeviceInfo.data文件中
local function SynchronousData()
  if DeviceInfo.hashTable == nil then
    logger.error("DeviceInfo.hashTable is nil")
    return -1
  end
  local tmp = json.stringify(DeviceInfo.hashTable)
  if tmp ~= nil then
    fs.writeFileSync(serCfgInfo.GetDataPath() .. "/DeviceInfo.data", tmp)
    return 0
  end
  return -1
end

function DeviceInfo.Init()
  local deviceInfoPath = serCfgInfo.GetDataPath() .. "/DeviceInfo.data"
  local fd, err = fs.openSync(deviceInfoPath, "r+")
  if err ~= nil then
    -- 没有文件则创建一个空文件
    fd, err = fs.openSync(deviceInfoPath, "w+")
    if err ~= nil then
      logger.error("err:", err, fd)
      return -1
    end
    logger.info("create a new empty DeviceInfo.data")
  end
  local stat = fs.statSync(deviceInfoPath)
  local chunk, err = fs.readSync(fd, stat.size, 0)
  if err ~= nil or chunk == nil then
    logger.error("err:", err, chunk)
    return -1
  end
  -- 将文件中的数据读取到DeviceInfo.hashTable中
  DeviceInfo.hashTable = json.parse(chunk)
  -- 定时写入文件
  timer.setInterval(
    serCfgInfo.GetDeviceInfosql_syncTime(),
    function()
      SynchronousData()
    end
  )
  logger.info("DeviceInfo sql init success. timer:%d ms", serCfgInfo.GetDeviceInfosql_syncTime())
  return 0
end

return DeviceInfo
