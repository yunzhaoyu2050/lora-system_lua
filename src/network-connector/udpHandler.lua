local consts = require("../lora-lib/constants/constants.lua")
local phyParser = require("./phyParser.lua")
local json = require("json")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles/utiles.lua")
local logger = require("../log.lua")

local function txAckParser(txAckData)
  local txAckJSON
  txAckJSON = json.parse(txAckData)
  ---------------------------------------error------------------------------------------
  -- Text              Description
  -- TOO_LATE,         Rejected because it was already too late to program this packet for downlink
  -- TOO_EARLY,        Rejected because downlink packet timestamp was received by the gateway too long before the scheduled transmission time
  -- COLLISION_PACKET, Rejected because there was already a packet programmed in requested timeframe
  -- COLLISION_BEACON, Rejected because there was already a beacon planned in requested timeframe
  -- TX_FREQ,          Rejected because requested frequency is not supported by TX RF chain
  -- TX_POWER,         Rejected because requested power is not supported by gateway
  -- GPS_UNLOCKED,     Rejected because GPS is unlocked, so GPS timestamp cannot be used
  --         Table 10: Description of TX_ACK error values
  return txAckJSON
end

-- udpLayer粗解析数据
-- @param data udp接收到的数据 string格式
-- @return nil: 粗解析失败, other: 解析成功
function parser(data)
  if data == nil then
    logger.error("data is nil.")
    return nil
  end
  if #data < consts.UDP_DATA_BASIC_LENGTH then
    logger.error(
      {
        "Invalid length of udp data, greater than consts.UDP_DATA_BASIC_LENGTH - 1 bytes is mandatory",
        dataLen = #data,
        BASIC_LENGTH = consts.UDP_DATA_BASIC_LENGTH
      }
    )
    return nil
  end

  local recvData = buffer:new(data)

  local udpJSON = {
    version = recvData:readUInt8(consts.UDP_VERSION_OFFSET + 1),
    token = utiles.BufferToHexString(recvData, consts.UDP_TOKEN_OFFSET + 1, consts.UDP_IDENTIFIER_OFFSET),
    identifier = recvData:readUInt8(consts.UDP_IDENTIFIER_OFFSET + 1)
  }

  if consts.UDP_VERSION_LIST[udpJSON.version] == nil then
    logger.error("Bad UDP version number!")
    return nil
  end

  local identifier = udpJSON.identifier
  if identifier == consts.UDP_ID_PUSH_DATA then
    if #data <= consts.PUSH_DATA_BASIC_LENGTH then
      logger.error("Invalid length of push data, greater than ${consts.PUSH_DATA_BASIC_LENGTH} bytes is mandatory")
      return nil
    end
    udpJSON.gatewayId = utiles.BufferToHexString(recvData, consts.UDP_GW_ID_OFFSET + 1, consts.UDP_JSON_OBJ_OFFSET)
    udpJSON.pushData = recvData:toString(consts.UDP_JSON_OBJ_OFFSET + 1)
    udpJSON.DataType = "PUSH_DATA"
  elseif identifier == consts.UDP_ID_PULL_DATA then
    -- p("Currently only processing push data. ", udpJSON)
    -- return nil -- TODO: 当前不测试推送的数据
    -- 当前不处理推送的数据
    if #data ~= consts.PULL_DATA_LENGTH then
      logger.error("Invalid length of pull data, ${consts.PULL_DATA_LENGTH} bytes is mandatory")
      return nil
    end
    udpJSON.gatewayId = utiles.BufferToHexString(recvData, consts.UDP_GW_ID_OFFSET + 1, consts.UDP_JSON_OBJ_OFFSET)
    udpJSON.DataType = "PULL_DATA"
  elseif identifier == consts.UDP_ID_TX_ACK then
    udpJSON.gatewayId = utiles.BufferToHexString(recvData, consts.UDP_GW_ID_OFFSET + 1, consts.UDP_JSON_OBJ_OFFSET)
    local txAckBuf = utiles.BufferSlice(recvData, 5, recvData.length)
    udpJSON.txAckData = txAckParser(recvData:toString(consts.UDP_TX_ACK_PAYLOAD_OFFSET + 1))
    udpJSON.DataType = "TX_ACK"

    -- 如果未报告任何错误，则“有效负载”字段包含值“ \ 0”的一个八位字节。
    -- 如果报告了错误，则该字段包含JSON“错误”对象。
    if udpJSON.txAckData ~= nil then
      logger.info({"   txAckData:", udpJSON.txAckData})
    else
      logger.error("   ack no error")
    end
    logger.warn({"Currently only processing tx ack data. ", udpJSON})
    return nil -- TODO: 当前不测试tx ack的数据
  else
    logger.error("Invalid identifier, any of [0x00, 0x02, 0x05] is required")
    return nil
  end
  logger.info({"gateway -> server, data parser:", udpJSON})
  return udpJSON
end

