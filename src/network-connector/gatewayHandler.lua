-- @info 涉及网关信息 操作相关的方法
local _GatewayInfoRedis = require("../lora-lib/models/RedisModels/GatewayInfo.lua")
local _GatewayInfoMySQL = require("../lora-lib/models/MySQLModels/GatewayInfo.lua")
local consts = require("../lora-lib/constants/constants.lua")
local serverHandle = require("../network-server/server.lua")

-- 上传至server模块数据
function uploadPushData(pushData)
  local msgHeader = {
    version = pushData.origin.version,
    token = pushData.origin.token,
    identifier = pushData.origin.identifier,
    gatewayId = pushData.origin.gatewayId
  }
  local ret = 0
  if pushData.stat ~= nil then -- 网关状态数据
    local stat = msgHeader
    stat.stat = pushData.stat
    serverHandle.Process({type = "ConnectorPubToServer", data = stat}) -- 把状态数据推送至network-server模块
  end
  if pushData.rxpk ~= nil then -- 业务数据
    for i, v in pairs(pushData.rxpk) do
      local rxpk = msgHeader
      rxpk.rxpk = pushData.rxpk[i]
      serverHandle.Process({type = "ConnectorPubToServer", data = rxpk}) -- 把业务数据推送至network-server模块
    end
  end
  return ret
end

-- 验证网关ID
-- @param gatewayId 网关id
function verifyGateway(gatewayId)
  -- 根据 gatewayId 在缓存中及数据库中 都查找是否存在
  if gatewayId == nil then
    p("gatewayId is nil.")
    return -1
  end
  if _GatewayInfoRedis.GetuserID(gatewayId) ~= nil then
    local tmp = _GatewayInfoMySQL.GetuserID(gatewayId)
    if tmp ~= nil then
      return _GatewayInfoRedis.UpdateuserID(gatewayId, tmp)
    else
      p("The received Gateway is not registered, the whole package is ignored, gatewayId:", gatewayId)
      return -2
    end
  end
  return -1
end

-- 更新网关地址
-- @param gatewayConfig 配置
function updateGatewayAddress(gatewayConfig)
  if gatewayConfig.identifier == consts.UDP_ID_PULL_DATA then
    gatewayConfig.pullPort = gatewayConfig.port
  else
    gatewayConfig.pushPort = gatewayConfig.port
  end

  return _GatewayInfoRedis.updateGatewayAddress(gatewayConfig)
end

return {
  verifyGateway = verifyGateway,
  updateGatewayAddress = updateGatewayAddress,
  uploadPushData = uploadPushData
}
