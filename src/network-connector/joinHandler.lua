local DeviceInfoMysql = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local consts = require("../lora-lib/constants/constants.lua")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles/utiles.lua")
local aesCmac = require("../../deps/node-aes-cmac-lua/lib/aes-cmac.lua").aesCmac

-- phy层打包数据
function packager(phyPayloadJSON, key)
  phyPayloadJSON.MHDR = MHDRPackager(phyPayloadJSON.MHDR)
  local MACPayloadJSON = phyPayloadJSON.MACPayload
  local MIC = joinMICCalculator(phyPayloadJSON, key, "accept")
  local macpayload =
    buffer.concat(
    {
      utiles.reverse(MACPayloadJSON.AppNonce),
      utiles.reverse(MACPayloadJSON.NetID),
      utiles.reverse(MACPayloadJSON.DevAddr),
      utiles.reverse(MACPayloadJSON.DLSettings),
      utiles.reverse(MACPayloadJSON.RxDelay)
    }
  )
  if MACPayloadJSON.CFList ~= nil then
    macpayload = buffer.concat({macpayload, MACPayloadJSON.CFList})
  end
  macpayload = buffer.concat({macpayload, MIC})
  local encmacpayload = AcptEncryption(macpayload, key)
  local phypayload = buffer.concat({phyPayloadJSON.MHDR, encmacpayload})
  return phypayload
end

function MHDRPackager(mhdr)
  local MHDR = buffer:new(consts.MHDR_LEN)
  utiles.bitwiseAssigner(MHDR, consts.MTYPE_OFFSET, consts.MTYPE_LEN, mhdr.MType)
  utiles.bitwiseAssigner(MHDR, consts.MAJOR_OFFSET, consts.MAJOR_LEN, mhdr.Major)
  return MHDR
end

function AcptEncryption(acpt, key)
  local iv = ""
  local cipher = crypto.createDecipheriv(consts.ENCRYPTION_ALGO, key, iv)
  cipher.setAutoPadding(false)
  return cipher.update(acpt)
end

-- @info Join-Request 消息解析

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
    micPayload:writeUInt8(1, requiredFields.MHDR)
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
    micPayload = buffer:new(consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + consts.DLSETTINGS_LEN + consts.RXDELAY_LEN) -- Buffer.concat(bufferArray, consts.BLOCK_LEN_ACPT_MIC_BASE);
    utiles.BufferFill(micPayload, 0, 1, micPayload.length)
    micPayload:writeUInt8(1, requiredFields.MHDR)
    utiles.BufferWrite(micPayload, consts.MHDR_LEN + 1, utiles.reverse(requiredFields.AppNonce), consts.APPNONCE_LEN)
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + 1,
      utiles.reverse(requiredFields.NetID),
      consts.NETID_LEN
    )
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + 1,
      utiles.reverse(requiredFields.DevAddr),
      consts.DEVADDR_LEN
    )
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + 1,
      utiles.reverse(requiredFields.DLSettings),
      consts.DLSETTINGS_LEN
    )
    utiles.BufferWrite(
      micPayload,
      consts.MHDR_LEN + consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + consts.DLSETTINGS_LEN + 1,
      utiles.reverse(requiredFields.RxDelay),
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
  p("calculatedMIC:", utiles.BufferToHexString(calculatedMIC))
  p("receivedMIC:", utiles.BufferToHexString(receivedMIC))
  if utiles.BufferToHexString(receivedMIC) == utiles.BufferToHexString(calculatedMIC) then
    p("mic value, verification succeeded")
    return {}
  else
    p(
      "MIC Mismatch, recvmic:",
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
  p("AppEUI:", utiles.BufferToHexString(MACPayload.AppEUI))
  p("DevEUI:", utiles.BufferToHexString(MACPayload.DevEUI))
  p("DevNonce:", utiles.BufferToHexString(MACPayload.DevNonce))
  local query = {
    DevEUI = utiles.BufferToHexString(MACPayload.DevEUI)
  }
  local attr = {"AppKey"}
  local res = DeviceInfoMysql.readItem(query, attr) -- 数据库中查询AppKey值
  if res.AppKey == nil then
    p("Query the deveui information of no such device from the device library, deveui:", query.DevEUI)
    return nil
  end
  res = micVerification(MICfields, res.AppKey, phyPayloadJSON.mic)
  if res ~= nil then
    return phyPayload
  else
    return nil
  end
end

return {
  parser = parser,
  packager = packager
}
