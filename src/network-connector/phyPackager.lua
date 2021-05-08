local utiles = require("../../utiles/utiles.lua")
-- const bluebird = require('bluebird');
-- const { consts, utils } = require('../lora-lib');
-- const phyUtils = require('./phyUtils');
local MACCmdPackager = require("./MACCmdPackager.lua")
--.MACCmdPackager;
local MACPackager = MACCmdPackager
-- const reverse = utils.bufferReverse;
local assign = utiles.bitwiseAssigner
-- const slice = utils.bufferSlice;
local consts = require("../lora-lib/constants/constants.lua")
local buffer = require("buffer").Buffer
local _deviceInfoMysql = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local joinHandler = require("./joinHandler.lua")

function MHDRPackager(MHDRJSON)
  local MHDR = buffer:new(consts.MHDR_LEN)
  utiles.bitwiseAssigner(MHDR, consts.MTYPE_OFFSET, consts.MTYPE_LEN, MHDRJSON.MType)
  utiles.bitwiseAssigner(MHDR, consts.MAJOR_OFFSET, consts.MAJON_LEN, MHDRJSON.Major)
  return MHDR
end

function FHDRPackager(FHDRJSON)
  local FHDR = buffer:new(consts.FHDR_LEN_BASE)
  local FCtrl = FCtrlPackager(FHDRJSON.FCtrl)
  utiles.reverse(FHDRJSON.DevAddr).copy(FHDR, consts.MP_DEVADDR_OFFSET)
  utiles.reverse(FCtrl).copy(FHDR, consts.MP_FCTRL_OFFSET)
  utiles.slice(FHDRJSON.FCnt, consts.FCNT_LEAST_OFFSET).copy(FHDR, consts.MP_FCNT_OFFSET)

  -- //console.log(FHDRJSON);
  if (FHDRJSON.FCtrl.FOptsLen > 0) then
    local FOpts = MACPackager.packager(FHDRJSON.FOpts)
    -- //console.log(FOpts);
    FHDR = buffer.concat({FHDR, FOpts})
  end

  return FHDR
end

function FCtrlPackager(FCtrlJSON)
  local FCtrl = buffer:new(consts.FCTRL_LEN)
  assign(FCtrl, consts.FC_ADR_OFFSET, consts.ADR_LEN, FCtrlJSON.ADR)
  assign(FCtrl, consts.FC_ACK_OFFSET, consts.ACK_LEN, FCtrlJSON.ACK)
  assign(FCtrl, consts.FC_FPENDING_OFFSET, consts.FPENDING_LEN, FCtrlJSON.FPending)
  assign(FCtrl, consts.FC_FOPTSLEN_OFFSET, consts.FOPTSLEN, FCtrlJSON.FOptsLen)
  return FCtrl
end

-- phy层打包
function packager(phyPayloadJSON)
  local MType = phyPayloadJSON.MHDR.MType
  local MACPayload = phyPayloadJSON.MACPayload
  local MHDR
  local FHDR
  -- const MType = utils.bitwiseFilter(phyPayloadJSON.MHDR, consts.MTYPE_OFFSET, consts.MTYPE_LEN);
  local FIRMED_DATA_DOWN = function()
    -- 配置下发数据
    if MACPayload.FPort ~= 0 then
      MACPayload.FPort = buffer:new(0)
    end

    if MACPayload.FRMPayload == 0 then
      MACPayload.FRMPayload = buffer.alloc(0)
    elseif (MACPayload.FPort.readUInt8() == consts.MACCOMMANDPORT.readUInt8()) then
      MACPayload.FRMPayload = MACPackager.packager(MACPayload.FRMPayload) --mac打包
    end

    MHDR = MHDRPackager(phyPayloadJSON.MHDR) --mhdr打包
    FHDR = FHDRPackager(MACPayload.FHDR) --fhdr打包
  end

  local JOIN_ACCEPT = function()
    local devaddr = MACPayload.DevAddr
    local key = _deviceInfoMysql.readItem({DevAddr = devaddr}, {"AppKey"})
    if key ~= nil then
      return joinHandler.packager(phyPayloadJSON, key.AppKey)
    end
  end
  
  local ret = utiles.switch(MType) {
    [consts.JOIN_ACCEPT] = JOIN_ACCEPT,
    [consts.UNCONFIRMED_DATA_DOWN] = FIRMED_DATA_DOWN,
    [consts.CONFIRMED_DATA_DOWN] = FIRMED_DATA_DOWN
  }
  if ret ~= nil then
    return ret
  end
  -- TODO:
  -- 以下是对于FRMPayload的负载情况下的
  -- //Encryption 加密
  local direction = buffer:new(consts.DIRECTION_LEN)
  direction:writeUInt8(consts.BLOCK_DIR_CLASS.Down)
  local DevAddr = MACPayload.FHDR.DevAddr
  local query = {
    DevAddr = DevAddr
  }
  local attrs = {
    "AppSKey",
    "NwkSKey"
  }
  -- //query AppSKey
  -- // return this.DeviceInfo.readItem(query, attrs)
  local keys = _deviceInfoMysql.readItem(query, attrs)
  if keys ~= nil then
    local encryptionFields = {
      FRMPayload = MACPayload.FRMPayload,
      DevAddr = MACPayload.FHDR.DevAddr,
      FCnt = MACPayload.FHDR.FCnt
    }
    local key
    if MACPayload.FPort.readUInt8() == 0 then
      key = keys.NwkSKey
    else
      key = keys.AppSKey
    end

    MACPayload.FRMPayload = phyUtils.decrypt(encryptionFields, key, direction) --下行加密
    local PHYPayload =
      buffer.concat(
      {
        MHDR,
        FHDR,
        MACPayload.FPort,
        MACPayload.FRMPayload
      }
    )
    local micFields = {
      MHDR,
      FHDR,
      FPort = MACPayload.FPort,
      FRMPayload = MACPayload.FRMPayload,
      DevAddr = MACPayload.FHDR.DevAddr,
      FCnt = MACPayload.FHDR.FCnt
    }
    local MIC = phyUtils.micCalculator(micFields, keys.NwkSKey, direction) -- mic计算
    PHYPayload = buffer.concat({PHYPayload, MIC})
    return PHYPayload
  end
end

return {
  packager = packager
}
