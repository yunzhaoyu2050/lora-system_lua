local queue = require("../deps/Dee_LuaADT/queue.lua")
-- lua table
local cnt = 10000 * 1

local t = {}
for i=1,cnt do
t[i] = i
end

local time = os.clock()
while #t > 0 do
-- table.remove(t)
	table.remove(t, 1)
end
print(os.clock() - time)
---1.037s

local v = queue.create()

for i=1,cnt do
	v.enqueue(i)
end

print("len:",#v)
local len = v.len
local time1 = os.clock()
while #v > 10 do
	v.dequeue()
end
print(os.clock() - time1)
---0.005s