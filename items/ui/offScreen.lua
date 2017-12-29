local utils = require("utils")


local NaiveBuffer = utils.makeClass(function(self)
    self.textBuf = {}
    self.colorBuf = {}
    self.backgroundBuf = {}
    self.color = packColor(0xFFFFFF, false)
    self.background = packColor(0x000000, false)
end)


function NaiveBuffer:getGpuInterface()
    return {
        setForeground=function(...)
            return self:setForeground(...)
        end,
        setBackground=function(...)
            return self:setBackground(...)
        end,
        set=function(...)
            return self:set(...)
        end,
        fill=function(...)
            return self:fill(...)
        end
    }
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


function NaiveBuffer:setChar(x, y, char, charWidth)
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


function NaiveBuffer:fill(x, y, w, h, char)
    local filler = utils.strsub(char, 1, 1)
    local width = utils.charWidth(filler)
    for yy=y,y + h - 1 do
        for xx=x,x + (w - 1) * width,width do
            self:setChar(xx, yy, filler, width)
        end
    end
end


return {
    NaiveBuffer=NaiveBuffer
}
