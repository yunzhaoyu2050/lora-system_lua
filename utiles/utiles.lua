local buffer = require("buffer").Buffer
local bit = require("bit")
local ffi = require("ffi")

-- 计算与值
-- @param offset 偏移
-- @param dataLen 数据长度
-- @return 0 入参错误 tmp 偏移后的值和
function CalcVersusValue(offset, dataLen)
  if offset == nil or dataLen == nil then
    return 0
  end
  local tmp = 0
  for i = offset, dataLen - 1 do
    tmp = tmp + bit.lshift(1, i)
  end
  return tmp
end

function BufferWrite(buf, offset, v, length)
  if type(offset) ~= "number" or offset < 1 or offset > buf.length then
    p("[buffer:write] Index out of bounds")
    return
  end
  if type(v) == "string" then
    length = length or #v
    ffi.copy(buf.ctype + offset - 1, v, length)
  elseif type(v) == "cdata" then
    if length > 0 then
      ffi.copy(buf.ctype + offset - 1, v, length)
    else
      p("[buffer:write] ctype must give length")
    end
  elseif v.ctype ~= nil and v.length ~= nil then -- Buffer
    length = length or v.length
    ffi.copy(buf.ctype + offset - 1, v.ctype, length)
  else
    p("[buffer:write] Input must be a string or cdata or Buffer")
    return
  end
end

-- buffer裁剪
-- @param buf 要裁剪的buffer对象
function BufferSlice(buf, offsetStart, offsetEnd)
  if buf.ctype == nil then
    p("buf must be a buffer type.")
    return nil
  end
  if offsetStart == nil then
    offsetStart = 1
  end
  if offsetEnd == nil then
    offsetEnd = buf.length
  end
  local newBuf = buffer:new(offsetEnd - offsetStart + 1)
  ffi.copy(newBuf.ctype, buf.ctype + offsetStart - 1, offsetEnd - offsetStart + 1)
  return newBuf
end

-- buffer连接
function BufferConcat(srcBuf, dstBuf)
  local newBuf = nil
  if type(srcBuf) == "table" and dstBuf == nil then
    local newBufLen = 0
    for i = 1, #srcBuf do
      newBufLen = newBufLen + srcBuf[i].length
    end
    newBuf = buffer:new(newBufLen)
    BufferFill(newBuf, 0)
    local offset = 0
    for i = 1, #srcBuf do
      if i == 1 then
        ffi.copy(newBuf.ctype, srcBuf[i].ctype, srcBuf[i].length)
      else
        ffi.copy(newBuf.ctype + offset + srcBuf[i - 1].length, srcBuf[i].ctype, srcBuf[i].length)
        offset = offset + srcBuf[i - 1].length
      end
      -- printBuf(newBuf)
    end
  else
    newBuf = buffer:new(srcBuf.length + dstBuf.length)
    ffi.copy(newBuf.ctype + 1 - 1, srcBuf.ctype, srcBuf.length)
    ffi.copy(newBuf.ctype + srcBuf.length, dstBuf.ctype, dstBuf.length)
  end
  return newBuf
end

-- buffer逆置
function reverse(buf)
  if buf.ctype == nil then
    p("buf must be a buffer type.")
    return nil
  end
  local bufTmp = buffer:new(buf.length)
  bufTmp = BufferCopy(bufTmp, 1, buf, 1, buf.length)
  for i = 1, bufTmp.length / 2 do
    local temp = bufTmp[i]
    bufTmp[i] = bufTmp[bufTmp.length - i + 1]
    bufTmp[bufTmp.length - i + 1] = temp
  end
  return bufTmp
end

-- 大端转小端
function BEToLE(buf)
  if buf.length <= 1 then
    return buf
  end
  return reverse(buf)
end

-- 小端转大端
function LEToBE(buf)
  if buf.length <= 1 then
    return buf
  end
  return reverse(buf)
end

