local udp = require("./udp.lua")
local udpHandler = require("./udpHandler.lua")
local gatewayHandler = require("./gatewayHandler.lua")
-- connector模块任务
-- Uplink处理
function UplinkTask()
  -- uplink
  udp.socket:on(
    "message",
    function(message, udpInfo)
      p("recv message: ", "ip:" .. udpInfo.ip, "port:" .. udpInfo.port, message)
      -- 1. udp层粗解析
      local udpUlJSON = udpHandler.parser(message)
      p("parser udpUlJSON: ", udpUlJSON)
      -- 2. 验证网关ID
      local ret = gatewayHandler.verifyGateway(udpUlJSON.gatewayId)
      -- 3. 更新网关地址
      local gatewayConfig = {
        gatewayId = udpUlJSON.gatewayId,
        ip = udpInfo.ip,
        port = udpInfo.port,
        identifier = udpUlJSON.identifier
      }
      ret = gatewayHandler.updateGatewayAddress(gatewayConfig)
      -- 4. ACK应答
      ret = udpHandler.ACK(udpUlJSON)
      if ret ~= nil then
        udp.Send(ret, udpInfo)
      end
      -- 5. pushData数据解析
      if udpUlJSON.pushData ~= nil then
        -- pushData数据解析
        ret = udpHandler.pushDataParser(udpUlJSON)
        if ret ~= nil then
          return gatewayHandler.uploadPushData(ret)
        end
      else
        -- return mqClient.publish(config.mqClient_nc.topics.pubToServer, udpUlJSON);
        -- pushData不存在也将其推送至network-server模块处理
        p(udpUlJSON)
      end
    end
  )
end
-- Downlink处理
function DownlinkTask(message)
  if udpHandler == nil then
    p("udpHandler is nil.")
    return -1
  end
  local udpDlData
  local PHYPayload = phyPackager.packager(message.txpk.data) -- phy层打包
  if PHYPayload then
    message.txpk.size = PHYPayload.length
    message.txpk.data = PHYPayload.toString(consts.DATA_ENCODING)
    udpDlData = udpHandler.packager(message) -- udp层打包
    local udpInfo = modelIns.RedisModel.GatewayInfo.queryGatewayAddress(message.gatewayId) -- 取得网关信息
    if udpInfo then
      udpInfo.port = udpInfo.pullPort
      -- logInfo.port = udpInfo.pullPort;
      -- logInfo.identifier = Buffer:new(consts.UDP_IDENTIFIER_LEN);
      -- logInfo.identifier.writeUInt8(consts.UDP_ID_PULL_RESP);
      -- logInfo.gatewayIP = udpInfo.address;
      -- log.info(logInfo);
      return udpServer.send(udpDlData, udpInfo, message.value.gatewayId)
    end
  end
end
return {
  Start = UplinkTask,
  UplinkTask = UplinkTask,
  DownlinkTask = DownlinkTask
}
