-- @info 存储模型

local RedisModelsDeviceInfo = require("./RedisModels/DeviceInfo.lua")
local RedisModelsGatewayInfo = require("./RedisModels/GatewayInfo.lua")
local MySQLModelsAppInfo = require("./MySQLModels/AppInfo.lua")
local MySQLModelsDeviceInfo = require("./MySQLModels/DeviceInfo.lua")
local MySQLModelsDeviceConfig = require("./MySQLModels/DeviceConfig.lua")
local MySQLModelsGatewayInfo = require("./MySQLModels/GatewayInfo.lua")
local MySQLDeviceRouting = require("./MySQLModels/DeviceRouting.lua")
local logger = require("../../log.lua")

local Models = {}

-- 模型初始化
function Models.Init()
  local ret = nil
  -- 初始化MySQL模型
  ret = MySQLModelsAppInfo.Init()
  if ret ~= 0 then
    logger.error("MySQLModelsAppInfo init failed")
    return -1
  end
  ret = MySQLModelsDeviceInfo.Init()
  if ret ~= 0 then
    logger.error("MySQLModelsDeviceInfo init failed")
    return -2
  end
  ret = MySQLModelsDeviceConfig.Init()
  if ret ~= 0 then
    logger.error("MySQLModelsDeviceConfig init failed")
    return -3
  end
  ret = MySQLModelsGatewayInfo.Init()
  if ret ~= 0 then
    logger.error("MySQLModelsGatewayInfo init failed")
    return -4
  end
  ret = MySQLDeviceRouting.Init()
  -- 初始化Redis模型
  RedisModelsDeviceInfo.Init()
  RedisModelsGatewayInfo.Init()
  return 0
end
return Models
