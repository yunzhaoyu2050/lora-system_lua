-- @info mac cmd解析

local consts = require("../lora-lib/constants/constants.lua")
local basexx = require("../../deps/basexx/lib/basexx.lua")
local buffer = require("buffer").Buffer
local bit = require("bit")
local ffi = require("ffi")

-- buffer裁剪
-- @param start开始位置
function buffer:slice(offsetStart, offsetEnd)
  local newBuf = buffer:new(offsetEnd - offsetStart + 1)
  ffi.copy(newBuf.ctype, self.ctype + offsetStart - 1, offsetEnd - offsetStart + 1)
  return newBuf
end

-- mac cmd 解析
-- @param macCommand buffer类型数据
function parser(macCommand)
  if macCommand == nil then
    p("macCommand is nil")
    return -1
  end
  local cmd = macCommand
  local ansLen = 0
  local cmdArr = {}
  while (cmd.length) do
    -- local cid = cmd:slice(consts.CID_OFFEST + 1, consts.PAYLOAD_OFFEST + 1);
    local cid = cmd:readInt8(consts.CID_OFFEST + 1)
    local payloadJson
    local offest
    local payload = nil
    local cidTmp = cid
    if cidTmp == consts.RESET_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.RESETIND_LEN
      payload = {
        Version = cmd:slice(consts.PAYLOAD_OFFEST + 1, offest)
      }
      ansLen = ansLen + consts.CID_LEN + consts.RESETCONF_LEN
    elseif cidTmp == consts.LINKCHECK_CID then
      -- payload = slice(cmd, consts.PAYLOAD_OFFEST, offest, false);
      offest = consts.PAYLOAD_OFFEST + 1 + consts.LINKCHECKREQ_LEN
      ansLen = ansLen + consts.CID_LEN + consts.LINKADRANS_LEN
    elseif cidTmp == consts.LINKADR_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.LINKADRANS_LEN
      payload = {
        Status = cmd:slice(consts.PAYLOAD_OFFEST + 1, offest)
      }
    elseif cidTmp == consts.DUTYCYCLE_CID then
      -- payload = slice(cmd, consts.PAYLOAD_OFFEST, offest, false);
      offest = consts.PAYLOAD_OFFEST + consts.DUTYCYCLEANS_LEN
    elseif cidTmp == consts.RXPARAMSETUP_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.RXPARAMSETUPANS_LEN
      payload = {
        Status = cmd:slice(consts.PAYLOAD_OFFEST + 1, offest)
      }
    elseif cidTmp == consts.DEVSTATUS_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.DEVSTATUSANS_LEN
      local marginOffest = consts.PAYLOAD_OFFEST + 1 + consts.BATTERY_LEN
      payload = {
        Battery = cmd:slice(consts.PAYLOAD_OFFEST + 1, marginOffest),
        Margin = cmd:slice(marginOffest, offest)
      }
    elseif cidTmp == consts.NEWCHANNEL_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.NEWCHANNELANS_LEN
      payload = {
        Status = cmd:slice(consts.PAYLOAD_OFFEST + 1, offest)
      }
    elseif cidTmp == consts.RXTIMINGSETUP_CID then
      -- payload = slice(cmd, consts.PAYLOAD_OFFEST, offest, false);
      offest = consts.PAYLOAD_OFFEST + 1 + consts.RXTIMINGSETUPANS_LEN
    elseif cidTmp == consts.TXPARAMSETUP_CID then
      -- payload = slice(cmd, consts.PAYLOAD_OFFEST, offest, false);
      offest = consts.PAYLOAD_OFFEST + 1 + consts.TXPARAMSETUPANS_LEN
    elseif cidTmp == consts.DLCHANNEL_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.DLCHANNELANS_LEN
      payload = {
        Status = cmd:slice(consts.PAYLOAD_OFFEST + 1, offest)
      }
    elseif cidTmp == consts.REKEY_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.REKEYIND_LEN
      payload = {
        Version = cmd:slice(consts.PAYLOAD_OFFEST + 1, offest)
      }
      ansLen = ansLen + consts.CID_LEN + consts.REKEYCONF_LEN
    elseif cidTmp == consts.ADRPARAMSETUP_CID then
      -- payload = slice(cmd, consts.PAYLOAD_OFFEST, offest, false);
      offest = consts.PAYLOAD_OFFEST + 1 + consts.ADRPARAMSETUPANS_LEN
    elseif cidTmp == consts.DEVICETIME_CID then
      -- payload = slice(cmd, consts.PAYLOAD_OFFEST, offest, false);
      offest = consts.PAYLOAD_OFFEST + 1 + consts.DEVICETIMEREQ_LEN
      ansLen = ansLen + consts.CID_LEN + consts.DEVICETIMEANS_LEN
    elseif cidTmp == consts.REJOINPARAMSETUP_CID then
      offest = consts.PAYLOAD_OFFEST + 1 + consts.REJOINPARAMSETUPANS_LEN
      payload = {
        Status = cmd:slice(consts.PAYLOAD_OFFEST + 1, offest)
      }
    else
      p("Bad cid of MACCommand")
      return -2
    end
    payloadJson = {
      [cid:toString()] = payload
    }
    table.insert(cmdArr, payloadJson)

    if offest > cmd.length then
      p("Invalid format of MACCommand payload")
      break
    else
      cmd = cmd:slice(offest, cmd.length)
    end
  end -- end while
  return {cmdArr, ansLen}
end

return {
  parser = parser
}
