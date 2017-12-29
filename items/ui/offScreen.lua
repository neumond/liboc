local utils = require("utils")
local colorMod = require("lib.gpu.color")
local packColor = colorMod.packColor
local unpackColor = colorMod.unpackColor
local defaultPalette = require("lib.gpu.gpuPalette_auto")


local NaiveBuffer = utils.makeClass(function(self)
    self.width = 160  -- tier 3 screen resolution by default
    self.height = 50
    self.textBuf = {}
    self.colorBuf = {}
    self.backgroundBuf = {}
    self.color = packColor(0xFFFFFF, false)
    self.background = packColor(0x000000, false)
    self.palette = utils.copyTable(defaultPalette)
end)


function NaiveBuffer:getResolution()
    return self.width, self.height
end


function NaiveBuffer:setResolution(width, height)
    self.width = width
    self.height = height
end


function NaiveBuffer:setForeground(color, isPalette)
    local r, p = unpackColor(self.color)
    self.color = packColor(color, isPalette)
    return r, p
end


function NaiveBuffer:setBackground(color, isPalette)
    local r, p = unpackColor(self.background)
    self.background = packColor(color, isPalette)
    return r, p
end


function NaiveBuffer:getPaletteColor(index)
    return self.palette[index]
end


function NaiveBuffer:setPaletteColor(index, value)
    local r = self.palette[index]
    self.palette[index] = value
    return r
end


function NaiveBuffer:setChar(x, y, char, charWidth)
    if x + charWidth - 1 > self.width then return false end
    if self.textBuf[y] == nil then
        self.textBuf[y] = {}
        self.colorBuf[y] = {}
        self.backgroundBuf[y] = {}
    end
    if self.textBuf[y][x] == false then return false end  -- skip wide char extension
    self.textBuf[y][x] = char
    self.colorBuf[y][x] = self.color
    self.backgroundBuf[y][x] = self.background
    for j=2,charWidth do
        local m = x + j - 1
        self.textBuf[y][m] = false
        self.colorBuf[y][m] = self.color
        self.backgroundBuf[y][m] = self.background
    end
    local xx = x + charWidth
    while self.textBuf[y][xx] == false do
        self.textBuf[y][xx] = " "
        xx = xx + 1
    end
    return true
end


function NaiveBuffer:set(x, y, value, vertical)
    local inc
    if vertical then
        inc = function() y = y + 1 end
    else
        inc = function(width) x = x + width end
    end
    for char, width in utils.iterChars(value) do
        self:setChar(x, y, char, width)
        inc(width)
    end
end


function NaiveBuffer:get(x, y)
    if (x <= 0) or (y <= 0) then error("index out of bounds") end
    local char = self.textBuf[y][x]
    if char == false then char = " " end
    local fc, fpal = unpackColor(self.colorBuf[y][x])
    local bc, bpal = unpackColor(self.backgroundBuf[y][x])
    local fidx, bidx
    if fpal then
        fidx = fc
        fc = self.palette[fc]
    end
    if bpal then
        bidx = bc
        bc = self.palette[bc]
    end
    return char, fc, bc, fidx, bidx
end


function NaiveBuffer:fill(x, y, w, h, char)
    local filler = utils.strsub(char, 1, 1)
    local width = utils.charWidth(filler)
    for yy=y,y + h - 1 do
        for xx=x,x + (w - 1) * width,width do
            self:setChar(xx, yy, filler, width)
        end
    end
end


function NaiveBuffer:copy(x, y, w, h, tx, ty)
    local textSubplane, colorSubplane, backgroundSubplane = {}, {}, {}
    local tails = {}
    for dy=1,h do
        local cy = y + dy - 1
        textSubplane[dy] = {}
        colorSubplane[dy] = {}
        backgroundSubplane[dy] = {}
        tails[dy] = 0
        for dx=1,w do
            local cx = x + dx - 1
            textSubplane[dy][dx] = self.textBuf[cy][cx]
            colorSubplane[dy][dx] = self.colorBuf[cy][cx]
            backgroundSubplane[dy][dx] = self.backgroundBuf[cy][cx]
        end
        local cx = x + w
        while self.textBuf[cy][cx] == false do
            tails[dy] = tails[dy] + 1
            self.textBuf[cy][cx] = " "
            cx = cx + 1
        end
    end

    for dy=1,h do
        local cy = y + dy - 1 + ty
        for dx=1,w do
            local cx = x + dx - 1 + tx
            self.textBuf[cy][cx] = textSubplane[dy][dx]
            self.colorBuf[cy][cx] = colorSubplane[dy][dx]
            self.backgroundBuf[cy][cx] = backgroundSubplane[dy][dx]
        end
        local cx = x + w + tx - 1
        for i=1,tails[dy] do
            self.textBuf[cy][cx + i] = false
        end
    end
end


function NaiveBuffer:getGpuInterface()
    return {
        getResolution=function(...)
            return self:getResolution(...)
        end,
        setResolution=function(...)
            return self:setResolution(...)
        end,
        setForeground=function(...)
            return self:setForeground(...)
        end,
        setBackground=function(...)
            return self:setBackground(...)
        end,
        getPaletteColor=function(...)
            return self:getPaletteColor(...)
        end,
        setPaletteColor=function(...)
            return self:setPaletteColor(...)
        end,
        get=function(...)
            return self:get(...)
        end,
        set=function(...)
            return self:set(...)
        end,
        fill=function(...)
            return self:fill(...)
        end,
        copy=function(...)
            return self:copy(...)
        end
    }
end


return {
    NaiveBuffer=NaiveBuffer,
    Buffer=NaiveBuffer  -- primary
}
