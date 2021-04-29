-- require("emmy_core").tcpListen("localhost", 9966)
-- p("debug open, listen: " .. "localhost" .. ",port: " .. 9966)

local consts = require("../src/lora-lib/constants/constants.lua")
local devinfo = require("../src/lora-lib/models/RedisModels/DeviceInfo.lua")
local udp = require("../src/network-connector/udp.lua")
local udpLayer = require("../src/network-connector/udpHandler.lua")
local serverCfgInfo = require("../server_cfg.lua")
local Module = require("../src/network-connector/connector.lua")
local model = require("../src/lora-lib/models/models.lua")
local serverModule = require("../src/network-server/server.lua")
-- local uv = require("luv")
-- uv.sleep(5000)
local ret = serverCfgInfo.Init() -- 初始化 配置文件
if ret ~=0 then
  p('server config info init failed.')
  return -1
end
ret = consts.Init() --初始化 固化参数
if ret ~=0 then
  p('consts param init failed.')
  return -1
end
ret = model.Init() -- 初始化 存储模型
if ret ~=0 then
  p('consts param init failed.')
  return -1
end
ret = udp.Init() -- 初始化 udp服务
p("start...")