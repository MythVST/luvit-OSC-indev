local dgram = require('dgram')
local pPrint = require('pretty-print')

HOST = '127.0.0.1'
PORT = 9000
print("Host: "..HOST)
print("Port: "..PORT)

OSCSock = dgram.createSocket()

function onMessageOSC(msg,rinfo)
    print(msg)
    OSCSock:close()
end
function onError(err)
    assert(err)
end
OSCSock:on('message', onMessageOSC)
OSCSock:on('error', onError)
OSCSock:bind(PORT,HOST)