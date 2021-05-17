local DeviceInfoRedis = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local DeviceInfoMysql = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local DeviceRoutingMysql = require("../lora-lib/models/MySQLModels/DeviceRouting.lua")
local DeviceConfigMysql = require("../lora-lib/models/MySQLModels/DeviceConfig.lua")
local basexx = require("../../deps/basexx/lib/basexx.lua")
-- local base64x = require("../../utiles/base64.lua")
local macCmdParser = require("./MACCmdParser.lua")
local consts = require("../lora-lib/constants/constants.lua")
local phyUtils = require("./phyUtils.lua")
local joinHandler = require("./joinHandler.lua")
local buffer = require("buffer").Buffer
local bit = require("bit")
-- local ffi = require("ffi")
local utiles = require("../../utiles/utiles.lua")

-- @info phyLayer层解析
-- Instance methods

-- 解析FCtrl
local function fctrlParser(fctrl)
  -- 上行消息如下:
  -- Bit#         7    6       5   4  [3..0]
  -- FCtrl bits ADR ADRACKReq ACK RFU FOptsLen
  local ADR = bit.rshift(fctrl, consts.FC_ADR_OFFSET)
  local ADRACKReq =
    bit.rshift(
    bit.band(fctrl, utiles.CalcVersusValue(consts.FC_ADRACKREQ_OFFSET, consts.ADRACKREQ_LEN)),
    consts.FC_ADRACKREQ_OFFSET
  )
  local ACK =
    bit.rshift(bit.band(fctrl, utiles.CalcVersusValue(consts.FC_ACK_OFFSET, consts.ACK_LEN)), consts.FC_ACK_OFFSET)
  local ClassB =
    bit.rshift(
    bit.band(fctrl, utiles.CalcVersusValue(consts.FC_CLASSB_OFFSET, consts.CLASSB_LEN)),
    consts.FC_CLASSB_OFFSET
  )
  local FOptsLen =
    bit.rshift(
    bit.band(fctrl, utiles.CalcVersusValue(consts.FC_FOPTSLEN_OFFSET, consts.FOPTSLEN)),
    consts.FC_FOPTSLEN_OFFSET
  )
  return {ADR = ADR, ADRACKReq = ADRACKReq, ACK = ACK, ClassB = ClassB, FOptsLen = FOptsLen}
end

-- Parse FHDR from MAC Payload, variable length
-- 解析FHDR
local function fhdrParser(macPayload)
  if macPayload == nil then
    p("macPayload is nil")
    return nil
  end
  -- slice(macPayload, consts.MP_DEVADDR_OFFSET, consts.MP_DEVADDR_END);
  local DevAddr = utiles.BufferSlice(macPayload, consts.MP_DEVADDR_OFFSET + 1, consts.MP_DEVADDR_END)
  DevAddr = utiles.BEToLE(DevAddr)
  p("   DevAddr:", utiles.BufferToHexString(DevAddr))
  local FCtrl = macPayload:readUInt8(consts.MP_FCTRL_OFFSET + 1)
  local FCtrlJSON = fctrlParser(FCtrl)
  local FCnt = utiles.BufferSlice(macPayload, consts.MP_FCNT_OFFSET + 1, consts.MP_FCNT_END)
  FCnt = utiles.BEToLE(FCnt)
  p("   FCnt:", utiles.BufferToHexString(FCnt))

  local FOpts = {}
  if FCtrlJSON.FOptsLen > 0 then
    local fhdrEnd = consts.MP_FOPTS_OFFSET + 1 + FCtrlJSON.FOptsLen
    local FOptsBuf = utiles.BufferSlice(macPayload, consts.MP_FOPTS_OFFSET + 1, fhdrEnd)
    FOptsBuf = utiles.BEToLE(FOptsBuf)
    p("   FOptsBuf:", utiles.BufferToHexString(FOptsBuf))
    -- mac cmd解析 FOpts中携带mac命令序列的情况下
    local FOptsJson = macCmdParser.parser(FOptsBuf)
    if FOptsJson == nil then
      p("macCmdParser.parser failed")
      return nil
    end
    if FOptsJson.ansLen > consts.FOPTS_MAXLEN then
      p("Invalid length of Request MACCommand in FOpts")
      return nil
    end
    FOpts = FOptsJson.cmdArr
  else
    p("   FCtrlJSON.FOptsLen = 0")
    FOpts = {}
  end

  return {
    DevAddr = DevAddr,
    FCtrl = FCtrlJSON,
    FCnt = FCnt,
    FOpts = FOpts
  }
