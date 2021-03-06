local consts = require("../lora-lib/constants/constants.lua")
local mysqlDeviceConfig = require("../lora-lib/models/MySQLModels/DeviceConfig.lua")
local mysqlDeviceInfo = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles/utiles.lua")
-- local bit = require("bit")
local crypto = require("../../deps/lua-openssl/lib/crypto.lua")
local rand = crypto.rand
local logger = require("../log.lua")

-- local lcrypto = require("../../deps/luvit-github/deps/tls/lcrypto.lua")

-- DLSettings字段打包
-- @param
--    RX1DRoffset: 位域设置上行数据速率和RX1下行数据速率的偏移量。 默认情况下偏移量为
--    0（ 意思就是上行数据速率与下行数据速率相等)。 偏移量用于考虑一些地区的基站最大功率密
--    度限制和平衡上下行射频链路预算。
-- @param
--    RX2DR
local function DLSettingsPackager(OptNeg, RX1DRoffset, RX2DR)
  -- DLsettings字段包含了下行配置:
  -- Bits       7   6:4         3:0
  -- DLsettings RFU RX1DRoffset RX2Datarate
  local DLSettings = buffer:new(consts.DLSETTINGS_LEN)
  utiles.BufferFill(DLSettings, 0, 1, DLSettings.length)
  DLSettings = utiles.bitwiseAssigner(DLSettings, consts.OPTNEG_OFFSET, consts.OPTNEG_LEN, OptNeg)
  DLSettings = utiles.bitwiseAssigner(DLSettings, consts.RX1DROFFSET_OFFSET, consts.RX1DROFFSET_LEN, RX1DRoffset)
  DLSettings = utiles.bitwiseAssigner(DLSettings, consts.RX2DR_OFFSET, consts.RX2DR_LEN, RX2DR)
  return DLSettings
end

-- RxDelay打包
local function RxDelayPackager(RxDelay, delay)
  return utiles.bitwiseAssigner(RxDelay, consts.RXDELAY_BITOFFSET, consts.RXDELAY_BITLEN, delay)
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
  local digest = crypto.digest
  local hash = digest.new(consts.HASH_METHOD) -- md5
  local euiBuf = buffer:new(consts.APPEUI_LEN + consts.DEVEUI_LEN)
  utiles.BufferFill(euiBuf, 0, 1, euiBuf.length)
  utiles.BufferWrite(euiBuf, 1, AppEUI, consts.APPEUI_LEN)
  utiles.BufferWrite(euiBuf, consts.APPEUI_LEN + 1, DevEUI, consts.DEVEUI_LEN)
  local devAddr = hash:final(euiBuf:toString())
  -- 6.1.1 终端地址(DevAddr)
  -- 终端地址(DevAddr)由可标识当前网络设备的32位ID所组成， 具体格式如下：
  -- Bit# [31..25] [24..0]
  -- DevAddr bits NwkID NwkAddr
  -- 它的高7位是NwkId， 用来区别同一区域内的不同网络， 另外也保证防止节点窜到别的网络
  -- 去。 它的低25位是NwkAddr， 是终端的网络地址， 可以由网络管理者来分配。
  local newDevaddr = buffer:new(string.len(devAddr) / 2)
  newDevaddr = utiles.BufferFromHexString(newDevaddr, 1, devAddr)
  newDevaddr = utiles.BufferSlice(newDevaddr, 1, consts.DEVADDR_LEN - 1)
  return utiles.BufferConcat(NwkID, newDevaddr)
end