function printBuf(buf)
  local head = "<buffer:"
  local sum = " "
  for i = 1, buf.length do
    sum = sum .. buf[i] .. " "
  end
  p("<buffer:" .. sum .. " >")
end

-- buffer转成hex格式的字符串
function BufferToHexString(buf, startIndex, endIndex)
  if startIndex == nil then
    startIndex = 1
  end
  if endIndex == nil then
    endIndex = buf.length
  end
  local sum = nil
  for i = startIndex, endIndex do
    if sum == nil then
      sum = tostring(bit.tohex(buf[i], 2))
    else
      sum = sum .. tostring(bit.tohex(buf[i], 2))
    end
  end
  return sum
end

function ToHex(dst, src)
  local j = 1
  for i = 1, src.length, 1 do
    dst[j] = bit.tohex(src[i], 2)
    j = j + 1
  end
end

local function ascii2num(a)
  local v = 0
  if a >= string.byte("a") and a <= string.byte("z") then
    a = a - 32
  end
  if a >= string.byte("0") and a <= string.byte("9") then
    v = a - 48
  elseif a >= string.byte("A") and a <= string.byte("Z") then
    v = a - 65 + 10
  end
  return v
end

-- hex格式的字符串转成buffer 不转成网络字节序 需要手动转序
-- @param flag true:开启网络字节序转换 false:关闭
-- @return 返回原始buffer
function BufferFromHexString(buf, startIndex, str, flag)
  if type(str) ~= "string" then
    p("str must be string type")
    return nil
  end
  if buf.ctype == nil then
    p("buf must be buffer type")
    return nil
  end
  if startIndex == nil then
    startIndex = 1
  end
  if flag ~= nil and flag == true then
    local len = #str
    local ii = len + 1
    for i = 1, len, 2 do
      local tmp = string.sub(str, ii - 2, ii - 1) -- 字符串 16进制 内容
      buf[startIndex] = bit.lshift(ascii2num(string.byte(tmp, 1)), 4) + ascii2num(string.byte(tmp, 2))
      startIndex = startIndex + 1
      ii = ii - 2
    end
  else
    for i = 1, #str - 1, 2 do
      local tmp = string.sub(str, i, i + 1) -- 字符串 16进制 内容
      buf[startIndex] = bit.lshift(ascii2num(string.byte(tmp, 1)), 4) + ascii2num(string.byte(tmp, 2))
      startIndex = startIndex + 1
    end
  end
  return buf
end

function BufferToAsciiString(buf)
  local sum = nil
  for i = 1, buf.length do
    if sum == nil then
      sum = string.char(buf[i])
    else
      sum = sum .. string.char(buf[i])
    end
  end
  return sum
end

-- buffer间复制
function BufferCopy(targetBuffer, targetStart, sourceBuffer, sourceStart, sourceEnd)
  local buf = nil
  if type(sourceBuffer) == "string" then
    buf = buffer:new(sourceBuffer)
  end
  if sourceBuffer.ctype ~= nil and sourceBuffer.length ~= nil then
    buf = sourceBuffer
  end
  if buf ~= nil then
    if targetStart == nil then
      targetStart = 1
    end
    if sourceStart == nil then
      sourceStart = 1
    end
    if sourceEnd == nil then
      sourceEnd = buf.length
    end
    for i = sourceStart, sourceEnd, 1 do
      targetBuffer[targetStart] = buf[i]
      targetStart = targetStart + 1
      if targetStart > targetBuffer.length or (i + 1) > buf.length then
        break
      end
    end
    return targetBuffer
  end
  p("sourceBuffer type not support,must be string buffer")
  return nil
end

-- buffer填充
function BufferFill(targetBuffer, val, startIndex, endIndex)
  -- TODO: 检测输入类型是否是buffer
  if startIndex == nil then
    startIndex = 1
  end
  if endIndex == nil or endIndex > targetBuffer.length then
    endIndex = targetBuffer.length
  end
  for i = startIndex, endIndex, 1 do
    targetBuffer[i] = val
  end
