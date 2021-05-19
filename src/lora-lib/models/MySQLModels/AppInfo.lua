-- @info 存储在json文件中的操作方法
local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")
local logger = require("../../../log.lua")

local AppInfo = {
  timer = timer,
  hashTable = {}
}

-- 1、AppInfo.lua,	key:AppEUI,		file:AppInfo.data
--  memory:
-- 	"AppEUI",
-- 	"userID",
-- 	"name"

function AppInfo.Write(appEui, info)
  if appEui == nil or type(appEui) ~= "string" then
    logger.error("appEui is nil or type is not string")
    return -1
  end
  if AppInfo.hashTable[appEui] == nil then
    AppInfo.hashTable[appEui] = {
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

function AppInfo.Read(appEui)
  if appEui == nil or type(appEui) ~= "string" then
    logger.error("appEui is nil or type is not string")
    return -1
  end
  return AppInfo.hashTable[appEui]
end

function AppInfo.Update(appEui, info)
  if appEui == nil or type(appEui) ~= "string" then
    logger.error("appEui is nil or type is not string")
    return -1
  end
  if AppInfo.hashTable[appEui] ~= nil then
    AppInfo.hashTable[appEui] = {
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

-- 定时任务 将AppInfo.hashTable中的数据写入到AppInfo.data文件中
local function SynchronousData()
  if AppInfo.hashTable == nil then
    logger.error("AppInfo.hashTable is nil")
    return -1
  end
  local tmp = json.stringify(AppInfo.hashTable)
  if tmp ~= nil then
    fs.writeFileSync(serCfgInfo.GetDataPath() .. "/AppInfo.data", tmp)
    return 0
  end
  return -1
end

function AppInfo.Init()
  local appInfoPath = serCfgInfo.GetDataPath() .. "/AppInfo.data"
  local fd, err = fs.openSync(appInfoPath, "r+")
  if err ~= nil then
    -- 没有文件则创建一个空文件
    fd, err = fs.openSync(appInfoPath, "w+")
    if err ~= nil then
      logger.error({"AppInfo open failed, err:, path:", err, appInfoPath})
      return -1
    end
    logger.info("create a new empty AppInfo.data")
  end
  local stat = fs.statSync(appInfoPath)
  local chunk, err = fs.readSync(fd, stat.size, 0)
  if err ~= nil or chunk == nil then
    logger.error({"AppInfo read failed, err:, path:", err, appInfoPath})
    return -1
  end
  -- 将文件中的数据读取到AppInfo.hashTable中
  AppInfo.hashTable = json.parse(chunk)
  -- 定时写入文件
  timer.setInterval(
    serCfgInfo.GetAppInfosql_syncTime(),
    function()
      SynchronousData()
    end
  )
  logger.info("AppInfo sql init success. timer:%d ms", serCfgInfo.GetAppInfosql_syncTime())
  return 0
end

return AppInfo
