local utils = require("utils")
local RegionGpu = require("ui.windows").RegionGpu  -- for handling border cases
local M = {}


local function strReplace(line, pos, text)
    assert(pos > 0)
    local len = utils.strlen(text)
    return (
        utils.strsub(line, 1, pos - 1) ..
        text ..
        utils.strsub(line, pos + len)
    )
end


local function createFilledPlane(width, height, char)
    assert(utils.strlen(char) == 1)
    local plane = {}
    for y=1,height do
        plane[y] = string.rep(char, width)
    end
    return plane
end


local function getSubPlane(plane, x, y, w, h)
    local r = {}
    for iy=1,h do
        local line = plane[y + iy - 1]
        r[iy] = utils.strsub(line, x, x + w - 1)
    end
    return r
end


local function setSubPlane(plane, x, y, subplane)
    for iy, line in ipairs(subplane) do
        plane[y + iy - 1] = strReplace(plane[y + iy - 1], x, line)
    end
end


function M.createGPU(width, height, colorBox)
    local currentColor = "X"
    local currentBackground = "X"
    local currentColorValue
    local currentBackgroundValue

    local textLines = createFilledPlane(width, height, "¶")
    local colorLines = createFilledPlane(width, height, currentColor)
    local backgroundLines = createFilledPlane(width, height, currentBackground)

    local function pickColor(color)
        local r = colorBox[color]
        if r == nil then r = "X" end
        assert(utils.strlen(r) == 1)
        return r
    end

    local function replace(x, y, text)
        local len = utils.strlen(text)
        textLines[y] = strReplace(
            textLines[y], x, text)
        colorLines[y] = strReplace(
            colorLines[y], x, string.rep(currentColor, len))
        backgroundLines[y] = strReplace(
            backgroundLines[y], x, string.rep(currentBackground, len))
    end

    local gpu = RegionGpu({
        getResolution=function()
            return width, height
        end,
        fill=function(x, y, w, h, char)
            assert(utils.strlen(char) == 1)
            for row=y,y+h-1 do
                replace(x, y, string.rep(char, w))
            end
            return true
        end,
        set=function(x, y, s)
            replace(x, y, s)
            return true
        end,
        getForeground=function()
            return currentColorValue
        end,
        setForeground=function(v)
            local result = currentColorValue
            currentColor = pickColor(v)
            currentColorValue = v
            return result
        end,
        getBackground=function()
            return currentBackgroundValue
        end,
        setBackground=function(v)
            local result = currentBackgroundValue
            currentBackground = pickColor(v)
            currentBackgroundValue = v
            return result
        end,
        copy=function(x, y, w, h, tx, ty)
            for _, plane in ipairs{textLines, colorLines, backgroundLines} do
                setSubPlane(plane, x + tx, y + ty, getSubPlane(plane, x, y, w, h))
            end
            return true
        end
    }, 1, 1, width, height)

    gpu.getTextResult=function(stripTail)
        if not stripTail then return textLines end
        local m = string.rep("¶", width)
        local cutter = height
        for y=height,1,-1 do
            if textLines[y] == m then
                cutter = y - 1
            else
                break
            end
        end
        local r = {}
        for y=1,cutter do table.insert(r, textLines[y]) end
        return r
    end
    gpu.getColorResult=function()
        return colorLines
    end
    gpu.getBackgroundResult=function()
        return backgroundLines
    end
    return gpu
end


M.testing = {
    strReplace=strReplace
}

return M
