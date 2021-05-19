local utiles = require("../../utiles/utiles.lua")
local phyUtils = require("./phyUtils.lua")
local MACCmdPackager = require("./MACCmdPackager.lua")
local MACPackager = MACCmdPackager
local assign = utiles.bitwiseAssigner
local consts = require("../lora-lib/constants/constants.lua")
local buffer = require("buffer").Buffer
local _deviceInfoMysql = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local joinHandler = require("./joinHandler.lua")
local logger = require("../log.lua")

function MHDRPackager(MHDRJSON)
  local MHDR = buffer:new(consts.MHDR_LEN)
  utiles.bitwiseAssigner(MHDR, consts.MTYPE_OFFSET, consts.MTYPE_LEN, MHDRJSON.MType)
  utiles.bitwiseAssigner(MHDR, consts.MAJOR_OFFSET, consts.MAJOR_LEN, MHDRJSON.Major)
  return MHDR
end

function FHDRPackager(FHDRJSON)
  local FHDR = buffer:new(consts.FHDR_LEN_BASE)
  local FCtrl = FCtrlPackager(FHDRJSON.FCtrl)
  local devaddr = utiles.BufferFrom(FHDRJSON.DevAddr)
  devaddr = utiles.reverse(devaddr)
  utiles.BufferCopy(FHDR, consts.MP_DEVADDR_OFFSET + 1, devaddr)
  FCtrl = utiles.reverse(FCtrl)
  utiles.BufferCopy(FHDR, consts.MP_FCTRL_OFFSET + 1, FCtrl)

  -- utiles.slice(FHDRJSON.FCnt, consts.FCNT_LEAST_OFFSET).copy(FHDR, consts.MP_FCNT_OFFSET)
  local FCnt  = utiles.reverse(FHDRJSON.FCnt)
  utiles.BufferCopy(FHDR, consts.MP_FCNT_OFFSET + 1, FCnt)

  logger.info({"FCntL:", utiles.BufferToHexString(FCnt)})
  -- utiles.printBuf(FHDR)

  if FHDRJSON.FCtrl.FOptsLen > 0 then
    local FOpts = MACPackager.packager(FHDRJSON.FOpts)
    FHDR = utiles.BufferConcat({FHDR, FOpts})
  end
  return FHDR
end

function FCtrlPackager(FCtrlJSON)
  local FCtrl = buffer:new(consts.FCTRL_LEN)
  if FCtrlJSON.ADR == true then
    FCtrlJSON.ADR = 1
  elseif FCtrlJSON.ADR == false then
    FCtrlJSON.ADR = 0
  else
    FCtrlJSON.ADR = 0
  end
  utiles.bitwiseAssigner(FCtrl, consts.FC_ADR_OFFSET, consts.ADR_LEN, FCtrlJSON.ADR)
  utiles.bitwiseAssigner(FCtrl, consts.FC_ACK_OFFSET, consts.ACK_LEN, FCtrlJSON.ACK)
  utiles.bitwiseAssigner(FCtrl, consts.FC_FPENDING_OFFSET, consts.FPENDING_LEN, FCtrlJSON.FPending)
  utiles.bitwiseAssigner(FCtrl, consts.FC_FOPTSLEN_OFFSET, consts.FOPTSLEN, FCtrlJSON.FOptsLen)
  return FCtrl
end

-- phy层细打包
function packager(phyPayloadJSON)
  logger.info("   phypayload packager...")
  local MType = phyPayloadJSON.MHDR.MType
  local MACPayload = phyPayloadJSON.MACPayload
  local MHDR
  local FHDR

  -- const MType = utils.bitwiseFilter(phyPayloadJSON.MHDR, consts.MTYPE_OFFSET, consts.MTYPE_LEN);
  local FIRMED_DATA_DOWN = function()
    -- 配置下发数据
    if MACPayload.FPort:readUInt8(1) ~= 0 then
      MACPayload.FPort = buffer:new(0)
    end

    if MACPayload.FRMPayload == nil or MACPayload.FRMPayload.length == 0 then
      MACPayload.FRMPayload = buffer:new(0)
    elseif MACPayload.FPort:readUInt8(1) == consts.MACCOMMANDPORT:readUInt8(1) then
      MACPayload.FRMPayload = MACPackager.packager(MACPayload.FRMPayload) --mac打包在frmpayload字段中
    end

    MHDR = MHDRPackager(phyPayloadJSON.MHDR) --mhdr打包
    FHDR = FHDRPackager(MACPayload.FHDR) --fhdr打包
  end

  local JOIN_ACCEPT = function()
    -- join accept消息 下行处理
    local devaddr = MACPayload.DevAddr
    local key = _deviceInfoMysql.readItem({DevAddr = devaddr}, {"AppKey"})
    if key ~= nil then
      logger.info("   join accept message packager...")
      return joinHandler.packager(phyPayloadJSON, key.AppKey)
    end
  end

  local ret =
    utiles.switch(MType) {
    [consts.JOIN_ACCEPT] = JOIN_ACCEPT,
    [consts.UNCONFIRMED_DATA_DOWN] = FIRMED_DATA_DOWN, -- ?? UNCONFIRMED 不存在下行帧
    [consts.CONFIRMED_DATA_DOWN] = FIRMED_DATA_DOWN
  }
  if ret ~= nil then
    return ret
  end

  -- frmpayload Encryption 加密
  local direction = buffer:new(consts.DIRECTION_LEN)
  direction:writeUInt8(1, consts.BLOCK_DIR_CLASS.Down)
  local DevAddr = MACPayload.FHDR.DevAddr

  local query = {
    DevAddr = utiles.BufferToHexString(DevAddr)
  }

  local attrs = {
    "AppSKey",
    "NwkSKey"
  }

  -- query AppSKey
  -- return this.DeviceInfo.readItem(query, attrs)
  local keys = _deviceInfoMysql.readItem(query, attrs)
  if keys ~= nil then
    local encryptionFields = {
      FRMPayload = MACPayload.FRMPayload,
      DevAddr = MACPayload.FHDR.DevAddr,
      FCnt = MACPayload.FHDR.FCnt
    }
    local key
    if MACPayload.FPort:readUInt8(1) == 0 then
      key = keys.NwkSKey
    else
      key = keys.AppSKey
    end

    if MACPayload.FHDR.FCtrl.FOptsLen > 0 then
      MACPayload.FRMPayload = nil
    else
      MACPayload.FRMPayload = phyUtils.decrypt(encryptionFields, key, direction) --下行加密
    end

    local PHYPayload =
      utiles.BufferConcat(
      {
        MHDR,
        FHDR,
        MACPayload.FPort,
        MACPayload.FRMPayload
      }
    )
    local micFields = {
      MHDR = MHDR,
      FHDR = FHDR,
      FPort = MACPayload.FPort,
      FRMPayload = MACPayload.FRMPayload,
      DevAddr = MACPayload.FHDR.DevAddr,
      FCnt = MACPayload.FHDR.FCnt
    }
    local MIC = phyUtils.micCalculator(micFields, keys.NwkSKey, direction) -- mic计算
    logger.info({"   calc mic val:", utiles.BufferToHexString(MIC)})
    PHYPayload = utiles.BufferConcat({PHYPayload, MIC})
    logger.info({" PHYPayload:", utiles.BufferToHexString(PHYPayload)})
    return PHYPayload
  end
end

return {
  packager = packager
}