end

-- macPayload层解析
-- @param macPayload buffer类型数据
function macPayloadParser(macPayload)
  if macPayload == nil then
    p("macPayload is nil")
    return nil
  end
  p("   macPayload:", utiles.BufferToHexString(macPayload))
  local macPayloadLen = macPayload.length
  local fhdrJSON = fhdrParser(macPayload) -- fhdr字段解析
  if fhdrJSON == nil then
    p("fhdr Parser failed")
    return nil
  end
  local fhdrEnd = 0
  if fhdrJSON.FCtrl.FOptsLen > 0 then
    fhdrEnd = consts.MP_FOPTS_OFFSET + fhdrJSON.FCtrl.FOptsLen
  else
    fhdrEnd = consts.MP_FOPTS_OFFSET
  end
  local fhdr = utiles.BufferSlice(macPayload, consts.MP_FHDR_OFFSET + 1, fhdrEnd)
  p("   fhdr:", utiles.BufferToHexString(fhdr))
  local macPayloadJSON = {
    fhdr = fhdr, -- 原始数据
    fhdrJSON = fhdrJSON -- 解析后的数据
  }
  -- Check if these is any FPort
  if fhdrEnd == macPayloadLen then -- 不是macplay的消息
    -- 此处有可能是其他的消息
    -- No FPort and FRMPayload
    p(" No FPort and FRMPayload")
    return macPayloadJSON
  else
    if fhdrEnd > macPayloadLen then -- 出错
      p("Insufficient length of FOpts, the package is ignored")
      return nil
    else
      local FRMPayloadOffset = fhdrEnd + consts.FPORT_LEN
      local FPort = utiles.BufferSlice(macPayload, fhdrEnd + 1, FRMPayloadOffset)
      p("   FPort:",  utiles.BufferToHexString(FPort))
      local FRMPayload = nil
      if FRMPayloadOffset == macPayload.length then
        FRMPayload = buffer:new(0)
      else
        FRMPayload = utiles.BufferSlice(macPayload, FRMPayloadOffset, macPayload.length)
      end
      FRMPayload = utiles.BufferSlice(macPayload, FRMPayloadOffset + 1, macPayload.length)
      p("   FRMPayload:", utiles.BufferToHexString(FRMPayload))
      if FRMPayload.length <= 0 then -- 出错
        p("FRMPayload must not be empty if FPort is given")
        return nil
      end
      -- 解析成功
      macPayloadJSON.FPort = FPort
      macPayloadJSON.FRMPayload = FRMPayload
      return macPayloadJSON
    end
  end
end

-- Parse MType, Major from MHDR
-- @param mhdr 解析数据
-- @return MType Major
local function mhdrParser(mhdr)
  local MType = bit.rshift(mhdr, consts.MTYPE_OFFSET)
  local Major =
    bit.rshift(bit.band(mhdr, utiles.CalcVersusValue(consts.MAJOR_OFFSET, consts.MAJOR_LEN)), consts.MAJOR_OFFSET)
  return {
    MType = MType,
    Major = Major
  }
end

-- Parse MHDR, MACPayload and MIC from physical payload
-- Join Request
-- @param phyPayload buffer类型数据
local function phyPayloadParser(phyPayload)
  p("   phyPayload:", utiles.BufferToHexString(phyPayload))
  local phyLen = phyPayload.length
  local mhdr = utiles.BufferSlice(phyPayload, consts.MHDR_OFFSET + 1, consts.MHDR_LEN)
  -- MAC layer MAC头(MHDR字段)
  local mhdrJSON = mhdrParser(mhdr:readUInt8(1))
  local macPayloadLen = phyLen - consts.MHDR_LEN - consts.MIC_LEN
  local MIC_OFFSET = consts.MACPAYLOAD_OFFSET + 1 + macPayloadLen - 1
  local macPayload = utiles.BufferSlice(phyPayload, consts.MACPAYLOAD_OFFSET + 1, MIC_OFFSET)
  local mic = utiles.BufferSlice(phyPayload, MIC_OFFSET + 1)

  return {
    mhdr = mhdr,
    mhdrJSON = mhdrJSON,
    macPayload = macPayload,
    mic = mic
  }
