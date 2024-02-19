local dgram = require('dgram')
local pPrint = require('pretty-print')
HOST = '127.0.0.1'
PORT = 9000
--Format:
--[Path][arguments][values]

--i hate this but here we go
--https://stackoverflow.com/a/39481287
local function splitByte(tValue)
    local text = string.format("%x",tValue)
    if (#text % 2 == 1) then text = "0"..text end
    local s = {}
    for i=1, #text, 2 do
        s[#s+1] = string.char(tonumber("0x"..text:sub(i,i+1)))
    end
    return s
end
-- usage example
--local st = splitByChunk("0123456789",3)
--for i,v in ipairs(st) do
--   print(i, v)
--end

--and continuing with the theme of stealing shit from stackoverflow, behold!
--https://stackoverflow.com/a/19996852
function float2hex (n)
    if n == 0.0 then return 0.0 end
    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end
    local mant, expo = math.frexp(n)
    local hext = {}
    if mant ~= mant then
        hext[#hext+1] = string.char(0xFF, 0x88, 0x00, 0x00)
    elseif mant == math.huge or expo > 0x80 then
        if sign == 0 then
            hext[#hext+1] = string.char(0x7F, 0x80, 0x00, 0x00)
        else
            hext[#hext+1] = string.char(0xFF, 0x80, 0x00, 0x00)
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
        hext[#hext+1] = string.char(sign, 0x00, 0x00, 0x00)
    else
        expo = expo + 0x7E
        mant = (mant * 2.0 - 1.0) * math.ldexp(0.5, 24)
        hext[#hext+1] = string.char(sign + math.floor(expo / 0x2),
                                    (expo % 0x2) * 0x80 + math.floor(mant / 0x10000),
                                    math.floor(mant / 0x100) % 0x100,
                                    mant % 0x100)
    end
    return tonumber(string.gsub(table.concat(hext),"(.)",
                                function (c) return string.format("%02X%s",string.byte(c),"") end), 16)
end

--that's enough of that

function valueSelect(value,type)
    if type == "f" then
        local oVal = ""
        local iVals = splitByte(string.format("%x",float2hex(value)))
        for j=1,#iVals do
            oVal = oVal..iVals[j]
        end
        return oVal
    elseif type == "i" then
        local oVal = ""
        local iVals = splitByte(value)
        for j=1,#iVals do
            oVal = oVal..iVals[j]
        end
        return oVal
    else
        return 0
    end
    --more types to be added
end




local function convertOSC(pregen)
    local OSCGen = ""
    for i,v in ipairs(pregen) do
        spacers = ""
        for i=1,(4-((string.len(v.Path .. "," .. v.Type .. '\000\000\000' .. valueSelect(v.Value,v.Type)))%4)) do spacers = spacers..'\000'end if string.len(spacers) == 4 then spacers = "" end
        OSCGen = OSCGen.. v.Path .. spacers .. "," .. v.Type ..'\000\000\000'.. valueSelect(v.Value,v.Type)
        print(string.len(OSCGen))

    end
    return OSCGen
end

print("Host: "..HOST)
print("Port: "..PORT)
OSCSock = dgram.createSocket("udp")

function onMessageOSC(msg,rinfo)
    print(msg)
    print(rinfo)
    OSCSock:close()
end
function onError(err)
    assert(err)
end
OSCSock:on('message', onMessageOSC)
OSCSock:on('error', onError)
OSCSock:send('/oscillator/5/frequency\000,i\000\000\000\220\000\000',PORT,HOST)--works?
--OSCSock:send('/osc/6/freq\000,T\000\000',PORT,HOST)--minimum 3 spaces?
--PATH
--space
--comma, arguments
--more space?
--value (4 bytes since its a float)



