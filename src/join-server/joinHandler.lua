local consts = require("../lora-lib/constants/constants.lua")
local DeviceConfig = require("../lora-lib/models/MySQLModels/DeviceConfig.lua")
local DeviceInfo = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles/utiles.lua")
local bit = require("bit")
local crypto = require("../../deps/lua-openssl/lib/crypto.lua")

function DLSettingsPackager(RX1DRoffset, RX2DR)
  local OptNeg = 1
  local DLSettings = buffer:new(consts.DLSETTINGS_LEN)
  DLSettings = utiles.bitwiseAssigner(DLSettings, consts.OPTNEG_OFFSET, consts.OPTNEG_LEN, OptNeg)
  DLSettings = utiles.bitwiseAssigner(DLSettings, consts.RX1DROFFSET_OFFSET, consts.RX1DROFFSET_LEN, RX1DRoffset)
  DLSettings = utiles.bitwiseAssigner(DLSettings, consts.RX2DR_OFFSET, consts.RX2DR_LEN, RX2DR)
  return DLSettings
end

function RxDelayPackager(RxDelay, delay)
  utiles.bitwiseAssigner(RxDelay, consts.RXDELAY_BITOFFSET, consts.RXDELAY_BITLEN, delay)
end

local _AppKey
local _DevAddr
local _DLSettings
local _RxDelay
local _acpt
local _AppNonce
local _NetID
local _defaultConf

-- Class methods or Static methods 
-- 生成devaddr
local function genDevAddr(AppEUI, DevEUI, NwkID)
  local hash = crypto.createHash(consts.HASH_METHOD);
  -- local eui = Buffer.concat([AppEUI, DevEUI], consts.APPEUI_LEN + consts.DEVEUI_LEN);
  -- local devAddr = hash.update(eui).digest().slice(0, consts.DEVADDR_LEN - 1);
  -- return Buffer.concat([NwkID, devAddr]);
end

function genSKey(AppKey, nonce, type)
  local sessionBuf = buffer:new(consts.BLOCK_LEN)
  type = type or "NWK"
  if type == "NWK" then
    sessionBuf[0] = 0x01
  elseif type == "APP" then
    sessionBuf[0] = 0x02
  end
  local appnonce = utiles.reverse(nonce.AppNonce)
  local netid = utiles.reverse(nonce.NetID)
  local devnonce = utiles.reverse(nonce.DevNonce)
  utiles.BufferWrite(sessionBuf, consts.SK_APPNONCE_OFFSET, appnonce, consts.APPNONCE_LEN)
  utiles.BufferWrite(sessionBuf, consts.SK_NETID_OFFSET, netid, consts.NETID_LEN)
  utiles.BufferWrite(sessionBuf, consts.SK_DEVNONCE_OFFSET, devnonce, consts.DEVNONCE_LEN)
  local iv = "" --crypto.randomBytes(consts.IV_LEN);
  local sessionKey = crypto.encrypt(consts.ENCRYPTION_AES128, sessionBuf, AppKey, iv) -- 加密
  return sessionKey
end

function joinAcptPHYPackager(joinAcpt)
  local MHDR = {
    MType = consts.JOIN_ACCEPT,
    Major = consts.MAJOR_DEFAULT
  }
  local micPayloadJSON = joinAcpt
  micPayloadJSON.MHDR = MHDR
  return {
    MHDR = MHDR,
    MACPayload = joinAcpt,
    DevAddr = joinAcpt.DevAddr
  }
end

local function readDevice(queryOpt)
  local attributes = {
    "DevAddr",
    "AppKey"
  }
  local res = DeviceInfo.readItem(queryOpt, attributes) -- MySQLModels DeviceInfo
  if res.AppKey then
    _AppKey = res.AppKey
    return res
  else
    p("Device not registered on LoRa web server")
    return nil
  end
end

