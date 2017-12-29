local utils = require("utils")
local RegionGpu = require("ui.regionGpu").RegionGpu  -- for handling border cases
local M = {}


-- Colors


local MAX_COLOR = 0x1000000


function M.packColor(color, isPalette)
    if isPalette then
        return MAX_COLOR + color
    else
        return color
    end
end


function M.unpackColor(pcolor)
    if pcolor >= MAX_COLOR then
        return pcolor - MAX_COLOR, true
    else
        return pcolor, false
    end
end


-- Test gpu


local PREFILL = "¶"
assert(utils.strlen(PREFILL) == 1)


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
    local currentColor = PREFILL
    local currentBackground = PREFILL
    local currentColorValue
    local currentBackgroundValue

    local textLines = createFilledPlane(width, height, PREFILL)
    local colorLines = createFilledPlane(width, height, PREFILL)
    local backgroundLines = createFilledPlane(width, height, PREFILL)

    local function pickColor(color)
        local r = colorBox[color]
        if r == nil then r = PREFILL end
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
        get=function(x, y)
            return utils.strsub(textLines[y], x, x), 0xFFFFFF, 0x000000
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
        local m = string.rep(PREFILL, width)
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


-- Consistency test functions


local testFuncs = {
    fillWide=function(gpu)
        gpu.fill(1, 1, 3, 3, "シ")
        return 6, 3
    end,
    fillUnaligned=function(gpu)
        gpu.fill(1, 1, 3, 3, "シ")
        gpu.fill(2, 1, 2, 3, "ネ")
        return 6, 3
    end,
    setWide=function(gpu)
        gpu.set(1, 1, "abc")
        gpu.set(1, 1, "シ")
        return 4, 1
    end,
    setWideUnaligned=function(gpu)
        gpu.set(1, 1, "シシシシ")
        gpu.set(1, 2, "シシシシ")

        gpu.set(2, 1, "abcdef")
        gpu.set(2, 2, "ネエミ")
        return 8, 2
    end,
    copyWideUnaligned=function(gpu)
        for y=1,4 do
            gpu.set(2, y, "カタカナ")
        end
        gpu.copy(2, 1, 4, 1, -1, 0)
        gpu.copy(2, 2, 8, 1, -1, 0)
        gpu.copy(2, 3, 4, 1, 1, 0)
        gpu.copy(2, 4, 8, 1, 1, 0)
        return 10, 4
    end
}


-- Consistency with real GPU


local function getGpuRegion(gpu, w, h)
    local textBuf, fgBuf, bgBuf = {}, {}, {}
    for y=1,h do
        textBuf[y] = {}
        fgBuf[y] = {}
        bgBuf[y] = {}
        for x=1,w do
            local char, fc, bc, fpal, bpal = gpu.get(x, y)
            textBuf[y][x] = char
            fgBuf[y][x] = fpal ~= nil and M.packColor(fpal, true) or M.packColor(fc, false)
            bgBuf[y][x] = bpal ~= nil and M.packColor(bpal, true) or M.packColor(bc, false)
        end
    end
    return textBuf, fgBuf, bgBuf
end


local function getGpuResult(gpu, testFunc)
    local w, h = gpu.getResolution()
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)
    gpu.fill(1, 1, w, h, " ")
    return getGpuRegion(gpu, testFunc(gpu))
end


local function gatherGpuResults()
    local gpu = require("component").gpu
    local r = {}
    for k, func in pairs(testFuncs) do
        r[k] = {getGpuResult(gpu, func)}
    end
    local f = assert(io.open("gpuResult_auto.lua", "w"))
    f:write("return ")
    f:write(require("serialization").serialize(r, false))
    f:close()
end


-- require("lib.renderTest").consistency.gatherGpuResults()


-- Module


M.testing = {
    strReplace=strReplace
}
M.consistency = {
    testFuncs=testFuncs,
    getGpuResult=getGpuResult,
    gatherGpuResults=gatherGpuResults
}
return M
