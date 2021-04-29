local uv = require()
local client = uv.new_udp()
local req = assert(uv.udp_send(client, "sendData", '192.168.1.157', 12234, expect(function (err)
  p("client on send", client, err)
  assert(not err, err)
  uv.close(client, expect(function()
    p("client on close", client)
  end))
end)))
p{client=client,req=req}    