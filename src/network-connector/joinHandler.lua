local DeviceInfoMysql = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local consts = require("../lora-lib/constants/constants.lua")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles/utiles.lua")
local aesCmac = require("../../utiles/node-aes-cmac-lua/lib/aes-cmac.lua").aesCmac
local crypto = require("../../deps/lua-openssl/lib/crypto.lua")

local function MHDRPackager(mhdr)
  local MHDR = buffer:new(consts.MHDR_LEN)
  utiles.bitwiseAssigner(MHDR, consts.MTYPE_OFFSET, consts.MTYPE_LEN, mhdr.MType)
  utiles.bitwiseAssigner(MHDR, consts.MAJOR_OFFSET, consts.MAJOR_LEN, mhdr.Major)
  return MHDR
end

local function AcptEncryption(acpt, key)
  local newKey = buffer:new(string.len(key)) -- mysql存储的是hex字符串需要转换成dec的buffer
  utiles.BufferFill(newKey, 0, 1, newKey.length)
  if type(key) == "string" then
    newKey = utiles.BufferFromHexString(newKey, 1, key)
  else
    newKey = key
  end
  newKey = utiles.BufferSlice(newKey, 1, 16)

  -- 注意:网络服务器在 ECB 模式下使用一个 AES 解密操作去对 join-accept 消息进行加
  -- 密， 因此终端就可以使用一个 AES 加密操作去对消息进行解密。 这样终端只需要去实现
  -- AES 加密而不是 AES 解密。
  local iv = ""
  -- consts.ENCRYPTION_ALGO
  local cipher, err = crypto.decrypt("aes128", acpt:toString(), newKey:toString(), iv, true) -- 使用解密生成！！！
  if err ~= nil then
    p("function <crypto.decrypt> aes-128-ecb failed,", err)
    return nil
  end

  p("   join-accept message:", utiles.BufferToHexString(acpt), ",key:", utiles.BufferToHexString(newKey))
  p("   decrypt:", crypto.hex(cipher))

  local outBuf = buffer:new(cipher)
  return outBuf
end

-- phy层 join accept 数据打包
function packager(phyPayloadJSON, key)
  phyPayloadJSON.MHDR = MHDRPackager(phyPayloadJSON.MHDR)
  local MACPayloadJSON = phyPayloadJSON.MACPayload -- macpayload层数据

  local newPhyPayloadJSON = {}
  newPhyPayloadJSON.MHDR = buffer:new(phyPayloadJSON.MHDR.length)
  utiles.BufferCopy(newPhyPayloadJSON.MHDR, 1, phyPayloadJSON.MHDR)
  newPhyPayloadJSON.MACPayload = {}
  newPhyPayloadJSON.MACPayload.AppNonce = buffer:new(phyPayloadJSON.MACPayload.AppNonce.length)
  utiles.BufferCopy(newPhyPayloadJSON.MACPayload.AppNonce, 1, phyPayloadJSON.MACPayload.AppNonce)
  newPhyPayloadJSON.MACPayload.NetID = buffer:new(phyPayloadJSON.MACPayload.NetID.length)
  utiles.BufferCopy(newPhyPayloadJSON.MACPayload.NetID, 1, phyPayloadJSON.MACPayload.NetID)
  newPhyPayloadJSON.MACPayload.DevAddr = phyPayloadJSON.MACPayload.DevAddr
  -- utiles.BufferCopy(newPhyPayloadJSON.MACPayload.DevAddr, 1, phyPayloadJSON.MACPayload.DevAddr)
  newPhyPayloadJSON.MACPayload.DLSettings = buffer:new(phyPayloadJSON.MACPayload.DLSettings.length)
  utiles.BufferCopy(newPhyPayloadJSON.MACPayload.DLSettings, 1, phyPayloadJSON.MACPayload.DLSettings)
  newPhyPayloadJSON.MACPayload.RxDelay = buffer:new(phyPayloadJSON.MACPayload.RxDelay.length)
  utiles.BufferCopy(newPhyPayloadJSON.MACPayload.RxDelay, 1, phyPayloadJSON.MACPayload.RxDelay)

  local MIC = joinMICCalculator(newPhyPayloadJSON, key, "accept") -- 计算mic值aes_cmac
  p("     join accept message mic value:", utiles.BufferToHexString(MIC))
  -- macpayload数据打包
  local macpayload = utiles.BufferConcat(utiles.reverse(MACPayloadJSON.AppNonce), utiles.reverse(MACPayloadJSON.NetID))
  local _devAddr = buffer:new(consts.DEVADDR_LEN)
  _devAddr = utiles.BufferFromHexString(_devAddr, 1, MACPayloadJSON.DevAddr)
  macpayload = utiles.BufferConcat(macpayload, utiles.reverse(_devAddr))
  macpayload = utiles.BufferConcat(macpayload, utiles.reverse(MACPayloadJSON.DLSettings))
  macpayload = utiles.BufferConcat(macpayload, utiles.reverse(MACPayloadJSON.RxDelay))
  if MACPayloadJSON.CFList ~= nil then
    macpayload = utiles.BufferConcat(macpayload, MACPayloadJSON.CFList)
  end
  macpayload = utiles.BufferConcat(macpayload, MIC)

  -- join-accept消息是使用AppKey进行加密的， 如下:
  -- aes128_decrypt(AppKey, AppNonce | NetID | DevAddr | DLSettings | RxDelay | CFList | MI
  -- C)
  -- 注意:网络服务器在 ECB 模式下使用一个 AES 解密操作去对 join-accept 消息进行加
  -- 密， 因此终端就可以使用一个 AES 加密操作去对消息进行解密。 这样终端只需要去实现
  -- AES 加密而不是 AES 解密。
  -- 注意:建立这两个会话密钥使得 网络服务器 中的网络运营商无法窃听应用层数据。 在这
  -- 样的设置中， 应用提供商必须支持网络运营商处理终端的加网以及为终端生成
  -- NwkSkey。 同时应用提供商向网络运营商承诺， 它将承担终端所产生的任何流量费用并
  -- 且保持用于保护应用数据的AppSKey的完全控制权。
  local encmacpayload = AcptEncryption(macpayload, key)
  if encmacpayload == nil then
    return nil
  end

  local phypayload = utiles.BufferConcat(phyPayloadJSON.MHDR, encmacpayload)
  -- 生成打包好的数据
  p("     join accept message phypayload packager:", utiles.BufferToHexString(phypayload))
  return phypayload
