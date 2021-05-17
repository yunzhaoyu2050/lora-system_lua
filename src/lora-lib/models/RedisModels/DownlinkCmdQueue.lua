-- local utiles = require("../../utiles/utiles.lua")
local queue = require("../../../../deps/Dee_LuaADT/queue.lua")

local DownlinkCmdQueueTbl = {}
local DownlinkCmdQueue = {}

DownlinkCmdQueue.table = DownlinkCmdQueueTbl

function DownlinkCmdQueue.checkQueueLength(devaddr) -- 获取队列长度
  return #DownlinkCmdQueueTbl[devaddr]
end

function DownlinkCmdQueue.getAll(devaddr) -- 获取所有元素
  if DownlinkCmdQueueTbl[devaddr] == nil then
    DownlinkCmdQueueTbl[devaddr] = queue.create()
  end
  local out = {
    length = #DownlinkCmdQueueTbl[devaddr]
  }
  for i = 1, #DownlinkCmdQueueTbl[devaddr] do
    out[i] = DownlinkCmdQueueTbl[devaddr].dequeue()
  end
  return out
end

function DownlinkCmdQueue.removeAll(devaddr) -- 删除所有元素
  DownlinkCmdQueueTbl[devaddr].clear()
end

function DownlinkCmdQueue.consume(devaddr) -- 出队
  return DownlinkCmdQueueTbl[devaddr].dequeue()
end

function DownlinkCmdQueue.produce(devaddr, src) -- 入队
  if DownlinkCmdQueueTbl[devaddr] == nil then
    DownlinkCmdQueueTbl[devaddr] = queue.create()
  end
  return DownlinkCmdQueueTbl[devaddr].enqueue(src)
end

function DownlinkCmdQueue.delete(devaddr)  -- 删除对头元素
  return DownlinkCmdQueueTbl[devaddr].dequeue()
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
