local log_file = require "../deps/lualogging/src/logging/rolling_file.lua"
local log_console = require "../deps/lualogging/src/logging/console.lua"
-- local log_sock = require "../deps/lualogging/src/logging/socket.lua"
local scfg = require("../server_cfg.lua")
local log = require("core").Object:extend()

local max_size = 1024 * 1024 * 2 -- 2M
local max_index = 50
local total_log_size = max_size * max_index -- more than needed because of the log pattern

-- 解析输出类型
-- @param type 源
-- @return 解析错误码，类型，句柄
function log:parse_out_type(type)
  -- e.g, terminal, file@runlog.log, net@127.0.0.1:5001,
  -- if type == nil then
  --     return -1
  -- end
  if string.find(type, "terminal", 1) then
    self.type = "terminal"
    self.path = type
    return 0, "terminal", log_console()
  elseif string.find(type, "file", 1) then
    local file_name = string.match(type, "file@(%s+)")
    if file_name == nil then
      file_name = "runlog.log" -- 默认文件名称为runlog.log
    end
    if scfg.GerLogPath() ~= nil then
      self.path = scfg.GerLogPath() .. "/" .. file_name
    else
      self.path = "./" .. file_name -- 默认为本地目录下
    end
    self.type = "file"
    return 0, "file", log_file(self.path, max_size, max_index)
  elseif string.find(type, "net", 1) then
    local addr, port = string.match(type, "file@(%s+):(%d+)")
    if addr == nil then
      addr = "127.0.0.1"
    end
    if port == nil then
      port = 5001
    end
    self.type = "net"
    self.path = "net" .. "@" .. addr .. ":" .. port
    return 0, "net", log_sock(addr, port)
  else
    return -1, -1
  end
end

-- log init.
-- TODO:文件夹创建.日志文件创建.日志压缩
function log:initialize()
  self.log_filepath = nil
  self.type = nil
  self.log_path = nil
  self.print = nil
  if scfg ~= nil then
    if scfg.GerLogOutType() ~= nil then
      local ret, type, handle = log:parse_out_type(scfg.GerLogOutType())
      if handle == nil or ret < 0 then
        p("handle == nil")
        return 
      end
      self.print = handle
      -- "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
      if scfg.GerLogLevel() ~= nil then
        if scfg.GerLogLevel() == "INFO" then
          self.print:setLevel("INFO")
        elseif scfg.GerLogLevel() == "DEBUG" then
          self.print:setLevel("DEBUG")
        elseif scfg.GerLogLevel() == "WARN" then
          self.print:setLevel("WARN")
        elseif scfg.GerLogLevel() == "ERROR" then
          self.print:setLevel("ERROR")
        elseif scfg.GerLogLevel() == "FATAL" then
          self.print:setLevel("FATAL")
        end
      else
        self.print:setLevel("ERROR")
      end
      return 
    else
      p("please config log_out_type.")
      return 
    end
  end
  return 
end

local _logger = {}

function _logger.init()
  _logger.logger = log:new()
  return 0
end

function _logger.info(...)
  return _logger.logger.print:info(...)
end


function _logger.debug(...)
  return _logger.logger.print:debug(...)
end

function _logger.error(...)
  return _logger.logger.print:error(...)
end

function _logger.warn(...)
  return _logger.logger.print:warn(...)
end
-- e.g
-- log.print:info("logging.console test")
-- log.print:debug("debugging...")
-- log.print:error("error!")
-- log.print:debug("string with %4")
-- log.print:setLevel("INFO") -- test log level change warning.
return _logger
