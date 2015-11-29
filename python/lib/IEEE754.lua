function PackIEEE754SP(number)
    if number == 0 then
        return string.char(0x00, 0x00, 0x00, 0x00)
    elseif number ~= number then
        return string.char(0xFF, 0xFF, 0xFF, 0xFF)
    else
        local sign = 0x00
        if number < 0 then
            sign = 0x80
            number = -number
        end
        local mantissa, exponent = math.frexp(number)
        exponent = exponent + 0x7F
        if exponent <= 0 then
            mantissa = math.ldexp(mantissa, exponent - 1)
            exponent = 0
        elseif exponent > 0 then
            if exponent >= 0xFF then
                return string.char(sign + 0x7F, 0x80, 0x00, 0x00)
            elseif exponent == 1 then
                exponent = 0
            else
                mantissa = mantissa * 2 - 1
                exponent = exponent - 1
            end
        end
        mantissa = math.floor(math.ldexp(mantissa, 23) + 0.5)
        return string.char(
                sign + math.floor(exponent / 2),
                (exponent % 2) * 0x80 + math.floor(mantissa / 0x10000),
                math.floor(mantissa / 0x100) % 0x100,
                mantissa % 0x100)
    end
end
function UnpackIEEE754SP(packed)
    local b1, b2, b3, b4 = string.byte(packed, 1, 4)
    local exponent = (b1 % 0x80) * 0x02 + math.floor(b2 / 0x80)
    local mantissa = math.ldexp(((b2 % 0x80) * 0x100 + b3) * 0x100 + b4, -23)
    if exponent == 0xFF then
        if mantissa > 0 then
            return 0 / 0
        else
            mantissa = math.huge
            exponent = 0x7F
        end
    elseif exponent > 0 then
        mantissa = mantissa + 1
    else
        exponent = exponent + 1
    end
    if b1 >= 0x80 then
        mantissa = -mantissa
    end
    return math.ldexp(mantissa, exponent - 0x7F)
end



local function PackIEEE754DP(number)
    if number == 0 then
        return string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    elseif number ~= number then
        return string.char(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF)
    else
        local sign = 0x00
        if number < 0 then
            sign = 0x80
            number = -number
        end
        local mantissa, exponent = math.frexp(number)
        exponent = exponent + 0x3ff
        if exponent <= 0 then
            mantissa = math.ldexp(mantissa, exponent - 1)
            exponent = 0
        elseif exponent > 0 then
            if exponent >= 0x800 then
                return string.char(sign + 0x7F, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
            elseif exponent == 1 then
                exponent = 0
            else
                mantissa = mantissa * 2 - 1
                exponent = exponent - 1
            end
        end
        mantissa = math.floor(math.ldexp(mantissa, 52) + 0.5)
        return string.char(
                sign + math.floor(exponent / 2^4),
                (exponent % (2^4)) * 0x10 + math.floor(mantissa / 0x1000000000000),
                math.floor(mantissa / 0x10000000000) % 0x100, 
                math.floor(mantissa / 0x100000000) % 0x100, 
                math.floor(mantissa / 0x1000000) % 0x100, 
                math.floor(mantissa / 0x10000) % 0x100, 
                math.floor(mantissa / 0x100) % 0x100, 
                math.floor(mantissa) % 0x100)
    end
end
local function UnpackIEEE754DP(packed)
    local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(packed, 1, 8)
    local exponent = ((b1 % 0x80) * 0x10 + math.floor(b2 / 0x10))
    local mantissa = math.ldexp(((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7)*0x100 + b8, -52)
    if exponent == 0x800 then
        if mantissa > 0 then
            return 0 / 0
        else
            mantissa = math.huge
            exponent = 0x800-1
        end
    elseif exponent > 0 then
        mantissa = mantissa + 1
    else
        exponent = exponent + 1
    end
    if b1 >= 0x80 then
        mantissa = -mantissa
    end
    return math.ldexp(mantissa, exponent - 0x3ff)
end




return {encodeSP=PackIEEE754SP, decodeSP=UnpackIEEE754SP, encodeDP=PackIEEE754DP, decodeDP=UnpackIEEE754DP}