-- 下行处理打包数据
local function packager(requiredFields)
  if requiredFields == nil then
    logger.error("requiredFields param is nil")
    return nil
  end
  -- TODO-Schema validation
  local data = buffer:new(consts.UDP_DOWNLINK_BASIC_LEN)
  data:writeUInt8(consts.UDP_VERSION_OFFSET + 1, requiredFields.version)
  utiles.BufferFromHexString(data, consts.UDP_TOKEN_OFFSET + 1, requiredFields.token)
  data:writeUInt8(consts.UDP_IDENTIFIER_OFFSET + 1, requiredFields.identifier)
  if requiredFields.identifier == consts.UDP_ID_PUSH_ACK then
    -- break
  elseif requiredFields.identifier == consts.UDP_ID_PULL_ACK then
    -- TODO: PULL_ACK的长度是 4 + 8(Gateway EUI) > consts.UDP_DOWNLINK_BASIC_LEN
    local idBuf = buffer:new(consts.GATEWAYID_LEN)
    utiles.BufferFromHexString(idBuf, 1, requiredFields.gatewayId)
    data = utiles.BufferConcat(data, idBuf)
  elseif requiredFields.identifier == consts.UDP_ID_PULL_RESP then
    local txpk = {
      txpk = requiredFields.txpk
    }
    if requiredFields.dstID ~= nil then
      txpk.dstID = requiredFields.dstID
    end
    txpk.txpk.brd = 0
    txpk.txpk.ant = 0
    requiredFields.payload = json.stringify(txpk)
    local payloadBuf = buffer:new(#requiredFields.payload)
    utiles.BufferWrite(payloadBuf, 1, requiredFields.payload, #requiredFields.payload) -- consts.UDP_VERSION_OFFSET + consts.UDP_TOKEN_OFFSET + consts.UDP_IDENTIFIER_OFFSET + 1
    data = utiles.BufferConcat(data, payloadBuf)
  else
    logger.error("Bad type of UDP identifier")
    return nil
  end
  local tmp = data:toString()
  return tmp
end

-- ACK应答
-- @param incomingJSON gateway -> server传过来粗解析后的数据
-- @return ACK错误：nil, ACK成功：非nil
function ACK(incomingJSON)
  logger.info("server -> gateway, data process")
  if incomingJSON == nil then
    logger.error("incomingJSON param is nil")
    return nil
  end
  local identifierTemp = {
    version = incomingJSON.version,
    token = incomingJSON.token,
    gatewayId = incomingJSON.gatewayId,
    DataType = incomingJSON.DataType
  } -- 保护原先的解析值
  -- local requiredFields = buffer:new(consts.UDP_PUSH_ACK_LEN)
  -- requiredFields.identifier.writeUInt8()
  if incomingJSON.identifier == consts.UDP_ID_PUSH_DATA then
    identifierTemp.identifier = consts.UDP_ID_PUSH_ACK
    identifierTemp.pushData = incomingJSON.pushData -- TODO: 删除
  elseif incomingJSON.identifier == consts.UDP_ID_PULL_DATA then
    identifierTemp.identifier = consts.UDP_ID_PULL_ACK
  else
    identifierTemp.identifier = nil
  end
  return packager(identifierTemp)
end

-- pushData解析
-- @param udpPushJSON
function pushDataParser(udpPushJSON)
  logger.info("rough analysis of upstream data...")
  if udpPushJSON == nil then
    logger.error("udpPushJSON is nil")
    return -1
  end
  local JSONStr = udpPushJSON.pushData
  local pushDataJSON = json.parse(JSONStr)
  if pushDataJSON == nil then
    logger.error("Error format of JSON, unable to parse")
    return -2
  end
  -- pushData粗解析
  -- json中对于相同的key可能会导致结果出现错误
  local stat = {}
  local output = {}
  output.origin = udpPushJSON -- 原始数据未json解析的
  local rxpkPromise
  if pushDataJSON["stat"] ~= nil then -- 网关状态数据
    stat = pushDataJSON.stat
    output.stat = stat
  end
  --   if ('srcID' in pushDataJSON) { // ? 可能是自行设计的元素
  --     output.srcID = pushDataJSON.srcID;
  --   }
  if pushDataJSON["rxpk"] ~= nil then -- 上行数据
    -- pushDataJSON.rxpk.可能为一个数组包含多组rxpk
    rxpkPromise = {}
    local element
    for k, _ in pairs(pushDataJSON.rxpk) do
      local data = phyParser.parser(pushDataJSON.rxpk[k].data)
      element = pushDataJSON.rxpk[k]
      if data ~= nil then
        element.raw = pushDataJSON.rxpk[k].data -- 原始数据
        element.data = data -- 解析后的数据
        rxpkPromise[k] = {}
        rxpkPromise[k] = element
      else
        logger.error("data is nil, phy layer parser failed.")
      end
    end
  else
    rxpkPromise = nil
  end
  if rxpkPromise ~= nil then
    output.rxpk = rxpkPromise
  end
  -- logger.info("output:", output)
  return output
end

-- pullRespPackager(pullJson) {
--   let tx;
--   if ('pullRes' in pullJson) {
--     tx = udpUtils.generateTxpk(pullJson.rxi, pullJson.pullRes, pullJson.gatewayId);
--   }

--   if ('joinAcp' in pullJson) {
--     tx = udpUtils.geneJoinAcpTxpk(pullJson.rxi, pullJson.joinAcp, pullJson.gatewayId);
--   }

--   if (!tx) {
--     return null;
--   }

--   let dlinkpackage = {
--     version: pullJson.version,
--     token: Buffer.from('0000', 'hex'),
--     identifier: Buffer.from('03', 'hex'),
--     txpk: tx,
--   };

--   return this.packager(dlinkpackage);
-- }

return {
  parser = parser,
  ACK = ACK,
  pushDataParser = pushDataParser,
  packager = packager
}
