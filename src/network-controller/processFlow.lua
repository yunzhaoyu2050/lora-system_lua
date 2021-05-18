local utiles = require("../../utiles/utiles.lua")
-- const BluebirdPromise = require('bluebird');
local MacCommandHandler = require("./macCmdHandlers/macCmdHandlers.lua")
-- const AdrControlScheme = require('./controlSchemes/adrControlScheme');
local constants = require("../lora-lib/constants/constants.lua")
local DownlinkCmdQueue = require("../lora-lib/models/RedisModels/DownlinkCmdQueue.lua")
-- // const DeviceRXInfo = require('../lib/converter/deviceRXInfo');
-- // const MacCommand = require('../lib/converter/macCommand');

-- class ProcessFlow {

--   constructor(mysqlConn, redisConn, log) {

--     this.mysqlConn = mysqlConn;
--     this.redisConn = redisConn;
--     this.log = log;
--     this.cmdHandler = MacCommandHandler;
--     this.adrControlScheme = new AdrControlScheme(mysqlConn, redisConn, log);
--   }

local function GetCidIndex(cmdTbl)
  for k, _ in pairs(cmdTbl) do
    return k
  end
end

-- 指向的值是否在表中存
local function IsExistInCmdTbl(tbl, val)
  local cmd
  if type(val) == "string" then
    cmd = tonumber(val)
  elseif type(val) == "number" then
    cmd = val
  else
    return nil
  end

  for _, v in pairs(tbl) do
    if v == cmd then
      return true
    end
  end
  return false
end

--
-- process mac command and uplink status report of adr device sequentially
--
function process(messageObj)
  if
    messageObj.DevAddr == nil or messageObj.adr == nil or messageObj.data == nil or messageObj.devtx == nil or
      messageObj.gwrx == nil
   then
    p("Invalid message from kafka, Message ${JSON.stringify(messageObj)}")
    return nil
  end

  local devAddr = utiles.BufferToHexString(messageObj.DevAddr)
  local isAdr = messageObj.adr
  local cmds = messageObj.data
  local remains = {
    devtx = messageObj.devtx,
    gwrx = messageObj.gwrx
  }

  -- let _this = this;
  local dlkCmdQue = DownlinkCmdQueue
  -- let log = this.log;
  local processFlow = {}

  -- process mac commands (req and ans)

  if devAddr == nil or cmds == nil then
    p("Lack of devAddr or data from kafka message", devAddr, cmds)
  end

  -- get all commands in downlink queue
  local mqKey = constants.MACCMDQUEREQ_PREFIX .. devAddr;
  local dlkArr = dlkCmdQue.getAll(mqKey)
  if dlkArr then
    -- misMatchIndex is index in downlink queue
    -- first cmd answer in uplink array mismatched cmd req in downlink que
    local misMatchIndex = -1
    local matchIndex = 1

    -- validate and process cmd in uplink array 'cmds'
    for i = 1, #cmds do
      local cid = GetCidIndex(cmds[i])

      -- process cmd req from device (cid = 0x01 0x02 0x0B 0x0D)
      if IsExistInCmdTbl(constants.QUEUE_CMDANS_LIST, cid) == true then
        -- continue;
        __getCmdHandlerFunc(devAddr, cid, cmds[i][cid], remains)
      else
        -- match cmd answers from device with req in downlink queue
        local dlkcid = nil
        if (dlkArr.length > 0 and matchIndex < dlkArr.length) then
          local dlkobj = JSON.parse(dlkArr[matchIndex])
          for key, _ in pairs(dlkobj) do
            if (dlkobj.hasOwnProperty(key)) then
              dlkcid = key
            end
          end
        end

        if (matchIndex < dlkArr.length and cid == dlkcid) then
          matchIndex = matchIndex + 1
          processFlow.push(_this.__getCmdHandlerFunc(devAddr, parseInt(cid, 16), cmds[i][cid], remains))
        else
          if (misMatchIndex == -1) then
            p(
              "uplink cmd mismatched with downlink cmd queue",
              {
                uplinkIndex = i,
                uplinkCid = cid,
                downlinkIndex = matchIndex,
                downlinkCid = dlkcid
              }
            )
          end
          if misMatchIndex == -1 then
            misMatchIndex = matchIndex
          else  
            misMatchIndex = misMatchIndex
          end
        end
      end
    end

    -- cmds in uplink array more than cmds in downlink queue
    local dowQueueLen = DownlinkCmdQueue.checkQueueLength(mqKey)
    if misMatchIndex > dowQueueLen then
      misMatchIndex = dowQueueLen
    end

  -- trim (repush downlink cmd request into queue)
  -- local startPos  -- =  misMatchIndex == -1 ? matchIndex : misMatchIndex;
  -- if misMatchIndex == -1 then
  --   startPos = matchIndex
  -- else
  --   startPos = misMatchIndex
  -- end
  -- dlkCmdQue.trim(devAddr, startPos, -1)
  end

  -- process uplink status of adr device

  -- push adr device status handler function
  if isAdr ~= 0 then
    processFlow.push(adrControlScheme.adrHandler.bind(_this.adrControlScheme, devAddr, remains.devtx))
  end

  -- process all command and adr report sequentially
  -- return BluebirdPromise.map(
  --   processFlow,
  --   function(process)
  --     return process()
  --   end
  -- )
  p("process all command and adr report sequentially", dlkCmdQue.checkQueueLength(mqKey))
end

--
-- return promise of uplink command handler
--
function __getCmdHandlerFunc(devaddr, cid, payload, remains)
  cid = tonumber(cid)
  -- switch cid to select 'devtx', 'gwrx' in remains
  -- and to select command handler
  -- fn.bind(_this, ...) is to use 'mysqlConn', 'redisConn' and 'log' of processFlow
  local fn = MacCommandHandler[cid]

  return utiles.switch(cid) {
    -- LoRaWAN 1.0 Device Request
    [constants.LINKCHECK_CID] = function()
      return fn(devaddr, remains.devtx, remains.gwrx)
    end,
    -- LoRaWAN 1.0 Device Answer
    -- TODO add 'payload' in fn.bind
    [constants.LINKADR_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.DEVSTATUS_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.RXPARAMSETUP_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.RXTIMINGSETUP_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.NEWCHANNEL_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.DUTYCYCLE_CID] = function()
      return fn(devaddr, payload)
    end,
    -- LoRaWAN 1.1 Device Request
    -- TODO
    [constants.RESET_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.REKEY_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.DEVICETIME_CID] = function()
      return fn(devaddr, payload, remains.gwrx)
    end,
    -- LoRaWAN 1.1 Device Answer
    -- TODO add 'payload' in fn.bind
    [constants.ADRPARAMSETUP_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.DLCHANNEL_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.TXPARAMSETUP_CID] = function()
      return fn(devaddr, payload)
    end,
    [constants.REJOINPARAMSETUP_CID] = function()
      return fn(devaddr, payload)
    end,
    [utiles.Default] = function()
      p("item is other, please check it.", cid)
      return nil
    end,
    [utiles.Nil] = function()
      p("cid is nil")
    end
  }
end

return {
  process = process
}
