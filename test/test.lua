-- @info 测试

require("emmy_core").tcpListen("localhost", 9966)
p("debug open, listen: " .. "localhost" .. ",port: " .. 9966)

local serverCfgInfo = require("../server_cfg.lua")
local ret = serverCfgInfo.Init() -- 初始化 配置文件
if ret ~= 0 then
  p("server config info init failed.")
  return -1
end

local logger = require("../src/log.lua")
ret = logger.init()
if ret ~= 0 then
  p("logger.init failed.", ret)
  return -1
end

local consts = require("../src/lora-lib/constants/constants.lua")
ret = consts.Init() --初始化 固化参数
if ret ~= 0 then
  p("consts param init failed.")
  return -1
end

local devinfo = require("../src/lora-lib/models/RedisModels/DeviceInfo.lua")
local udp = require("../src/network-connector/udp.lua")
local udpLayer = require("../src/network-connector/udpHandler.lua")

local Module = require("../src/network-connector/connector.lua")
local model = require("../src/lora-lib/models/models.lua")
local serverModule = require("../src/network-server/server.lua")
local uv = require("luv")
-- local thread = require('thread')
uv.sleep(2000)

ret = model.Init() -- 初始化 存储模型
if ret ~= 0 then
  p("model init failed.")
  return -1
end
-- ret = mqHandle.Init() -- 消息通讯
ret = udp.Init() -- 初始化 udp服务
-- local connectorThread = thread.start(function()
-- local connectorModule = require('../network-connector/connector.lua')
-- ret = connectorModule.Task() -- connector模块 上行任务
-- logger.warn("test warn")
logger.info("start...")
ret = Module.Start()
-- end):join()
-- ret = connectorModule.Init() -- 初始化 connector模块
-- ret = serverModule.Init() -- 初始化 server模块
-- connectorModule.UplinkTask()
-- udp.socket:on("message", function(message, udpInfo)
--     p('rec: '..message)
-- end)

-- local thread = require('thread')
-- local serverThread
-- function _init()
--     serverThread = thread.start(function()
--         local mqHandle = require('../src/common/message_queue.lua')
--         local uv = require('luv')
--         while true do
--             local recvData = mqHandle.Subscription('ConnectorPubToServer')
--             if recvData ~= nil then
--                 p('child',thread.self())
--                 p(recvData)
--             else
--                 uv.sleep(math.random(1000))
--             end
--         end
--     end)
--     serverThread:join()
-- end
-- local step = 10
-- local uv = require('luv')
-- local hare_id = uv.new_thread(function(step,...)
--     local ffi = require'ffi'
--     local uv = require('luv')
--     local sleep
--     if ffi.os=='Windows' then
--         ffi.cdef "void Sleep(int ms);"
--         sleep = ffi.C.Sleep
--     else
--         ffi.cdef "unsigned int usleep(unsigned int seconds);"
--         sleep = ffi.C.usleep
--     end
--     while (true) do
--         step = step - 1
--         sleep(math.random(1000))
--         print("Hare ran another step")
--     end
--     print("Hare done running!")
-- end, step,true,'abcd','false')
-- uv.thread_join(hare_id)
