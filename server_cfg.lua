-- @info 服务器配置
local fs = require("fs")
local json = require("json")

local _cfi = {
  path = {
    data = nil
  },
  udp = {
    ip = nil,
    port = nil
  },
  log = {
    logLevel = nil,
    logOutType = nil,
    logPath = nil
  },
  simusql = {
    appInfosql_syncTime = nil,
    deviceInfosql_syncTime = nil,
    deviceConfigsql_syncTime = nil,
    deviceRoutingsql_syncTime = nil,
    gatewayInfosql_syncTime = nil
  },
  loraWan = {
    fcntCheckEnable = nil,
    downlinkDataDelay = nil,
    macInFrmpaylaodEnable = nil
  },
  gateWay = {
    cmdGatewwayTxPowe = nil,
    enableImme = nil,
    enableIpol = nil,
    enableNcrc = nil,
    enableRfch = nil
  }
}

local function _setConfigFile(tcfg)
  if tcfg == nil then
    p("tcfg is nil")
    return -1
  end
  _cfi.path.data = tcfg.path.data or "data/"
  _cfi.udp.port = tcfg.udp.port or 12234
  _cfi.udp.ip = tcfg.udp.ip or "127.0.0.1"
  _cfi.loraWan.fcntCheckEnable = tcfg.loraWan.fcntCheckEnable or true
  _cfi.loraWan.downlinkDataDelay = tcfg.loraWan.downlinkDataDelay or 200
  _cfi.loraWan.macInFrmpaylaodEnable = tcfg.loraWan.macInFrmpaylaodEnable or false
  _cfi.gateWay.cmdGatewwayTxPowe = tcfg.gateWay.cmdGatewwayTxPowe or 25
  _cfi.gateWay.enableImme = tcfg.gateWay.enableImme or false
  _cfi.gateWay.enableIpol = tcfg.gateWay.enableIpol or false
  _cfi.gateWay.enableNcrc = tcfg.gateWay.enableNcrc or false
  _cfi.gateWay.enableRfch = tcfg.gateWay.enableRfch or 0
  _cfi.log.logLevel = tcfg.log.logLevel or "INFO"
  _cfi.log.logOutType = tcfg.log.logOutType or "terminal"
  _cfi.log.logPath = tcfg.log.logPath or "./"
  _cfi.simusql.appInfosql_syncTime = tcfg.simusql.appInfosql_syncTime or 5000
  _cfi.simusql.deviceInfosql_syncTime = tcfg.simusql.deviceInfosql_syncTime or 5000
  _cfi.simusql.deviceConfigsql_syncTime = tcfg.simusql.deviceConfigsql_syncTime or 5000
  _cfi.simusql.deviceRoutingsql_syncTime = tcfg.simusql.deviceRoutingsql_syncTime or 5000
  _cfi.simusql.gatewayInfosql_syncTime = tcfg.simusql.gatewayInfosql_syncTime or 5000
  -- p(tcfg)
  -- p(_cfi)
  return 0
end

-- 程序配置文件解析
-- @param serCfgPath 程序配置文件路径
-- @return 成功：0 失败：-1
local function _serverCfgParse(serCfgPath)
  if serCfgPath == nil then
    p("serCfgPath is nil")
    return -1
  end
  local chunk, err = fs.readFileSync(serCfgPath)
  if err ~= nil or chunk == nil then
    p(err, chunk)
    return -1
  end
  local tmp = json.parse(chunk)
  local ret = _setConfigFile(tmp)
  if ret < 0 then
    return ret
  end
  return 0
end

function _init()
  local serCfgPath = "./config/config.json" -- 配置文件固定路径为程序执行路径下的config/文件夹中
  return _serverCfgParse(serCfgPath)
end

function _getDataPath()
  return _cfi.path.data
end

function _getUdpPort()
  return _cfi.udp.port
end

function _getUdpIp()
  return _cfi.udp.ip
end

function _getFcntCheckEnable()
  return _cfi.loraWan.fcntCheckEnable
end

function _getDownlinkDataDelay()
  return _cfi.loraWan.downlinkDataDelay
end

function _getCmdGatewwayTxPowe()
  return _cfi.gateWay.cmdGatewwayTxPowe
end

function _getEnableImme()
  return _cfi.gateWay.enableImme
end

function _getEnableIpol()
  return _cfi.gateWay.enableIpol
end

function _gerEnableNcrc()
  return _cfi.gateWay.enableNcrc
end

function _gerEnableRfch()
  return _cfi.gateWay.enableRfch
end

function _gerLogLevel()
  return _cfi.log.logLevel
end

function _gerLogOutType()
  return _cfi.log.logOutType
end

function _gerLogPath()
  return _cfi.log.logPath
end

function _getMacInFrmpaylaodEnable()
  return _cfi.loraWan.macInFrmpaylaodEnable
end

function _getAppInfosql_syncTime()
  return _cfi.simusql.appInfosql_syncTime
end

function _getDeviceInfosql_syncTime()
  return _cfi.simusql.deviceInfosql_syncTime
end

function _getDeviceConfigsql_syncTime()
  return _cfi.simusql.deviceConfigsql_syncTime
end

function _getDeviceRoutingsql_syncTime()
  return _cfi.simusql.deviceRoutingsql_syncTime
end

function _getGatewayInfosql_syncTime()
  return _cfi.simusql.gatewayInfosql_syncTime
end

return {
  Init = _init,
  GetDataPath = _getDataPath,
  GetUdpPort = _getUdpPort,
  GetUdpIp = _getUdpIp,
  GetFcntCheckEnable = _getFcntCheckEnable,
  GetDownlinkDataDelay = _getDownlinkDataDelay,
  GetCmdGatewwayTxPowe = _getCmdGatewwayTxPowe,
  GetEnableImme = _getEnableImme,
  GetEnableIpol = _getEnableIpol,
  GerEnableNcrc = _gerEnableNcrc,
  GerEnableRfch = _gerEnableRfch,
  GerLogLevel = _gerLogLevel,
  GerLogOutType = _gerLogOutType,
  GerLogPath = _gerLogPath,
  GetMacInFrmpaylaodEnable = _getMacInFrmpaylaodEnable,
  GetAppInfosql_syncTime = _getAppInfosql_syncTime,
  GetDeviceInfosql_syncTime = _getDeviceInfosql_syncTime,
  GetDeviceConfigsql_syncTime = _getDeviceConfigsql_syncTime,
  GetDeviceRoutingsql_syncTime = _getDeviceRoutingsql_syncTime,
  GetGatewayInfosql_syncTime = _getGatewayInfosql_syncTime
}