function genAcpt(joinReq, DLSettings, RxDelay)
  -- //CFLIST TODO
  local joinAcpt = {
    AppNonce = _AppNonce,
    NetID = _NetID,
    DevAddr = _DevAddr,
    DLSettings = DLSettings,
    RxDelay = RxDelay
    -- // CFList: this.defaultConf.CFList,
  }
  local nonce = {
    DevNonce = joinReq.DevNonce,
    AppNonce = _AppNonce,
    NetID = _NetID
  }
  local NwkSKey = genSKey(_AppKey, nonce, "NWK")
  local AppSKey = genSKey(_AppKey, nonce, "APP")
  local sKey = {
    NwkSKey = NwkSKey,
    AppSKey = AppSKey
  }
  joinAcpt.sKey = sKey
  return joinAcpt
end

local function getFreqPlan(freq, freqList)
  if freq >= freqList[1] and freq < freqList[2] then
    return freqList[1]
  elseif freq >= freqList[2] and freq < freqList[3] then
    return freqList[2]
  elseif freq >= freqList[3] and freq < freqList[4] then
    return freqList[3]
  elseif freq >= freqList[4] then
    return freqList[4]
  else
    p("freq is not int freqList", freq)
    return nil
  end
end

-- join server模块 join请求处理
function handler(rxpk)
  local joinReqPayload = rxpk.data
  local freq = rxpk.freq
  -- Check the length of join request
  -- const requiredLength = consts.APPEUI_LEN + consts.DEVEUI_LEN + consts.DEVNONCE_LEN;
  -- const receivedLength = joinReqPHYPayload.MACPayload.length;
  local joinReq = joinReqPayload[1]  -- joinReqPayload.MACPayload --TODO: 当前只能处理第一个消息
  local joinReqMHDR = joinReqPayload.MHDR
  local appKeyQueryOpt = {
    DevEUI = utiles.BufferToHexString(joinReq.DevEUI)
  }
  local _freqList = consts.FREQUENCY_PLAN_LIST;

  local frequencyPlan = getFreqPlan(freq, _freqList)
  _defaultConf = consts.DEFAULTCONF[frequencyPlan]
  -- Query the existance of DevEUI
  -- If so, process the rejoin procedure
  _AppNonce = math.random(consts.APPNONCE_LEN)
  -- Promises
  local rejoinProcedure = function(res) -- 重新入网处理
    if res.DevAddr == "" then -- 查看是否查询到 DevAddr
      _DevAddr = res.DevAddr
    else
      _DevAddr =
        genDevAddr(
        joinReq.AppEUI,
        joinReq.DevEUI,
        _NetID.slice(consts.NWKID_OFFSET, consts.NWKID_OFFSET + consts.NWKID_LEN)
      ) -- ??
    end
    return _DevAddr
  end
  local initDeviceConf = function(deviceConf)
    local query = {DevAddr = deviceConf.DevAddr}
    return DeviceConfig.UpdateItem(deviceConf, query)
  end
  local updateDevInfo = function(DevAddr)
    local RX1DRoffset = 4
    local RX2DR = 0
    local delay = 1
    _DLSettings = DLSettingsPackager(RX1DRoffset, RX2DR)
    _RxDelay = buffer:new(consts.RXDELAY_LEN)
    _RxDelay = RxDelayPackager(_RxDelay, delay)
    _acpt = genAcpt(joinReq, _DLSettings, _RxDelay)
    local deviceInfoUpd = {
      DevAddr = DevAddr,
      DevNonce = joinReq.DevNonce,
      AppNonce = _AppNonce,
      NwkSKey = _acpt.sKey.NwkSKey,
      AppSKey = _acpt.sKey.AppSKey
    }
    _acpt.sKey = nil
    _DevAddr = DevAddr
    _defaultConf.DevAddr = DevAddr
    _defaultConf.RX1DRoffset = RX1DRoffset
    DeviceInfo.UpdateItem(appKeyQueryOpt, deviceInfoUpd)
    initDeviceConf(_defaultConf)
    return -1
  end
  local returnAcptMsg = function()
    local acptPHY = joinAcptPHYPackager(_acpt)
    return acptPHY
  end
  local res = readDevice(appKeyQueryOpt)
  res = rejoinProcedure(res)
  res = updateDevInfo(res)
  res = returnAcptMsg()
  return res
end

return {
  handler = handler
}
