-- @info 存储在json文件中的操作方法
local serCfgInfo = require("../../../../server_cfg.lua")
local json = require("json")
local fs = require("fs")
local timer = require("timer")

local AppInfo = {
  timer = timer,
  hashTable = {} -- 以AppEUI为键值 存储着各个app的配置
}

function AppInfo.Write(appEui, info)
  if appEui == nil then
    p("appEui is nil")
    return -1
  end
  if AppInfo.hashTable[appEui] == nil then
    AppInfo.hashTable[appEui] = {
      AppEUI = info.AppEUI,
      userID = info.userID,
      name = info.name
    }
    p("inster a new app info, appEui:" .. appEui)
    return 0
  end
  p("appEui already exists, appEui:" .. appEui)
  return -2
end

function AppInfo.Read(appEui)
  if appEui == nil then
    p("appEui is nil")
    return -1
  end
  return AppInfo.hashTable[appEui]
end

function AppInfo.Update(appEui, info)
  if appEui == nil then
    p("appEui is nil")
    return -1
  end
  if AppInfo.hashTable[appEui] ~= nil then
    AppInfo.hashTable[appEui] = {
      AppEUI = info.AppEUI,
      userID = info.userID,
      name = info.name
    }
    p("update app info, appEui:" .. appEui)
    return 0
  end
  p("error :update app info is nil, appEui:" .. appEui)
  return -2
end

-- 定时任务 将AppInfo.hashTable中的数据写入到AppInfo.data文件中
local function SynchronousData()
  if AppInfo.hashTable == nil then
    p("AppInfo.hashTable is nil")
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
      p(err, fd)
      return -1
    end
    p("create a new empty AppInfo.data")
  end
  local stat = fs.statSync(appInfoPath)
  local chunk, err = fs.readSync(fd, stat.size, 0)
  if err ~= nil or chunk == nil then
    p(err, chunk)
    return -1
  end
  -- 将文件中的数据读取到AppInfo.hashTable中
  AppInfo.hashTable = json.parse(chunk)
  -- 定时5s写入文件一次
  timer.setInterval(
    5000,
    function()
      SynchronousData()
    end
  )
  return 0
end

return AppInfo