-- 生成会话密钥NwkSKey和AppSKey
local function genSKey(AppKey, nonce, inputType)
  local sessionBuf = buffer:new(consts.BLOCK_LEN)
  utiles.BufferFill(sessionBuf, 0, 1, sessionBuf.length)

  inputType = inputType or "NWK"
  if inputType == "NWK" then
    sessionBuf[1] = 0x01
  elseif inputType == "APP" then
    sessionBuf[1] = 0x02
  end

  local appnonce = utiles.reverse(nonce.AppNonce) -- 转换成网络字节序
  local netid = utiles.reverse(nonce.NetID)
  local devnonce = utiles.reverse(nonce.DevNonce)

  utiles.BufferWrite(sessionBuf, consts.SK_APPNONCE_OFFSET + 1, appnonce, consts.APPNONCE_LEN) -- 再将转换成网络字节序的数据打包成buffer
  utiles.BufferWrite(sessionBuf, consts.SK_NETID_OFFSET + 1, netid, consts.NETID_LEN)
  utiles.BufferWrite(sessionBuf, consts.SK_DEVNONCE_OFFSET + 1, devnonce, consts.DEVNONCE_LEN)

  local newKey = buffer:new(string.len(AppKey)) -- mysql存储的是hex字符串需要转换成dec的buffer
  utiles.BufferFill(newKey, 0, 1, newKey.length)
  if type(AppKey) == "string" then
    newKey = utiles.BufferFromHexString(newKey, 1, AppKey)
  else
    newKey = AppKey
  end
  newKey = utiles.BufferSlice(newKey, 1, 16)

  -- NwkSKey = aes128_encrypt(AppKey, 0x01 | AppNonce | NetID | DevNonce | pad 16 )
  -- AppSKey = aes128_encrypt(AppKey, 0x02 | AppNonce | NetID | DevNonce | pad 16 )

  local iv = "" --crypto.randomBytes(consts.IV_LEN);
  -- consts.ENCRYPTION_AES128
  local res = crypto.encrypt("aes128", sessionBuf:toString(), newKey:toString(), iv) -- aes128 ecb加密
  res = crypto.hex(res)
  local sessionKey = buffer:new(string.len(res) / 2)
  utiles.BufferFromHexString(sessionKey, 1, res)
  sessionKey = utiles.BufferSlice(sessionKey, 1, 16)
  return sessionKey
end

