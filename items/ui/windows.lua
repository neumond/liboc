local utils = require("utils")
local markupModule = require("ui.markup")


function intersection(a1, a2, b1, b2)
    if (b1 > a2) or (b2 < a1) then return end
    return math.max(a1, b1), math.min(a2, b2)
end


function intersectionWH(a, aw, b, bw)
    local j, k = intersection(a, a + aw - 1, b, b + bw - 1)
    if j == nil then return end
    return j, k - j + 1
end


-- RegionGpu


function RegionGpu(gpu, winX, winY, winWidth, winHeight, scrollX, scrollY)
    -- TODO: remove scrollX, scrollY
    return {
        set = function(x, y, text)
            x = x - scrollX
            y = y - scrollY
            local w = utils.strlen(text)
            local ox, ow = intersectionWH(1, winWidth, x, w)
            if ox == nil then return false end
            local oy, _ = intersectionWH(1, winHeight, y, 1)
            if oy == nil then return false end
            if w ~= ow then
                local textX = 1 + ox - x
                text = utils.strsub(text, textX, textX + ow - 1)
            end
            return gpu.set(ox + winX - 1, oy + winY - 1, text)
        end,
        fill = function(x, y, w, h, fillchar)
            x = x - scrollX
            y = y - scrollY
            local ox, ow = intersectionWH(1, winWidth, x, w)
            if ox == nil then return false end
            local oy, oh = intersectionWH(1, winHeight, y, h)
            if oy == nil then return false end
            return gpu.fill(ox + winX - 1, oy + winY - 1, ow, oh, fillchar)
        end,
        setForeground = function(color)
            return gpu.setForeground(color)
        end,
        setBackground = function(color)
            return gpu.setBackground(color)
        end,
        getResolution = function()
            return winWidth, winHeight
        end
    }
end


-- BaseFrame
-- Represents constrained part of screen
-- Can contain other frames


local BaseFrame = utils.makeClass(function(self)
    self.width = 0
    self.height = 0
end)


function BaseFrame:resize(width, height)
    local wc = self.width ~= width
    local hc = self.height ~= height
    self.width = width
    self.height = height
    return wc, hc
end


function BaseFrame:render(gpu)
    error("Not implemented")
end


-- MarkupFrame


local MarkupFrame = utils.makeClass(BaseFrame, function(super, markup, styles, minWidth)
    local self = super()
    self.markup = markup
    self.styles = styles
    self.minWidth = minWidth ~= nil and minWidth or 1
    assert(self.minWidth >= 1)
    self.commands = {}
    -- self.scrollX = 0  TODO
    -- self.scrollY = 0  TODO
end)


function MarkupFrame:resize(width, height)
    local wc, _ = MarkupFrame.__super.resize(self, width, height)
    if wc then
        self.commands = markupModule.markupToGpuCommands(
            self.markup, self.styles,
            math.max(self.minWidth, self.width)
        )
    end
end


function MarkupFrame:render(gpu)
    -- TODO: render only relevant lines
    markupModule.execGpuCommands(gpu, self.commands)
end


-- ContainerFrame


local ContainerFrame = utils.makeClass(BaseFrame, function(super)
    local self = super()
    self.frameIds = {}
    self.frames = {}
    self.autoId = 0
end)


function ContainerFrame:insert(frame, beforeIdx)
    self.autoId = self.autoId + 1
    if beforeIdx == nil then
        table.insert(self.frameIds, self.autoId)
    else
        table.insert(self.frameIds, beforeIdx, self.autoId)
    end
    self.frames[self.autoId] = frame
    return self.autoId
end


function ContainerFrame:remove(idx)
    local frameId = table.remove(self.frameIds, idx)
    self.frames[frameId] = nil
    return frameId
end


function ContainerFrame:isEmpty()
    return #self.frameIds == 0
end


function ContainerFrame:getCount()
    return #self.frameIds
end


