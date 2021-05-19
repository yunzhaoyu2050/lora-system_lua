-- @info udp 服务器
local dgram = require("dgram")
local serverCfgInfo = require("../../server_cfg.lua")
local logger = require("../log.lua")

local udp = {
  ip = nil,
  port = nil,
  socket = nil,
  type = nil
}
-- udp 初始化
-- @param port 端口
-- @param ip 地址
-- @param type 类型
function udp.Init(port, ip, type)
  local sfiPort = serverCfgInfo.GetUdpPort()
  local sfiIp = serverCfgInfo.GetUdpIp()
  if port == nil then
    if sfiPort ~= nil then
      port = sfiPort
    else
      port = 12234
    end
  end
  if ip == nil then
    if sfiIp ~= nil then
      ip = sfiIp
    else
      ip = "127.0.0.1"
    end
  end
  if type == nil then
    type = "udp4"
  end
  udp.ip = ip
  udp.port = port
  udp.type = type
  udp.socket = dgram.createSocket(udp.type)
  udp.socket:bind(udp.port, udp.ip)
  udp.socket:on(
    "error",
    function(err)
      if err ~= nil then
        p(err)
      end
    end
  )
  logger.info("udp server ip: " .. udp.ip .. ",port: " .. udp.port)
end
-- 发送消息
-- @param msg 要发送的消息
function udp.Send(msg, cliInfo)
  if msg == nil then
    logger.error("msg is nil.")
  else
    udp.socket:send(
      msg,
      cliInfo.port,
      cliInfo.ip,
      function(err)
        if err ~= nil then
          p(err .. ", msg:" .. msg)
        end
      end
    )
  end
end
-- udp关闭
function udp.Close()
  udp.socket:close(
    function(err)
    end
  )
  logger.info("udp ip:" .. udp.ip .. "port:" .. udp.port .. "close.")
end
return udp
