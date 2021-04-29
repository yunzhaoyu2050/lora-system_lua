
-- @info 服务器配置

local fs = require('fs')
local json = require('json')

local _cfi = {
    path = {
        data = nil,
    },
    udp = {
        ip = nil,
        port = nil,
    }
}

local function _setConfigFile(tcfg)
    if tcfg == nil then
        p('tcfg is nil')
        return -1
    end
    _cfi.path.data = tcfg.path.data or 'data/'
    _cfi.udp.port = tcfg.udp.port or 12234
    _cfi.udp.ip = tcfg.udp.ip or '127.0.0.1'
    return 0
end

-- 程序配置文件解析
-- @param serCfgPath 程序配置文件路径
-- @return 成功：0 失败：-1 
local function _serverCfgParse(serCfgPath)
    if serCfgPath == nil then
        p('serCfgPath is nil')
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

function _getDataPath()
    return _cfi.path.data
end

function _getUdpPort()
    return _cfi.udp.port
end

function _getUdpIp()
    return _cfi.udp.ip
end

function _init()
    local serCfgPath = './config/config.json'
    return _serverCfgParse(serCfgPath)
end

return {
    Init = _init,
    GetDataPath = _getDataPath,
    GetUdpPort = _getUdpPort,
    GetUdpIp = _getUdpIp,
}

