local MAX_COLOR = 0x1000000


function packColor(color, isPalette)
    if isPalette then
        return MAX_COLOR + color
    else
        return color
    end
end


function unpackColor(pcolor)
    if pcolor >= MAX_COLOR then
        return pcolor - MAX_COLOR, true
    else
        return pcolor, false
    end
end


return {
    packColor=packColor,
    unpackColor=unpackColor
}