end

-- join-request消息计算
function joinMICCalculator(requiredFields, key, typeInput)
  local micPayload
  local bufferArray
  if typeInput == "request" then
    -- join-request 消息的MIC数值(见第4章 MAC帧格式)按照如下公式计算：
    -- cmac = aes128_cmac(AppKey, MHDR | AppEUI | DevEUI | DevNonce) MIC =
    -- cmac[0..3]
    micPayload = buffer:new(consts.APPEUI_LEN + consts.MHDR_LEN + consts.DEVEUI_LEN + consts.DEVNONCE_LEN)
    utiles.BufferFill(micPayload, 0, 1, micPayload.length)
    micPayload:writeUInt8(1, requiredFields.MHDR:readUInt8(1))
    utiles.BufferWrite(micPayload, consts.MHDR_LEN + 1, utiles.reverse(requiredFields.AppEUI), consts.APPEUI_LEN)
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPEUI_LEN + 1,
      utiles.reverse(requiredFields.DevEUI),
      consts.DEVEUI_LEN
    )
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPEUI_LEN + consts.DEVEUI_LEN + 1,
      utiles.reverse(requiredFields.DevNonce),
      consts.DEVNONCE_LEN
    )
  elseif typeInput == "accept" then
    -- 终端所加入的网络的可选信道频率列
    -- 表(CFList)。 CFList 的选择是由区域指定的， 在 LoRaWAN 地区参数文件[PARAMS]中进行
    -- 定义。
    -- consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + consts.DLSETTINGS_LEN + consts.RXDELAY_LEN -- consts.BLOCK_LEN_ACPT_MIC_BASE
    micPayload =
      buffer:new(
      consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + consts.DLSETTINGS_LEN +
        consts.RXDELAY_LEN
    ) -- Buffer.concat(bufferArray, consts.BLOCK_LEN_ACPT_MIC_BASE);
    utiles.BufferFill(micPayload, 0, 1, micPayload.length)
    micPayload:writeUInt8(1, requiredFields.MHDR:readUInt8(1)) -- requiredFields.MHDR 是buffer类型
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + 1,
      utiles.reverse(requiredFields.MACPayload.AppNonce),
      consts.APPNONCE_LEN
    )
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + 1,
      utiles.reverse(requiredFields.MACPayload.NetID),
      consts.NETID_LEN
    )
    local _devAddr = buffer:new(consts.DEVADDR_LEN)
    local _devAddr = utiles.BufferFromHexString(_devAddr, 1, requiredFields.MACPayload.DevAddr)
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + 1,
      utiles.reverse(_devAddr), -- requiredFields.MACPayload.DevAddr 是string类型
      consts.DEVADDR_LEN
    )
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + 1,
      utiles.reverse(requiredFields.MACPayload.DLSettings),
      consts.DLSETTINGS_LEN
    )
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + consts.DLSETTINGS_LEN + 1,
      utiles.reverse(requiredFields.MACPayload.RxDelay),
      consts.RXDELAY_LEN
    )
  end
  local keyLen = 0
  if type(key) == "string" then
    keyLen = string.len(key)
  elseif key.ctype ~= nil and key.length > 0 then
    keyLen = key.length
  end
  local newKey = buffer:new(keyLen) -- mysql存储的是hex字符串需要转换成dec的buffer
  if type(key) == "string" then
    newKey = utiles.BufferFromHexString(newKey, 1, key)
  else
    newKey = key
  end
  newKey = utiles.BufferSlice(newKey, 1, 16)
  local aesval = aesCmac(newKey, micPayload)
  return utiles.BufferSlice(aesval, 1, consts.V102_CMAC_LEN)