end

-- 从缓存中读取DeviceInfo
local function getAndCacheDeviceInfo(DevAddr, queryAttributes)
  if DevAddr == nil or queryAttributes == nil then
    p("DevAddr is nil or queryAttributes is nil")
    return nil
  end
  local res = DeviceInfoRedis.readItem({DevAddr = DevAddr}, queryAttributes) -- 从redis中读取
  if res ~= nil then
    if res.NwkSKey == nil then -- 不存在
      local devInfo = {}
      res = DeviceInfoMysql.readItem({DevAddr = DevAddr}, consts.DEVICEINFO_CACHE_ATTRIBUTES) -- 从mysql中读取
      if res.AppKey == nil or res.AppEUI == nil then -- 没有AppEUI或者没有AppKey 则出错
        p("The Device was not registered in LoRa web")
        return nil
      end
      if res.NwkSKey == nil or res.AppSKey == nil then -- 没有NwkSKey或者没有AppSKey 则出错
        p("The OTAA Device was not registered through the join process")
        return nil
      end
      -- DeviceRoutingMysql
      for k, v in pairs(res) do
        devInfo[k] = v
      end
      res = DeviceRoutingMysql.readItem({DevAddr = DevAddr}, consts.DEVICEROUTING_CACHE_ATTRIBUTES)
      -- DeviceConfigMysql
      for k, v in pairs(res) do
        devInfo[k] = v
      end
      res = DeviceConfigMysql.readItem({DevAddr = DevAddr}, consts.DEVICECONFIG_CACHE_ATTRIBUTES)
      -- DeviceInfoRedis
      for k, v in pairs(res) do
        devInfo[k] = v
      end
      res = DeviceInfoRedis.UpdateItem(DevAddr.DevAddr, devInfo) -- 更新所有的值,并添加不存在的值
      local resTmp = {
        NwkSKey = devInfo.NwkSKey,
        AppSKey = devInfo.AppSKey
      }
      return resTmp
    else -- 存在直接返回
      return res
    end
  else
    p("DeviceInfoRedis readItem failed")
    return res
  end
end

-- MIC值验证
local function macPayloadMICVerify(requiredFields, values, direction, phyPayloadJSON)
  if values == nil or requiredFields == nil or direction == nil or phyPayloadJSON == nil then
    p("inputs is nil")
    return nil
  end
  if values.NwkSKey == nil then
    p("The device was not registered in LoRa web")
    return nil
  end

  -- local requiredFieldsTmp = 

  local recvMic = utiles.BufferToHexString(phyPayloadJSON.mic)
  local NwkSKey = values.NwkSKey
  local micCal = phyUtils.micCalculator(requiredFields, NwkSKey, direction) -- mic计算
  micCal = utiles.BufferToHexString(micCal)
  p("   recv mic:", recvMic)
  p("   calc mic:", micCal)
  if micCal == recvMic then
    -- MIC verification passing
    p(" MIC verification passing")
    return values
  else
    p("MACPayload MIC mismatch")
    return nil
  end
end

-- 解析FRMPayload字段
function decryptFRMPayload(values, phyPayloadJSON, macPayloadJSON, requiredFields, direction)
  if values == nil or phyPayloadJSON == nil or macPayloadJSON == nil or requiredFields == nil or direction == nil then
    return nil
  end
  local key
  local result = {
    MHDR = phyPayloadJSON.mhdrJSON,
    MACPayload = {
      FHDR = macPayloadJSON.fhdrJSON
    }
  }
  if macPayloadJSON.FPort ~= nil then
    result.MACPayload.FPort = macPayloadJSON.FPort
  end
  if requiredFields.FRMPayload == nil then
    result.MACPayload.FRMPayload = buffer:new(0)
    return result
  else
    if macPayloadJSON.FPort:readUInt8(1) == 0 then
      key = values.NwkSKey
    else
      key = values.AppSKey
    end
    -- 需要通过key去解密
    local framePayload = phyUtils.decrypt(requiredFields, key, direction) -- 解密framePayload数据
    result.MACPayload.FRMPayload = framePayload
    
    if (macPayloadJSON.FPort:readUInt8(1) == consts.MACCOMMANDPORT:readUInt8(1)) then
      -- FPort值为0表示FRMPayload为MAC指令，非0则标志FRMPayload为业务数据。
      -- 当FOptsLen为非0值时，FPort也只能为非0值，不允许同时在FOpts和FRMPayload都有MAC指令
      p("   is mac data.")
      if macPayloadJSON.fhdrJSON.FCtrl.FOptsLen > 0 then
        p("MAC Commands are present in the FOpts field, the FPort 0 cannot be used")
        return -2
      else
        -- MAC指令
        result.MACPayload.FRMPayload = macCmdParser.parser(framePayload).cmdArr
      end
    else
      p("   is app data.")
    end
    -- 业务数据
    return result
  end
