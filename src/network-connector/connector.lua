local udp = require("./udp.lua")
local udpHandler = require("./udpHandler.lua")
local gatewayHandler = require("./gatewayHandler.lua")
local gatewayInfoRedis = require("../lora-lib/models/RedisModels/GatewayInfo.lua")
local consts = require("../lora-lib/constants/constants.lua")
local phyPackager = require("./phyPackager.lua")
local basexx = require("../../deps/basexx/lib/basexx.lua")
local utiles = require("../../utiles/utiles.lua")
local timer = require('timer')

-- connector模块任务

-- Uplink处理
function UplinkTask()
  udp.socket:on(
    "message",
    function(message, udpInfo)
      p("------------------------------------start--------------------------------------------")
      p("recv message: ", "ip:" .. udpInfo.ip, "port:" .. udpInfo.port, message)
      -- 1. udp层粗解析
      local udpUlJSON = udpHandler.parser(message)
      if udpUlJSON == nil then
        p("function <udpHandler.parser> failed")
        return -1
      end
      -- 2. 验证网关ID
      local ret = gatewayHandler.verifyGateway(udpUlJSON.gatewayId)
      if ret < 0 then
        p("function <gatewayHandler.verifyGateway> failed")
        return -1
      end
      -- 3. 更新redis中网关地址信息
      local gatewayConfig = {
        gatewayId = udpUlJSON.gatewayId,
        ip = udpInfo.ip,
        port = udpInfo.port,
        identifier = udpUlJSON.identifier
      }
      ret = gatewayHandler.updateGatewayAddress(gatewayConfig)
      if ret < 0 then
        p("function <gatewayHandler.updateGatewayAddress> failed")
      end
      -- 4. ACK应答
      ret = udpHandler.ACK(udpUlJSON)
      if ret ~= nil then
        udp.Send(ret, udpInfo)
        p("udp send <ACK> to gateway, udp-ip:", udpInfo.ip, "udp-port:", udpInfo.port, "message:<", ret, ">end")
        if gatewayConfig.identifier == consts.UDP_ID_PULL_DATA then
          return 0
        end
      end
      -- 5. pushData数据解析
      if udpUlJSON.pushData ~= nil then
        ret = udpHandler.pushDataParser(udpUlJSON)
        if ret ~= nil then
          local retStat, retRxpk = gatewayHandler.uploadPushData(ret)
          if retRxpk ~= nil then
            p("recv from server module message...")
            for k, _ in pairs(retRxpk) do
              ret = DownlinkTask(retRxpk[k])
            end
          else
            p("uplink process falied")
          end
          return ret
        -- return gatewayHandler.uploadPushData(ret)
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
  local PHYPayload = phyPackager.packager(message.txpk.data) -- phy层细打包
  if PHYPayload then
    message.txpk.size = PHYPayload.length
    message.txpk.data = basexx.to_base64(PHYPayload:toString()) -- 转换成base64格式 -- consts.DATA_ENCODING
    local udpDlData = udpHandler.packager(message) -- udp层打包
    local udpInfo = gatewayInfoRedis.Read(message.gatewayId) -- 取得网关信息
    if udpInfo then
      local cliUdpInfo = {}
      if message.identifier == consts.UDP_ID_PULL_DATA then -- TODO:
        cliUdpInfo.port = udpInfo.pullPort
      else
        cliUdpInfo.port = udpInfo.pushPort
      end
      -- if udpInfo.pullPort == nil then
      --   -- PULL_RESP通过* pull_port *发送到网关。 因此，网关必须在可以接收任何PULL_RESP之前发送PULL_DATA。
      --   p(" error: PULL_RESP is sent to the gateway through *pull_port*. Therefore, the gateway must send PULL_DATA before it can receive any PULL_RESP")
      --   return -2
      -- end
      -- cliUdpInfo.port = udpInfo.pullPort
      cliUdpInfo.ip = udpInfo.address
      p(
        "udp send message to gateway, udp-ip:",
        cliUdpInfo.ip,
        "udp-port:",
        cliUdpInfo.port,
        "message:<",
        udpDlData,
        ">end"
      )
      p("-------------------------------------end--------------------------------------------")
      return udp.Send(udpDlData, cliUdpInfo)
    end
  end
end

return {
  Start = UplinkTask,
  UplinkTask = UplinkTask,
  DownlinkTask = DownlinkTask
}
