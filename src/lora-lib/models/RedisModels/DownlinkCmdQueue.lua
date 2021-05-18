-- local utiles = require("../../utiles/utiles.lua")
local queue = require("../../../../deps/Dee_LuaADT/queue.lua")

local DownlinkCmdQueueTbl = {}
local DownlinkCmdQueue = {}

DownlinkCmdQueue.table = DownlinkCmdQueueTbl

function DownlinkCmdQueue.checkQueueLength(key) -- 获取队列长度
  return #DownlinkCmdQueueTbl[key]
end

function DownlinkCmdQueue.getAll(key) -- 获取所有元素
  if DownlinkCmdQueueTbl[key] == nil then
    DownlinkCmdQueueTbl[key] = queue.create()
  end
  local out = {
    -- length = #DownlinkCmdQueueTbl[key]
  }
  for i = 1, #DownlinkCmdQueueTbl[key] do
    out[i] = DownlinkCmdQueueTbl[key].dequeue()
  end
  return out
end

DownlinkCmdQueue.consumeAll = DownlinkCmdQueue.getAll

function DownlinkCmdQueue.removeAll(key) -- 删除所有元素
  if DownlinkCmdQueueTbl[key] == nil then
    return nil
  end
  return DownlinkCmdQueueTbl[key].clear()
  --return table.remove(DownlinkCmdQueueTbl, key)
end

function DownlinkCmdQueue.consume(key) -- 出队
  if DownlinkCmdQueueTbl[key] == nil then
    return nil
  end
  if DownlinkCmdQueue.checkQueueLength(key) == 0 then
    return nil -- table.remove(DownlinkCmdQueueTbl, key)
  end
  local ret = DownlinkCmdQueueTbl[key].dequeue()
  if DownlinkCmdQueue.checkQueueLength(key) == 0 then
    --table.remove(DownlinkCmdQueueTbl, key)
  end
  return ret 
end

function DownlinkCmdQueue.produce(key, src) -- 入队
  if DownlinkCmdQueueTbl[key] == nil then
    DownlinkCmdQueueTbl[key] = queue.create()
  end
  return DownlinkCmdQueueTbl[key].enqueue(src)
end

function DownlinkCmdQueue.delete(key)  -- 删除对头元素
  return DownlinkCmdQueueTbl[key].dequeue()
end

-- DownlinkCmdQueue.prototype.trim = function (mq, start, end) {
--   let _this = this;
--   return _this._ioredis.ltrim(mq, start, end)
--     .then((res) => {
--       if (res == 'OK') {
--         return BluebirdPromise.resolve();
--       }

--       return BluebirdPromise.reject(new Error('DownlinkCmdQueue trim failed'));
--     });
-- }

return DownlinkCmdQueue
