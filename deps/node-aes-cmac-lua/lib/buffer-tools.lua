-- Design By https://github.com/allan-stewart/node-aes-cmac.git

local _buffer = require("buffer").Buffer
local bit = require("bit")

-- @param buffer is buffer type
function bitShiftLeft(buffer)
  local shifted = _buffer:new(buffer.length)
  local last = buffer.length
  for index = 1, last - 1, 1 do
    shifted[index] = bit.lshift(buffer[index], 1)
    if bit.band(buffer[index + 1], 0x80) ~= 0 then
      shifted[index] = shifted[index] + 0x01
    end
  end
  shifted[last] = bit.lshift(buffer[last], 1)
  return shifted
end

function xor(bufferA, bufferB)
  local length = math.min(bufferA.length, bufferB.length)
  local output = _buffer:new(length)
  for index = 1, length, 1 do
    output[index] = bit.bxor(bufferA[index], bufferB[index])
  end
  return output
end

-- var bitmasks = [0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01];

-- exports.toBinaryString = function (buffer) {
--   var binary = '';
--   for (var bufferIndex = 0; bufferIndex < buffer.length; bufferIndex++) {
--     for (var bitmaskIndex = 0; bitmaskIndex < bitmasks.length; bitmaskIndex++) {
--       binary += (buffer[bufferIndex] & bitmasks[bitmaskIndex]) ? '1' : '0';
--     }
--   }
--   return binary;
-- }

return {
  bitShiftLeft = bitShiftLeft,
  xor = xor
}