end

function BufferXor(buf1, buf2)
  for ind = 1, buf1.length do
    buf1[ind] = bit.bxor(buf1[ind], buf2[ind])
  end
  return buf1
end

function BufferFrom(src)
  local newBuf = buffer:new(src.length)
  newBuf = BufferCopy(newBuf, 1, src, 1, src.length)
  return newBuf
end

function BufferToTable(srcBuffer)
  local tmp = {}
  for i = 1, srcBuffer.length, 1 do
    tmp[i] = srcBuffer[i]
  end
  return tmp
end

function numToHexBuf(num, buf_len)
  -- if buf_len == nil or num < 0 then
  --   return buffer:new(0);
  -- end
  -- local str = num.toString(16);
  -- local str_len = buf_len * 2;
  -- local tmp = Buffer.alloc(buf_len).toString('hex');
  -- local fill_len = str_len - str.length;
  -- if (fill_len >= 0) then
  --   str = tmp.substr(0, fill_len) + str;
  -- else
  --   str = str.substr(fill_len);
  -- end
  -- return Buffer.from(str, 'hex');
end

function numToBuf(num, buf_len)
  local newBuf = buffer:new(1)
  -- for i=1, buf_len do
  --   newBuf[i] = num
  -- end
  newBuf[1] = num
  return newBuf
end

-- bit写值
-- @param objByte typebuffer
-- @param value type:number
function bitwiseAssigner(objByte, offset, len, value)
  local baseBits = math.pow(2, len) - 1
  local filterBits = bit.lshift(baseBits, offset)
  -- All the bitwise operations are based on 32 bits-length int
  -- THEREFORE, GET THE LEAST-SIGNIFICANT 8 BITS BY & 0xFF IS CRITICAL!!
  -- BUFFER NEEDS TO BE READED AS UINT BEFORE BITWISE OPERATIONS
  local srcBits = bit.band(bit.band(objByte:readUInt8(1), bit.bnot(filterBits)), 0xFF)
  local destBits = bit.band(bit.lshift(value, offset), filterBits)
  objByte:writeUInt8(1, srcBits + destBits)
  return objByte
end

-- switch
local Default, Nil = {}, function()
  end -- for uniqueness
function switch(i)
  return setmetatable(
    {i},
    {
      __call = function(t, cases)
        local item = #t == 0 and Nil or t[1]
        return (cases[item] or cases[Default] or Nil)(item)
      end
    }
  )
end

-- 索引值是否在表中存在
-- @param tbl 表
-- @param val 数值
-- @return true, false
local function IsIndexInList(tbl, val)
  local cmd
  if type(val) == "string" then
    cmd = tonumber(val)
  elseif type(val) == "number" then
    cmd = val
  else
    return nil
  end
  for k, _ in pairs(tbl) do
    if k == cmd then
      return true
    end
  end
  return false
end

-- 数值是否在表中存在
-- @param tbl 表
-- @param val 数值
-- @return true, false
local function IsValueInList(tbl, val)
  for _, v in pairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

return {
  CalcVersusValue = CalcVersusValue,
  BufferSlice = BufferSlice,
  BufferWrite = BufferWrite,
  BufferToHexString = BufferToHexString,
  BufferCopy = BufferCopy,
  BufferFill = BufferFill,
  BufferToTable = BufferToTable,
  BufferConcat = BufferConcat,
  BufferFrom = BufferFrom,
  BufferFromHexString = BufferFromHexString,
  BufferToAsciiString = BufferToAsciiString,
  BEToLE = BEToLE,
  LEToBE = LEToBE,
  numToBuf = numToBuf,
  reverse = reverse,
  printBuf = printBuf,
  bitwiseAssigner = bitwiseAssigner,
  switch = switch,
  Default = Default,
  BufferXor = BufferXor,
  Nil = Nil,
  IsIndexInList = IsIndexInList,
  IsValueInList = IsValueInList
}
