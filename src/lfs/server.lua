local log = require("log")
local device = require("device")

-- enable discovery
if require("settings").discovery ~= false then
  log.info('UPnP:', 'Listening for UPnP disc')
  net.multicastJoin(wifi.sta.getip(), '239.255.255.250')
  local upnp = net.createUDPSocket()
  upnp:listen(1900, '0.0.0.0')
  upnp:on('receive', function(c, d, port, ip)
    require('ssdp_response')(c, d, port, ip)
  end)

  -- broadcast SSDP NOTIFY
  tmr.create():alarm(15000, tmr.ALARM_SINGLE, function()
    upnp:send(1900, '239.255.255.250', require('ssdp_notify')('upnp:rootdevice', '::upnp:rootdevice'))
    upnp:send(1900, '239.255.255.250', require('ssdp_notify')(device.id, ''))
    upnp:send(1900, '239.255.255.250', require('ssdp_notify')(device.urn, '::' .. device.urn))
    log.info('UPnP:', 'Sent SSDP NOTIFY')
  end)
end

-- enable HTTP server
log.info("HTTP: server at http://" .. wifi.sta.getip() .. ":" .. device.http_port)
local http = net.createServer(net.TCP, 10)
http:listen(device.http_port, function(conn)
  conn:on("receive", function(c, payload)
    require("server_receiver")(c, payload)
  end)
end)