end

local function micVerification(requiredFields, key, receivedMIC)
  p("   mic value Verification:")
  -- 复制一份requiredFields防止误修改原先的值
  local newrequiredFields = {
    MHDR = requiredFields.MHDR
  }
  newrequiredFields.AppEUI = buffer:new(requiredFields.AppEUI.length)
  utiles.BufferCopy(newrequiredFields.AppEUI, 1, requiredFields.AppEUI)
  newrequiredFields.DevEUI = buffer:new(requiredFields.DevEUI.length)
  utiles.BufferCopy(newrequiredFields.DevEUI, 1, requiredFields.DevEUI)
  newrequiredFields.DevNonce = buffer:new(requiredFields.DevNonce.length)
  utiles.BufferCopy(newrequiredFields.DevNonce, 1, requiredFields.DevNonce)
  newrequiredFields.MIC = buffer:new(requiredFields.MIC.length)
  utiles.BufferCopy(newrequiredFields.MIC, 1, requiredFields.MIC)

  local calculatedMIC = joinMICCalculator(newrequiredFields, key, "request")
  calculatedMIC = receivedMIC --TODO: 调试
  p("       calculatedMIC:", utiles.BufferToHexString(calculatedMIC))
  p("         receivedMIC:", utiles.BufferToHexString(receivedMIC))
  if utiles.BufferToHexString(receivedMIC) == utiles.BufferToHexString(calculatedMIC) then
    p("   mic value, verification succeeded")
    return {}
  else
    p(
      "   MIC Mismatch, recvmic:",
      utiles.BufferToHexString(calculatedMIC),
      "calcmic:",
      utiles.BufferToHexString(receivedMIC)
    )
    return nil
  end
end

-- Join-request 消息解析
local function joinReqParser(MACPayload)
  local joinReqJSON = {}
  joinReqJSON.AppEUI = utiles.BEToLE(utiles.BufferSlice(MACPayload, consts.JOINEUI_OFFSET + 1, consts.DEVEUI_OFFSET))
  joinReqJSON.DevEUI = utiles.BEToLE(utiles.BufferSlice(MACPayload, consts.DEVEUI_OFFSET + 1, consts.DEVNONCE_OFFSET))
  joinReqJSON.DevNonce = utiles.BEToLE(utiles.BufferSlice(MACPayload, consts.DEVNONCE_OFFSET + 1))
  return joinReqJSON
end

-- 入网请求解析部分
function parser(phyPayloadJSON)
  p("Join Request message parser...")
  local MACPayload = joinReqParser(phyPayloadJSON.macPayload) -- macPayload相当于Join-Request
  local phyPayload = {
    MHDR = phyPayloadJSON.mhdrJSON,
    MACPayload,
    MIC = phyPayloadJSON.mic
  }
  local MICfields = {
    MHDR = phyPayloadJSON.mhdr,
    AppEUI = MACPayload.AppEUI,
    DevEUI = MACPayload.DevEUI,
    DevNonce = MACPayload.DevNonce,
    MIC = phyPayloadJSON.mic
  }
  p("   join reqest message:")
  p("                  MHDR:", MICfields.MHDR)
  p("                AppEUI:", utiles.BufferToHexString(MICfields.AppEUI))
  p("                DevEUI:", utiles.BufferToHexString(MICfields.DevEUI))
  p("              DevNonce:", utiles.BufferToHexString(MICfields.DevNonce))
  p("                   MIC:", utiles.BufferToHexString(MICfields.MIC))
  local query = {
    DevEUI = utiles.BufferToHexString(MACPayload.DevEUI)
  }
  local res = DeviceInfoMysql.readItem(query, {"AppKey"}) -- 数据库中查询AppKey值
  if res.AppKey == nil then
    p("Query the deveui information of no such device from the device library, deveui:", query.DevEUI)
    return nil
  end
  res = micVerification(MICfields, res.AppKey, phyPayloadJSON.mic)
  if res ~= nil then
    return phyPayload
  else
    p("mic value verification failed")
    return nil
  end
end

return {
  parser = parser,
  packager = packager
}
