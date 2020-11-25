local guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
local encode_b64 = ApolloLive.Tools.base64.encode
local sha1 = ApolloLive.Tools.sha1
local log = ApolloLive.Log
local bit = ApolloLive.Libs.bit
local socket = ApolloLive.Libs.socket
local tobytes = string.char
local rshift = bit.rshift
local client
local server = assert(socket.bind("*", 55666))
local ip, port = server:getsockname()
local MAX_MESSAGE_SIZE = 4294967295

server:settimeout(0)
log("Listening for connections at: "..ip..":"..port)

local Connection = { Status = 'closed' }
local ch, line, sent, err


local makeHandshake = function ()
  line, err = client:receive('*l')
  if line ~= 'GET / HTTP/1.1'
  then
    log("Invalid HTTP Upgrade Request")
    Connection.Close()
    return
  end

  local key
  while line ~= "" do
    line, err = client:receive('*l')
    local name,val = line:match('([^%s]+)%s*:%s*([^\r\n]+)')
    if name then
      if name:match('Sec%-WebSocket%-Key') then
        key = val
      end
    end
  end

  local res = {
    'HTTP/1.1 101 Switching Protocols',
    'Upgrade: websocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Accept: '..encode_b64(sha1(key..guid)),
    'Sec-WebSocket-Protocol: Apollo',
  }

  sent, err = client:send(table.concat(res, '\r\n')..'\r\n\r\n')
  if sent then
    Connection.Status = 'open'
    log('Handshake successful: '..sent)
  else
    Connection.Status = 'closed'
    log('Handshake err: '..err)
  end
end


Connection.Open = function ()
  client, err = server:accept()
  if client then
    Connection.Status = 'connecting'
    client:settimeout(0)
    log("Accepting connection from: "..client:getpeername())
    makeHandshake()
    ApolloLive.Update()
  end
end


Connection.Close = function ()
  Connection.Status = 'closing'
  repeat ch, err = client:receive(1)
  until err
  client:send(tobytes(136, 0))
  client:close()
  Connection.Status = 'closed'
  log('Connection Closed: '..err)
end


Connection.Send = function (msg)
  local msg_len = #msg
  if msg_len > MAX_MESSAGE_SIZE then
    log('Warning: Exceeded Max Message size. Message not sent.')
    return
  end
  -- log('sending websocket frame')
  sent, err = client:send(tobytes(129))
  if not err then
    if msg_len < 126 then
      sent, err = client:send(tobytes(msg_len))
    elseif msg_len < 65536 then
      -- log('sending medium message')
      client:send(tobytes(
        126,
        rshift(msg_len, 8),
        msg_len % 256
      ))
    else
      -- log('sending large message')
      sent, err = client:send(tobytes(
        127, 0, 0, 0, 0,
        rshift(msg_len, 24),
        rshift(msg_len, 16) % 256,
        rshift(msg_len, 8) % 256,
        msg_len % 256
      ))
    end
    sent, err = client:send(msg)
    if sent then
      log('sent: '..sent..' bytes.')
    end
  end
  if err then Connection.Close() end
end


Connection.Pong = function ()
  ch, err = client:receive(1)
  if err then
    sent, err = client:send(tobytes(138, 4))
    sent, err = client:send('pong')
    if sent then return end
  end
  Connection.Close()
end


ApolloLive.Send = function (...)
  if Connection.Status ~= 'open' then return end
  for i = 1, select('#', ...) do
    local payload = select(i, ...)
    Connection.Send(TableToJSONString({
      type = type(payload),
      payload = payload,
    }))
  end
end


ApolloLive.Connection = Connection
log('loaded Connection.lua')