end

-- phyLayer层解析
-- @param phyPayloadRaw json解析过的data数据
-- @return 失败: nil
function parser(phyPayloadRaw)
  p("PHYPayload data parser...")
  if phyPayloadRaw == nil then
    p("phyPayloadRaw is nil")
    return nil
  end
  local tmp = basexx.from_base64(phyPayloadRaw) -- base64 to string
  local phyPayload = buffer:new(tmp)
  p("   phyPayload base64:", phyPayload:toString())
  local phyPayloadJSON = phyPayloadParser(phyPayload)

  -- 判断Data message type
  -- MType 描述
  -- 000 Join Request
  -- 001 Join Accept
  -- 010 Unconfirmed Data Up
  -- 011 Unconfirmed Data Down
  -- 100 Confirmed Data Up
  -- 101 Confirmed Data Down
  -- 110 RFU
  -- 111 Proprietary
  if
    consts.NS_MSG_TYPE_LIST[phyPayloadJSON.mhdrJSON.MType + 1] > -1 and
      consts.NS_MSG_TYPE_LIST[phyPayloadJSON.mhdrJSON.MType + 1] ~= consts.JOIN_REQ
   then -- 非Join Request消息
    if phyPayload.length < consts.MIN_PHYPAYLOAD_LEN then
      p("Insufficient length of PHYPayload, greater than ${consts.MIN_PHYPAYLOAD_LEN} bytes is mandatory")
      return nil
    end
    local direction = buffer:new(consts.DIRECTION_LEN)
    direction[1] = consts.BLOCK_DIR_CLASS.Up

    local macPayloadJSON = macPayloadParser(phyPayloadJSON.macPayload)
    if macPayloadJSON == nil then
      return nil
    end
    -- macPayloadJSON.fhdrJSON.DevAddr[1] = 0
    utiles.printBuf(macPayloadJSON.fhdrJSON.DevAddr)
    -- MIC verification mic计算需要使用的参数
    local requiredFields = {
      MHDR = phyPayloadJSON.mhdr,
      FHDR = macPayloadJSON.fhdr,
      DevAddr = macPayloadJSON.fhdrJSON.DevAddr,
      FCnt = macPayloadJSON.fhdrJSON.FCnt
    }
    if macPayloadJSON.FPort then
      requiredFields.FPort = macPayloadJSON.FPort
      requiredFields.FRMPayload = macPayloadJSON.FRMPayload
    end

    local queryAttributes = {"NwkSKey", "AppSKey"}
    local res = getAndCacheDeviceInfo(utiles.BufferToHexString(requiredFields.DevAddr), queryAttributes)
    if res == nil then
      return nil
    end
    -- macPayload层mic校验
    res = macPayloadMICVerify(requiredFields, res, direction, phyPayloadJSON)
    if res == nil then
      return nil
    end
    -- 解密FRMPayload层
    return decryptFRMPayload(res, phyPayloadJSON, macPayloadJSON, requiredFields, direction)
  elseif consts.JS_MSG_TYPE_LIST[phyPayloadJSON.mhdrJSON.MType + 1] == consts.JOIN_REQ then -- Join Request消息
    if phyPayloadJSON.macPayload.length ~= consts.JOINREQ_BASIC_LENGTH then -- 出错
      p("Invalid length of JOIN request, ${consts.JOINREQ_BASIC_LENGTH} bytes is mandatory")
      return nil
    end
    return joinHandler.parser(phyPayloadJSON) -- Join Request消息解析
  else -- 出错
    p("nvalid message type, one of [0, 2, 4] is mandatory")
    return -4
  end
end

return {
  parser = parser
}
