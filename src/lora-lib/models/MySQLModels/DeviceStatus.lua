local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")
local logger = require("../../../log.lua")

local DeviceStatus = {
  -- timer = timer,
  -- hashTable = {}
}
  
-- 1、DeviceStatus.lua,	key:DevAddr,		file:DeviceStatus.data
-- {
--   "devaddr1": {
--     "time1":{...},
--     "time2":{...}
--   },
--   "devaddr2": {
--     "time1":{...}
--   },
-- }
--  memory:
-- 	"DevAddr",
-- 	"gatewayId",
-- 	"time",
--  "tmst",
--  "freq",
--  "chan",
--  "rfch",
--  "stat",
--  "modu",
--  "datr",
--  "codr",
--  "rssi",
--  "lsnr",
--  "size"

function DeviceStatus.Write(devaddr, info)
  if devaddr == nil or type(devaddr) ~= "string" then
    logger.error("devaddr is nil or type is not string")
    return -1
  end
  if info.time == nil then
    logger.error("info.time is nil")
    return -1
  end

  

  if DeviceStatus.hashTable[appEui] == nil then
    DeviceStatus.hashTable[appEui] = {
      AppEUI = info.AppEUI,
      userID = info.userID,
      name = info.name
    }
    logger.info("inster a new app info, appEui:%s", appEui)
    return 0
  end
  logger.warn("appEui already exists, appEui:%s", appEui)
  return -2
end

function DeviceStatus.Read(appEui)
  if appEui == nil or type(appEui) ~= "string" then
    logger.error("appEui is nil or type is not string")
    return -1
  end
  return DeviceStatus.hashTable[appEui]
end

function DeviceStatus.Update(appEui, info)
  if appEui == nil or type(appEui) ~= "string" then
    logger.error("appEui is nil or type is not string")
    return -1
  end
  if DeviceStatus.hashTable[appEui] ~= nil then
    DeviceStatus.hashTable[appEui] = {
      AppEUI = info.AppEUI,
      userID = info.userID,
      name = info.name
    }
    logger.info("update app info, appEui:%s", appEui)
    return 0
  end
  logger.warn("update app info is nil, appEui:%s", appEui)
  return -2
end

-- 定时任务 将DeviceStatus.hashTable中的数据写入到DeviceStatus.data文件中
local function SynchronousData()
  if DeviceStatus.hashTable == nil then
    logger.error("DeviceStatus.hashTable is nil")
    return -1
  end
  local tmp = json.stringify(DeviceStatus.hashTable)
  if tmp ~= nil then
    fs.writeFileSync(serCfgInfo.GetDataPath() .. "/DeviceStatus.data", tmp)
    return 0
  end
  return -1
end

function DeviceStatus.Init()
  local DeviceStatusPath = serCfgInfo.GetDataPath() .. "/DeviceStatus.data"
  local fd, err = fs.openSync(DeviceStatusPath, "r+")
  if err ~= nil then
    -- 没有文件则创建一个空文件
    fd, err = fs.openSync(DeviceStatusPath, "w+")
    if err ~= nil then
      logger.error({"DeviceStatus open failed, err:, path:", err, DeviceStatusPath})
      return -1
    end
    logger.info("create a new empty DeviceStatus.data")
  end
  local stat = fs.statSync(DeviceStatusPath)
  local chunk, err = fs.readSync(fd, stat.size, 0)
  if err ~= nil or chunk == nil then
    logger.error({"DeviceStatus read failed, err:, path:", err, DeviceStatusPath})
    return -1
  end
  -- 将文件中的数据读取到DeviceStatus.hashTable中
  DeviceStatus.hashTable = json.parse(chunk)
  -- 定时写入文件
  timer.setInterval(
    serCfgInfo.GetDeviceStatussql_syncTime(),
    function()
      SynchronousData()
    end
  )
  logger.info("DeviceStatus sql init success. timer:%d ms", serCfgInfo.GetDeviceStatussql_syncTime())
  return 0
end

return DeviceStatus