-- 粗打包 生成 join-accept
local function genAcpt(joinReq, DLSettings, RxDelay)
  -- CFLIST TODO
  local joinAcpt = {
    AppNonce = _AppNonce,
    NetID = _NetID,
    DevAddr = _DevAddr,
    DLSettings = DLSettings,
    RxDelay = RxDelay
    -- CFList: this.defaultConf.CFList,
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

-- join accept 数据打包
local function joinAcptPHYPackager(joinAcpt)
  local MHDR = {
    MType = consts.JOIN_ACCEPT,
    Major = consts.MAJOR_DEFAULT
  }
  -- local micPayloadJSON = joinAcpt
  -- micPayloadJSON.MHDR = MHDR
  -- local mhdrBuf = buffer:new(1)
  -- mhdrBuf = utiles.bitwiseAssigner(mhdrBuf, consts.MAJOR_OFFSET, consts.MAJOR_LEN, consts.MAJOR_DEFAULT)
  -- mhdrBuf = utiles.bitwiseAssigner(mhdrBuf, consts.MTYPE_OFFSET, consts.MTYPE_LEN, consts.JOIN_ACCEPT)
  -- micPayloadJSON.MHDR = mhdrBuf:readUInt8(1)
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
  local res = mysqlDeviceInfo.readItem(queryOpt, attributes) -- MySQLModels DeviceInfo
  if res.AppKey then
    _AppKey = res.AppKey
    return res
  else
    logger.error("Device not registered on LoRa web server")
    return nil
  end
end

-- join server模块 join请求流程 数据处理单元
function handler(rxpk)
  logger.info("join request message process...")
  local joinReqPayload = rxpk.data
  local freq = rxpk.freq
  -- Check the length of join request
  -- const requiredLength = consts.APPEUI_LEN + consts.DEVEUI_LEN + consts.DEVNONCE_LEN;
  -- const receivedLength = joinReqPHYPayload.MACPayload.length;
  local joinReq = joinReqPayload[1] -- joinReqPayload.MACPayload --TODO: 当前只能处理第一个消息
  local joinReqMHDR = joinReqPayload.MHDR
  local appKeyQueryOpt = {
    DevEUI = utiles.BufferToHexString(joinReq.DevEUI)
  }
  -- local _freqList = consts.FREQUENCY_PLAN_LIST

  local frequencyPlan = consts.GetISMFreqPLanOffset(freq)
  _defaultConf = consts.DEFAULTCONF[frequencyPlan]
  if _defaultConf == nil then
    logger.error("_defaultConf is nil")
    return nil
  end
  -- Query the existance of DevEUI
  -- If so, process the rejoin procedure

  local random = rand.bytes(consts.APPNONCE_LEN)
  _AppNonce = buffer:new(consts.APPNONCE_LEN)
  for i = 1, string.len(random), 1 do
    _AppNonce[i] = string.byte(i)
  end

  -- NetID的格式如下所述:NetID的7个最低有效位称为NwkID并且和之前所描述的终端的短地址
  -- 的7个最高有效位相对应。保留的17个最高有效位可以由网络运营商进行自由选择。
  _NetID = buffer:new(consts.NETID_LEN) -- TODO: netid
  utiles.BufferFill(_NetID, 0, 1, _NetID.length)

  -- Promises
  local rejoinProcedure = function(res) -- 重新入网处理
    if res.DevAddr ~= "" then -- 是否查询到DevAddr，否则重新生成一个
      -- 将字符串转成数组
      -- _DevAddr = buffer:new(consts.DEVADDR_LEN)
      -- _DevAddr = utiles.BufferFromHexString(_DevAddr, 1, res.DevAddr)
      _DevAddr = res.DevAddr
    else
      local tmpNetID = utiles.BufferSlice(_NetID, consts.NWKID_OFFSET + 1, consts.NWKID_OFFSET + consts.NWKID_LEN)
      _DevAddr = genDevAddr(joinReq.AppEUI, joinReq.DevEUI, tmpNetID)
    end
    return _DevAddr
  end

  local initDeviceConf = function(deviceConf) -- mysql设备配置信息更新
    local query = {DevAddr = deviceConf.DevAddr}
    return mysqlDeviceConfig.UpdateItem(query, deviceConf)
  end

  local updateDevInfo = function(DevAddr)
    local OptNeg = 0 -- 默认lorawan协议版本1.0版本
    local res =
      mysqlDeviceInfo.readItem({DevAddr = DevAddr}, {"ProtocolVersion", "RX1DRoffset", "RX1Delay", "RX2DataRate"})
    if res.ProtocolVersion ~= nil then
      if res.ProtocolVersion == "1.1" then
        OptNeg = 1
      end
    end

    local RX1DRoffset = 1 -- TODO: RX1DRoffset值写死需确定
    if res.RX1DRoffset ~= nil then
      RX1DRoffset = res.RX1DRoffset
    end
    local RX2DR = 0 -- TODO: RX2DR值写死需确定
    if res.RX2DataRate ~= nil then
      RX2DR = res.RX2DataRate
    end
    local delay = 1 -- TODO: delay值写死需确定
    if res.RX1Delay ~= nil  then
      RX2DR = res.RX1Delay
    end
    
    _DLSettings = DLSettingsPackager(OptNeg, RX1DRoffset, RX2DR)

    _RxDelay = buffer:new(consts.RXDELAY_LEN)
    utiles.BufferFill(_RxDelay, 0, 1, _RxDelay.length)
    _RxDelay = RxDelayPackager(_RxDelay, delay)

    _acpt = genAcpt(joinReq, _DLSettings, _RxDelay) -- 得到粗打包的数据

    local deviceInfoUpd = {
      -- mysql需要更新的内容
      DevAddr = DevAddr,
      DevNonce = utiles.BufferToHexString(joinReq.DevNonce),
      AppNonce = utiles.BufferToHexString(_AppNonce),
      NwkSKey = utiles.BufferToHexString(_acpt.sKey.NwkSKey),
      AppSKey = utiles.BufferToHexString(_acpt.sKey.AppSKey)
    }
    -- _acpt.sKey = nil -- TODO:
    logger.info("   update mysql deviceInfo:")
    logger.info({"                   DevAddr:", deviceInfoUpd.DevAddr})
    logger.info({"                  AppNonce:", deviceInfoUpd.AppNonce})
    logger.info({"                  DevNonce:", deviceInfoUpd.DevNonce})
    logger.info({"                   NwkSKey:", deviceInfoUpd.NwkSKey})
    logger.info({"                   AppSKey:", deviceInfoUpd.AppSKey})
    _DevAddr = DevAddr
    _defaultConf.DevAddr = DevAddr
    _defaultConf.RX1DRoffset = RX1DRoffset

    mysqlDeviceInfo.UpdateItem(appKeyQueryOpt, deviceInfoUpd) -- mysql设备信息更新

    return initDeviceConf(_defaultConf) -- mysql设备配置信息更新
  end

  local returnAcptMsg = function()
    local acptPHY = joinAcptPHYPackager(_acpt)
    logger.info("downstream data processing...")
    logger.info({"   join Acpt PHY Packager:", acptPHY})
    return acptPHY
  end

  -- main
  local res = readDevice(appKeyQueryOpt)
  if res == nil then
    return res
  end
  res = rejoinProcedure(res)
  res = updateDevInfo(res)
  if res < 0 then
    logger.error("updateDevInfo failed")
    return nil
  end
  res = returnAcptMsg()
  return res
end
return {
  handler = handler
}
