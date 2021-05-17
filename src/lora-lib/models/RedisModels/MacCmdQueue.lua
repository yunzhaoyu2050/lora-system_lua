local queue = require("../../../../deps/Dee_LuaADT/queue.lua")

local MacCmdQueueTbl = {}
local MacCmdQueue = {}

function MacCmdQueue.read(devaddr)
  return MacCmdQueueTbl[devaddr].dequeue()
end

function MacCmdQueue.consumeAll(devaddr)
  if MacCmdQueueTbl[devaddr] == nil then
    MacCmdQueueTbl[devaddr] = queue.create()
  end
  local out = {
    length = #MacCmdQueueTbl[devaddr]
  }
  for i = 1, #MacCmdQueueTbl[devaddr] do
    out[i] = MacCmdQueueTbl[devaddr].dequeue()
  end
  return out
end

return MacCmdQueue
