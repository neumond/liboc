local utils = require("utils")
local event = require("event")
local component = require("component")
local gpu = component.gpu
local M = {}
local KEYS = {
    ["up"]=200,
    ["down"]=208,
    ["enter"]=28,
    ["back"]=203
}
local CURSOR = ">"


function stringLines(lines)
    local pos = 1
    local len = string.len(lines)
    return function()
        if pos == nil then return end
        local s, e = string.find(lines, "\n", pos, true)
        local r
        if s ~= nil then
            r = string.sub(lines, pos, s - 1)
            pos = e + 1
        else
            r = string.sub(lines, pos)
            pos = nil
        end
        return r
    end
end


function wrapLine(text, width)
    local pos = 1
    local len = string.len(text)
    return function()
        if pos > len then return end
        local r = string.sub(text, pos, pos + width - 1)
        pos = pos + width
        return r
    end
end


function outputTextToWindow(text, x, y, w, h)
    local lcount = 0
    for line in stringLines(text) do
        for subline in wrapLine(line, w) do
            if lcount >= h then return lcount end
            gpu.fill(1, y + lcount, w, 1, " ")
            gpu.set(1, y + lcount, subline)
            lcount = lcount + 1
        end
    end
    return lcount
end


function M.clearScreen()
    local w, h = gpu.getResolution()
    gpu.fill(1, 1, w, h, " ")
end


local Menu = utils.makeClass(function(self, allowBack, preSelect)
    M.clearScreen()
    self.planeX, self.planeY = 1, 1
    self.planeWidth, self.planeHeight = gpu.getResolution()

    self.allowBack = allowBack
    self.preSelectValue = preSelect
    self.preSelectIndex = 1
    self.yOffset = 0
    self.hasChoices = false
    self.choiceCount = 0
    self.choicePoints = {}
    self.choiceValues = {}
end)
M.Menu = Menu


function Menu:_writeText(text)
    return outputTextToWindow(
        text,
        self.planeX, self.planeY + self.yOffset,
        self.planeWidth, self.planeHeight - self.yOffset)
end


function Menu:addText(text)
    local dy = self:_writeText(text)
    self.yOffset = self.yOffset + dy
    return self
end


function Menu:addSelectable(text, value)
    table.insert(self.choicePoints, self.yOffset)
    table.insert(self.choiceValues, value)
    self.choiceCount = self.choiceCount + 1
    self.hasChoices = true
    if self.preSelectValue ~= nil and value == self.preSelectValue then
        self.preSelectIndex = self.choiceCount
    end

    local dy = self:_writeText("  [ " .. text .. " ]")
    self.yOffset = self.yOffset + dy
    return self
end


function Menu:addSeparator()
    gpu.fill(
        self.planeX, self.planeY + self.yOffset,
        self.planeWidth, 1,
        "-")
    self.yOffset = self.yOffset + 1
    return self
end


function Menu:run()
    local select = nil

    function drawSelection(position, visible)
        gpu.set(
            self.planeX,
            self.planeY + self.choicePoints[position],
            visible and CURSOR or " ")
    end

    if self.hasChoices then
        select = self.preSelectIndex
        drawSelection(select, true)
    end

    while true do
        local _, _, _, key = event.pull("key_down")
        local newSelect = select

        if self.hasChoices then
            if key == KEYS.up then
                newSelect = (select - 2) % self.choiceCount + 1
            elseif key == KEYS.down then
                newSelect = select % self.choiceCount + 1
            elseif key == KEYS.enter then
                break
            end
        end
        if key == KEYS.back and self.allowBack then
            select = nil
            break
        end

        if newSelect ~= select then
            drawSelection(select, false)
            select = newSelect
            drawSelection(select, true)
        end
    end

    if select == nil then return end
    return self.choiceValues[select]
end


return M
