local RedisDeviceInfo = require("../lora-lib/models/RedisModels/DeviceInfo.lua")
local consts = require("../lora-lib/constants/constants.lua")
local buffer = require("buffer").Buffer
local MysqlDeviceInfo = require("../lora-lib/models/MySQLModels/DeviceInfo.lua")
local DownlinkCmdQueue = require("../lora-lib/models/RedisModels/DownlinkCmdQueue.lua")
local config = require("../../server_cfg.lua")
local uv = require("luv")
local utiles = require("../../utiles/utiles.lua")
local logger = require("../log.lua")

-- app-data下行数据处理
function appDataDownlink(uplinkData, convertFn)
  logger.info("<-------uplinkData Info------------>")
  -- logger.info("   uplinkData:", uplinkData)
  local uplinkInfo = uplinkData
  local DevAddr = uplinkInfo.MACPayload.FHDR.DevAddr
  local ret = nil

  local generateDownlink = function(txJson, downlinkJson) -- 生成下行数据包
    local dlkObj = convertFn(txJson, downlinkJson, uplinkInfo) -- 下行数据打包
    if dlkObj == nil then
      logger.error("Generate downlink object failed")
      return nil
    end
    logger.info("<-------Downlink Object------------>")
    -- logger.info("   dlkObj:", dlkObj)
    -- publish schema-valid downlink data to NC-sub
    -- TODO : increaseNfcntdown (for MAC Command)
    ret = RedisDeviceInfo.IncreaseAfcntdown(DevAddr)
    -- return _this.mysqlConn.DeviceInfo.increaseAfcntdown(DevAddr);
    -- 将数据推送至network connector模块
    return dlkObj
  end

  local downlinkDataHandler = function()
    local res
    local downlinkJson = {
      FPending = 0,
      FOptsLen = 0,
      FOpts = buffer:new(0),
      FRMPayload = buffer:new(0),
      isMacCmdInFRM = false,
      ackbit = 0
    }

    local messageType = uplinkInfo.MHDR.MType
    local messageFPort = uplinkInfo.MACPayload.FPort

    if messageType == consts.CONFIRMED_DATA_UP then
      downlinkJson.ackbit = 1
    end

    -- Get txpk config from db
    -- return _this.mysqlConn.getTxpkInfo(DevAddr).then(function (txJson) {
    DevAddr = utiles.BufferToHexString(DevAddr)
    local txJson = RedisDeviceInfo.Read(DevAddr)

    -- const frequencyPlan = txJson.DeviceConfig.frequencyPlan;
    local frequencyPlan = txJson.frequencyPlan
    local downlinkDatr = txJson.datr
    local repeaterCompatible = false
    -- const protocolVersion = txJson.DeviceInfo.ProtocolVersion;
    local protocolVersion = txJson.ProtocolVersion
    local maxFRMPayloadAndFOptSize =
      getMaxFRMPayloadAndFOptByteLength(frequencyPlan, txJson.datr, repeaterCompatible, protocolVersion)

    if maxFRMPayloadAndFOptSize == 0 then
      logger.error(
        {
          message = "Get max FRMPayload & FOpt Byte Length Error",
          DevAddr = DevAddr,
          frequencyPlan = frequencyPlan,
          downlinkDatr = downlinkDatr
        }
      )
    end

    local macCmdQueAnsKey = consts.MACCMDQUEANS_PREFIX .. DevAddr
    local macCmdQueReqKey = consts.MACCMDQUEREQ_PREFIX .. DevAddr
    local msgQueKey = consts.DOWNLINK_MQ_PREFIX .. DevAddr

    -- Consume mac cmd answer queue
    local cmdAnsArrLen = DownlinkCmdQueue.checkQueueLength(macCmdQueAnsKey)
    local cmdAnsArr = DownlinkCmdQueue.consumeAll(macCmdQueAnsKey) -- ans队列

    if config.GetMacInFrmpaylaodEnable() == false then
      -- Mac cmd answer queue has data
      if cmdAnsArr and cmdAnsArrLen > 0 then
        downlinkJson.ackbit = 1
        local macCmdDownLen = getMacCmdDownByteLength(cmdAnsArr)

        if macCmdDownLen > consts.FOPTS_MAXLEN then
          downlinkJson.isMacCmdInFRM = true
          downlinkJson.FRMPayload = cmdAnsArr

          local remainSize = maxFRMPayloadAndFOptSize - macCmdDownLen

          if remainSize < 0 then
            logger.error(
              {
                message = "RemainSize less than 0",
                DevAddr = DevAddr,
                macCmdAns = cmdAnsArr,
                macCmdDownLen = macCmdDownLen,
                maxSize = maxFRMPayloadAndFOptSize
              }
            )
            return nil
          end

          local cmdReqArrLen = DownlinkCmdQueue.checkQueueLength(macCmdQueReqKey)
          local cmdReqArr = DownlinkCmdQueue.consumeAll(macCmdQueReqKey) -- req队列
          if cmdReqArr and cmdReqArrLen > 0 then
            for i = 1, cmdReqArrLen do
              local macByteLen = 0
              for key, _ in pairs(cmdReqArr[i]) do
                local cid = key
                if utiles.IsIndexInList(consts.MACCMD_DOWNLINK_LIST, cid) == true then
                  macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_DOWNLINK_LIST[cid]
                end
              end

              remainSize = remainSize - macByteLen
              if remainSize >= 0 then
                downlinkJson.FRMPayload = cmdReqArr[i]
              else
                if i < cmdReqArrLen - 1 then
                  downlinkJson.FPending = 1
                end
                break
              end
            end
          end

          res = DownlinkCmdQueue.checkQueueLength(msgQueKey)

          if res and res > 0 then
            downlinkJson.FPending = 1
          end
          return generateDownlink(txJson, downlinkJson)
        elseif macCmdDownLen <= consts.FOPTS_MAXLEN then
          downlinkJson.FOptsLen = macCmdDownLen
          downlinkJson.FOpts = cmdAnsArr -- 此处整理将cmd命令顺序排放至fopts中

          local cmdReqArrLen = DownlinkCmdQueue.checkQueueLength(macCmdQueReqKey) -- 此处存在问题: 为什么检查req队列
          local cmdReqArr = DownlinkCmdQueue.consume(macCmdQueReqKey) -- ??
          if cmdReqArr and cmdReqArrLen > 0 then
            for i = 0, cmdReqArrLen do
              local macByteLen = 0
              for key, _ in pairs(cmdReqArr[i]) do
                local cid = key
                if utiles.IsIndexInList(consts.MACCMD_DOWNLINK_LIST, cid) == true then
                  macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_DOWNLINK_LIST[cid]
                end
              end

              if macByteLen + downlinkJson.FOptsLen <= consts.FOPTS_MAXLEN then
                downlinkJson.FOptsLen = macByteLen + downlinkJson.FOptsLen
                downlinkJson.FOpts = cmdReqArr[i]
              else
                if i < cmdReqArr.length - 1 then
                  downlinkJson.FPending = 1
                end
                break
              end
            end
          end

          res = DownlinkCmdQueue.consume(msgQueKey)
          if res and res.pbdata ~= nil then
            downlinkJson.FRMPayload = utiles.BufferFrom(res.pbdata)
          end
          if downlinkJson.FRMPayload.length > maxFRMPayloadAndFOptSize then
            logger.error(
              {
                message = "App data Length exceeds the maximum length in FRMPayload",
                DevAddr = DevAddr,
                maxFRMPayloadAndFOptSize = maxFRMPayloadAndFOptSize,
                appDataLength = downlinkJson.FRMPayload.length
              }
            )
            return nil
          end

          return generateDownlink(txJson, downlinkJson)
        end

        -- Mac cmd answer queue has NO data
        -- Read Mac cmd request queue
        local cmdReqArrLen = DownlinkCmdQueue.checkQueueLength(macCmdQueReqKey)
        local cmdReqArr = DownlinkCmdQueue.consume(macCmdQueReqKey)
        -- Mac cmd request queue has data
        if cmdReqArr and cmdReqArrLen > 0 then
          downlinkJson.ackbit = 1
          local macCmdDownLen = getMacCmdDownByteLength(cmdReqArr)
          if macCmdDownLen > consts.FOPTS_MAXLEN then
            local macCmdDownLen = getMacCmdDownByteLength(cmdReqArr)

            downlinkJson.isMacCmdInFRM = true
            downlinkJson.FRMPayload = cmdReqArr

            if macCmdDownLen > maxFRMPayloadAndFOptSize then
              logger.error(
                {
                  message = "MAC commands request Length exceeds the maximum length  in FRMPayload && delete reqest queue",
                  DevAddr = DevAddr,
                  maxFRMPayloadAndFOptSize = maxFRMPayloadAndFOptSize,
                  macReqLength = downlinkJson.FRMPayload.length
                }
              )
            end

            res = DownlinkCmdQueue.checkQueueLength(msgQueKey)
            if res and res > 0 then
              downlinkJson.FPending = 1
            end

            return generateDownlink(txJson, downlinkJson)
          elseif macCmdDownLen <= consts.FOPTS_MAXLEN then
            downlinkJson.FOptsLen = macCmdDownLen
            downlinkJson.FOpts = cmdReqArr
          end
        end

        -- Mac cmd request queue has data || Mac cmd request queue length <= FOPTS_MAXLEN
        res = DownlinkCmdQueue.consume(msgQueKey)
        if res == nil and downlinkJson.ackbit == nil then
          logger.error("The message has no downlink object")
          return nil
        end

        if res and res.pbdata then
          downlinkJson.FRMPayload = utiles.BufferFrom(res.pbdata)
        end

        if downlinkJson.FRMPayload.length > maxFRMPayloadAndFOptSize then
          logger.error(
            {
              message = "App data Length exceeds the maximum length in FRMPayload",
              DevAddr = DevAddr,
              maxFRMPayloadAndFOptSize = maxFRMPayloadAndFOptSize,
              appDataLength = downlinkJson.FRMPayload.length
            }
          )
        end

        return generateDownlink(txJson, downlinkJson)
      end
    elseif config.GetMacInFrmpaylaodEnable() == true then
      -- 使能mac命令在frmpayload字段中
      downlinkJson.isMacCmdInFRM = true

      downlinkJson.FRMPayload = cmdAnsArr
      -- for i, _ in pairs(cmdAnsArr) do
      --   for k, v in pairs(cmdAnsArr[i]) do
      --     local cidBuf = buffer:new(consts.CID_LEN)
      --     cidBuf:writeUInt8(consts.CID_OFFEST + 1, tonumber(k))
      --     local payloadBuf = utiles.BufferConcat(v)
      --     downlinkJson.FRMPayload = utiles.BufferConcat({cidBuf, payloadBuf})
      --     -- 当前只取第一个命令
      --     break
      --   end
      --   -- 当前只取第一个命令
      --   break
      -- end
      -- p("downlinkJson.FRMPayload:")
      -- utiles.printBuf(downlinkJson.FRMPayload)
      res = DownlinkCmdQueue.checkQueueLength(macCmdQueAnsKey)
      if res and res > 0 then
        downlinkJson.FPending = 1
      end
      return generateDownlink(txJson, downlinkJson)
    else
      logger.error({"error, GetMacInFrmpaylaodEnable, ", config.GetMacInFrmpaylaodEnable()})
      return nil
    end
  end

  local UpdateData = function(downlinkData) -- 更新数据库
    -- Persist Redis data to Mysql
    local res = RedisDeviceInfo.Read(DevAddr)
    if res == nil then
      logger.error({"Failed to persist Redis data to Mysql. No data in Redis, devaddr:", DevAddr})
      return nil
    end
    if downlinkData then
      -- return _this.mysqlConn.DeviceRouting.upsertItem(persistDataToDeviceRouting);
      local persistDataToDeviceInfo = {
        FCntUp = res.FCntUp,
        AFCntDown = res.AFCntDown,
        NFCntDown = res.NFCntDown
      }
      local persistDataToDeviceRouting = {
        DevAddr = DevAddr,
        gatewayId = res.gatewayId,
        imme = res.imme,
        tmst = res.tmst,
        freq = res.freq,
        powe = res.powe,
        datr = res.datr,
        modu = res.modu,
        codr = res.codr
      }
      return MysqlDeviceInfo.UpdateItem({DevAddr = DevAddr}, persistDataToDeviceInfo)
    else
      local persistDataToDeviceInfo = {
        FCntUp = res.FCntUp
      }
      return MysqlDeviceInfo.UpdateItem({DevAddr = DevAddr}, persistDataToDeviceInfo)
    end
  end

  -- main
  -- uv.sleep(config.GetDownlinkDataDelay()) -- delay 500 ms from config
  local downlinkData = downlinkDataHandler()
  ret = UpdateData(downlinkData)
  return downlinkData
end

function getMacCmdDownByteLength(macCmdArr)
  local macByteLen = 0
  for _, element in pairs(macCmdArr) do
    local cid
    for key, _ in pairs(element) do
      cid = key
    end
    if utiles.IsIndexInList(consts.MACCMD_DOWNLINK_LIST, cid) == true then
      macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_DOWNLINK_LIST[tonumber(cid)]
    end
  end
  return macByteLen
end

function getMacCmdUpByteLength(macCmdArr)
  local macByteLen = 0
  for _, element in pairs(macCmdArr) do
    local cid
    for key, _ in pairs(element) do
      cid = key
    end
    if utiles.IsIndexInList(consts.MACCMD_UPLINK_LIST, cid) == true then
      macByteLen = macByteLen + consts.CID_LEN + consts.MACCMD_UPLINK_LIST[cid]
    end
  end
  return macByteLen
end

function getMaxFRMPayloadAndFOptByteLength(frequencyPlan, datr, repeaterCompatible, protocolVersion)
  local maxByteLen = 0
  -- TODO Add protocolVersion Check
  if repeaterCompatible == false then
    maxByteLen = consts.MAX_FRMPAYLOAD_SIZE_NOREPEATER[frequencyPlan][datr]
  else
    maxByteLen = consts.MAX_FRMPAYLOAD_SIZE_REPEATER[frequencyPlan][datr]
  end
  return maxByteLen
end

-- 下行join-accept数据处理
function joinAcceptDownlink(joinAcceptJson, convertFn)
  local devAddr = joinAcceptJson.rxpk.data.DevAddr
  -- local query = {
  --   DevAddr = devAddr
  -- }
  local res = RedisDeviceInfo.Read(devAddr) -- 读取存储的所有内容
  if res == nil then
    logger.error("get txpk config from db failed.")
    return -2
  end
  local dlkObj = convertFn(res, joinAcceptJson)
  -- 把数据推送至connector模块处理
  return dlkObj
end

return {
  joinAcceptDownlink = joinAcceptDownlink,
  appDataDownlink = appDataDownlink
}
