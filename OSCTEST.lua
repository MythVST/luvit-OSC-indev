--start by requiring some basics
local dgram = require('dgram')
local pPrint = require('pretty-print')
--set up port and ip
HOST = '127.0.0.1'
PORT = 9000
--
--todo: Strings.




--test functions. see if they're worth using
--initialize function splitByte
local function splitByte(tValue)

    local text = string.format("%x",tValue) --formats it into hex
    if (#text % 2 == 1) then text = "0"..text end -- impends a 0 to the input text if it detects an odd amount of chars
    local s = {}--init string table
    for i=1, #text, 2 do --
        s[#s+1] = string.char(tonumber("0x"..text:sub(i,i+1)))--does the actual work
    end
    bytestring = "" -- initializes the string for outputting
    for i=1,#s do
        bytestring = bytestring..s[i]--puts all of the strings together into one
    end
    return bytestring
end
--Testing shows splitByte is working and worth keeping.
--SB can be used alone on ints or in conjunction with a processed float

--initialize float2hex
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
--float2hex works as intended.
--packVal & packStr
function packVal(pakV)
    padding = 4 - ((#pakV)%4)
    outS = pakV
    for i=1, padding do
        outS = '\000'..outS
    end
    return outS
end

function packStr(pakS)
    padding = 4 - ((#pakS)%4)
    outS = pakS
    for i=1, padding do
        outS = outS..'\000'
    end
    return outS
end

function onMessageOSC(msg,rinfo)
    print(msg)
    print('boob')
end
function onError(err)
    assert(err)
end
--start websocketry
--declare message function
OSCserver = dgram.createSocket()
path = packStr("/Test/Value")
pArgs = packStr(",iifsf")
outMessage = packVal(splitByte(1234))..packVal(splitByte(5678))..splitByte(float2hex(1.234))..packStr("Hello World!")..splitByte(float2hex(567.8))
print(HOST..":"..PORT)
--print(#path)
--print(#pArgs)
--print(#outMessage)
OSCserver:send(path..pArgs..outMessage,PORT,HOST)
OSCserver:on('message',onMessageOSC)

--deconstructed
--path part begins with a forward slash and a name.
--Subpaths are doable too.
-- "/Test/Value"
-- the path, being a string, must be padded out to a multiple of 4 bytes, which is doable with packStr("/Test/Value") or manually by counting the chars and adding nulls at the end "/Test/Value\000"
-- "/Test/Value\000"
--onto the arguments
--start with a comma, and then list out the types of data being sent.
--",ifs"
--i for int, f for float, s for string
--this part must once again be padded. luckily, it's already a multiple of 4 right now, so no work needs done.
--now onto the values
--all values must be converted to ascii representations of themselves. don't do this manually. use splitByte(value) to split up a numeric value.
--for ints, just splitBtye(value) is necessary. for floats though, you'll need to use splitByte(float2hex(value))
--padding is once again necessary (at least with ints. thanks to standardization, floats are already padded). this time, in front of the value instead of behind it, which is what packVal is for.
--packVal(splitByte(1234)) outputs '\000\000\004\210' and '\068\013\243\051' is the result of splitBtye(float2hex(567.8))
--strings can be packed with packStr still. packStr("Hello World!"") results in "Hello World!\000\000\000\000". It should be noted that all strings should terminate in a null character *before* packing
--putting it all together, we come out with this
--"/Test/Value\000,ifs\000\000\004\210\068\013\243\051Hello World!\000\000\000\000"
--running print(#"/Test/Value\000,ifs\000\000\004\210\068\013\243\051Hello World!\000\000\000\000") gives us 40. it's always good to verify that your strings work


--todo: RGB
--rgb doesn't seem to get noticed by protokol :(
