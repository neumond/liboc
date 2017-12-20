local utils = require("utils")
local markupModule = require("ui.markup")
local bordersModule = require("ui.borders")


function forceRange(value, a, b)
    return math.min(math.max(value, a), b)
end


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


function RegionGpu(gpu, winX, winY, winWidth, winHeight)
    return {
        set = function(x, y, text)
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


local BaseFrame = utils.makeClass(function(self)
    self.width = 0
    self.height = 0
    self.needRedraw = true
end)


function BaseFrame:resize(width, height)
    local wc = self.width ~= width
    local hc = self.height ~= height
    self.width = width
    self.height = height
    self:invalidate()  -- always redraw on resize
    return wc, hc
end


function BaseFrame:render(gpu, br)
    if not self.needRedraw then return end
    self.needRedraw = false
    return true
end


function BaseFrame:invalidate()
    self.needRedraw = true
end


-- MarkupFrame


local MarkupFrame = utils.makeClass(BaseFrame, function(super, markup, styles, minWidth)
    local self = super()
    self.markup = markup
    self.styles = styles
    self.commands = {}
    self.reflown = false

    self.scrollX = 1
    self.scrollY = 1
    self.scrollMaxX = 1
    self.scrollMaxY = 1

    self:setMinimalContentWidth(minWidth)  -- TODO: remove from constructor parameters
end)


function MarkupFrame:setMinimalContentWidth(minWidth)
    self.minWidth = minWidth ~= nil and minWidth or 1
    assert(self.minWidth >= 1)
    self:invalidate()
end


function MarkupFrame:getContentWidth()
    return math.max(self.minWidth, self.width)
end


function MarkupFrame:getMaxScroll()
    return self.scrollMaxX, self.scrollMaxY
end


function MarkupFrame:scrollTo(x, y)
    x = forceRange(x, 1, self.scrollMaxX)
    y = forceRange(y, 1, self.scrollMaxY)
    self.scrollX = x
    self.scrollY = y
    self:invalidate()
end


function MarkupFrame:relativeScroll(dx, dy)
    return self:scrollTo(self.scrollX + dx, self.scrollY + dy)
end


function MarkupFrame:reflowMarkup(width)
    self.commands = markupModule.markupToGpuCommands(
        self.markup, self.styles, width
    )
    self.scrollMaxX = math.max(1, width - self.width + 1)
    self.scrollMaxY = math.max(1, #self.commands - self.height + 1)
    self.reflown = true
    self:scrollTo(self.scrollX, self.scrollY)
    self:invalidate()
end


function MarkupFrame:resize(width, height)
    local oldWidth = self:getContentWidth()
    local wc, _ = MarkupFrame.__super.resize(self, width, height)
    if wc then
        local newWidth = self:getContentWidth()
        if (oldWidth ~= newWidth) or (not self.reflown) then
            self:reflowMarkup(newWidth)
        end
    end
end


function MarkupFrame:render(gpu, br)
    if not MarkupFrame.__super.render(self, gpu, br) then return end
    local cmds = {}
    for i=1,self.height do
        cmds[i] = self.commands[i + (self.scrollY - 1)]
    end
    markupModule.execGpuCommands(
        gpu, cmds,
        self.scrollX - 1, 0
    )
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


function ContainerFrame:iterFrames()
    local iter, iterTable, iterKey = pairs(self.frameIds)
    return function()
        iterKey, frameId = iter(iterTable, iterKey)
        if iterKey == nil then return end
        return self.frames[frameId], frameId
    end
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
    if self.activeFrameId == frameId then return end
    self.activeFrameId = frameId
    self:getActiveFrame():resize(width, height)
    self:invalidate()
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


function SwitcherFrame:render(gpu, br)
    if not SwitcherFrame.__super.render(self, gpu, br) then return end
    if self.activeFrameId == nil then
        self:renderWarning(gpu, "No active frame available")
    else
        self:getActiveFrame():render(gpu, br)
    end
end


-- BaseSplitFrame


local BaseSplitFrame = utils.makeClass(ContainerFrame, function(super, borderType)
    local self = super()
    self:setBorder(borderType)
    self.frameGrowFactors = {}
    self.growFactorSum = 0
end)


function BaseSplitFrame:setBorder(borderType)
    self.borderType = borderType
    self.borderWidth = bordersModule.getBorderWidth(borderType)
end


function BaseSplitFrame:insert(frame, before)
    local frameId = BaseSplitFrame.__super.insert(self, frame, before)
    self.frameGrowFactors[frameId] = 1
    self.growFactorSum = self.growFactorSum + 1
    return frameId
end


function BaseSplitFrame:remove(idx)
    local frameId = BaseSplitFrame.__super.remove(self, idx)
    self.growFactorSum = self.growFactorSum - self.frameGrowFactors[frameId]
    self.frameGrowFactors[frameId] = nil
    return frameId
end


function BaseSplitFrame:setGrowFactor(frameId, growFactor)
    if growFactor == nil then growFactor = 1 end
    assert(growFactor > 0)
    local old = self.frameGrowFactors[frameId]
    if growFactor == old then return end
    self.growFactorSum = self.growFactorSum - old + growFactor
    self.frameGrowFactors[frameId] = growFactor
    self:resizeInner(self.width, self.height)
    self:invalidate()
end


function BaseSplitFrame:resize(width, height)
    local wc, hc = BaseSplitFrame.__super.resize(self, width, height)
    if (wc or hc) then
        self:resizeInner(width, height)
    end
end


function BaseSplitFrame:reflowLengths(mainAxisLength)
    mainAxisLength = mainAxisLength - self.borderWidth * (self:getCount() - 1)
    local iter = self:iterFrames()
    local restCount = self:getCount()
    local restSpace = mainAxisLength
    return function()
        frame, frameId = iter()
        if frame == nil then return end
        local length = math.floor(
            mainAxisLength * self.frameGrowFactors[frameId] / self.growFactorSum
        )
        if restCount == 1 then
            length = restSpace
        else
            restCount = restCount - 1
            restSpace = restSpace - length
        end
        return frame, length
    end
end


function BaseSplitFrame:iterFramePositions()
    error("Not implemented")
end


function BaseSplitFrame:drawFrameBorder(gpu, x, y, w, h)
    error("Not implemented")
end


function BaseSplitFrame:render(gpu, br)
    if not BaseSplitFrame.__super.render(self, gpu, br) then return end
    if self:isEmpty() then
        self:renderWarning(gpu, "No content available")
    else
        local first = true
        for frame, x, y, w, h in self:iterFramePositions() do
            if not first then
                self:drawFrameBorder(br, x, y, w, h)
            end
            frame:render(RegionGpu(gpu, x, y, w, h), br:enterWindow(x, y))
            if self.borderWidth > 0 then first = false end
        end
    end
end


-- HSplitFrame, VSplitFrame


local HSplitFrame = utils.makeClass(BaseSplitFrame, function(super, ...)
    local self = super(...)
end)
local VSplitFrame = utils.makeClass(BaseSplitFrame, function(super, ...)
    local self = super(...)
end)


function HSplitFrame:iterFramePositions()
    local x = 1
    local iter = self:iterFrames()
    return function()
        local frame = iter()
        if frame == nil then return end
        local prevX = x
        x = x + frame.width + self.borderWidth
        return frame, prevX, 1, frame.width, frame.height
    end
end
function VSplitFrame:iterFramePositions()
    local y = 1
    local iter = self:iterFrames()
    return function()
        local frame = iter()
        if frame == nil then return end
        local prevY = y
        y = y + frame.height + self.borderWidth
        return frame, 1, prevY, frame.width, frame.height
    end
end


function HSplitFrame:resizeInner(width, height)
    for frame, fsize in self:reflowLengths(width) do
        frame:resize(fsize, height)
    end
end
function VSplitFrame:resizeInner(width, height)
    for frame, fsize in self:reflowLengths(height) do
        frame:resize(width, fsize)
    end
end


function HSplitFrame:drawFrameBorder(br, x, y, w, h)
    br:setBorderType(self.borderType)
    br:vertical(x - 1, y, h)
end
function VSplitFrame:drawFrameBorder(br, x, y, w, h)
    br:setBorderType(self.borderType)
    br:horizontal(x, y - 1, w)
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