function ContainerFrame:renderWarning(gpu, text)
    gpu.setForeground(0x808080)
    gpu.setBackground(0x000000)
    gpu.fill(1, 1, self.width, self.height, " ")
    gpu.set(
        math.floor((self.width - #text) / 2),
        math.floor(self.height / 2),
        text
    )
end


-- SwitcherFrame


local SwitcherFrame = utils.makeClass(ContainerFrame, function(super)
    local self = super()
    self.activeFrameId = nil
end)


function SwitcherFrame:remove(idx)
    local frameId = SwitcherFrame.__super.remove(self, idx)
    if frameId == self.activeFrameId then self:setActive(nil) end
    return frameId
end


function SwitcherFrame:setActive(frameId)
    self.activeFrameId = frameId
end


function SwitcherFrame:getActiveFrame()
    return self.frames[self.activeFrameId]
end


function SwitcherFrame:resize(width, height)
    local wc, hc = SwitcherFrame.__super.resize(self, width, height)
    if (wc or hc) and self.activeFrameId ~= nil then
        self:getActiveFrame():resize(width, height)
    end
end


function SwitcherFrame:render(gpu)
    if self.activeFrameId == nil then
        self:renderWarning(gpu, "No active frame available")
    else
        self:getActiveFrame():render(gpu)
    end
end


-- BaseSplitFrame


local BaseSplitFrame = utils.makeClass(ContainerFrame, function(super, border)
    local self = super()
    self.border = border ~= nil and border or 0
    assert(self.border >= 0)
    self.frameGrowFactors = {}
    self.growFactorSum = 0
end)


function BaseSplitFrame:insert(frame, before, growFactor)
    if growFactor == nil then growFactor = 1 end
    assert(growFactor > 0)
    local frameId = BaseSplitFrame.__super.insert(self, frame, before)
    self.frameGrowFactors[frameId] = growFactor
    self.growFactorSum = self.growFactorSum + growFactor
    return frameId
end


function BaseSplitFrame:remove(idx)
    local frameId = BaseSplitFrame.__super.remove(self, idx)
    self.growFactorSum = self.growFactorSum - self.frameGrowFactors[frameId]
    self.frameGrowFactors[frameId] = nil
    return frameId
end


function BaseSplitFrame:reflowLengths(mainAxisLength)
    local iter, iterTable, iterKey = pairs(self.frameIds)
    return function()
        iterKey, frameId = iter(iterTable, iterKey)
        if iterKey == nil then return end
        -- TODO: sum of yielded lengths must be EXACTLY equal to mainAxisLength
        return self.frames[frameId], math.floor(
            mainAxisLength * self.frameGrowFactors[frameId] / self.growFactorSum
        )
    end
end


function BaseSplitFrame:iterFramePositions()
    error("Not implemented")
end


function BaseSplitFrame:render(gpu)
    print("BaseSplitFrame:render")
    if self:isEmpty() then
        self:renderWarning(gpu, "No content available")
    else
        for frame, x, y, w, h in self:iterFramePositions() do
            frame:render(RegionGpu(gpu, x, y, w, h, 0, 0))
        end
    end
end


-- HSplitFrame


local HSplitFrame = utils.makeClass(BaseSplitFrame, function(super, ...)
    local self = super(...)
end)


function HSplitFrame:iterFramePositions()
    local x = 1
    local iter = self:reflowLengths(self.width)
    return function()
        local frame, fsize = iter()
        if frame == nil then return end
        local prevX = x
        x = x + frame.width
        return frame, prevX, 1, frame.width, self.height
    end
end


function HSplitFrame:resize(width, height)
    local wc, hc = HSplitFrame.__super.resize(self, width, height)
    if (wc or hc) then
        for frame, fsize in self:reflowLengths(width) do
            frame:resize(fsize, height)
        end
    end
end


-- VSplitFrame


local VSplitFrame = utils.makeClass(BaseSplitFrame, function(super, ...)
    local self = super(...)
end)


function VSplitFrame:iterFramePositions()
    local y = 1
    local iter = self:reflowLengths(self.width)
    return function()
        local frame, fsize = iter()
        if frame == nil then return end
        local prevY = y
        y = y + frame.height
        return frame, 1, prevY, self.width, frame.height
    end
end


function VSplitFrame:resize(width, height)
    local wc, hc = VSplitFrame.__super.resize(self, width, height)
    if (wc or hc) then
        for frame, fsize in self:reflowLengths(height) do
            frame:resize(width, fsize)
        end
    end
end


-- Module


return {
    RegionGpu=RegionGpu,
    MarkupFrame=MarkupFrame,
    SwitcherFrame=SwitcherFrame,
    HSplitFrame=HSplitFrame,
    VSplitFrame=VSplitFrame,
    testing={
        intersection=intersection
    }
}
