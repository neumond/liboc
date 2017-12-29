local utils = require("utils")
local markupModule = require("ui.markup")
local bordersModule = require("ui.borders")
local LinkedList = require("lib.linkedList").LinkedList
local Stack = require("lib.stack").Stack
local regionModule = require("ui.regionGpu")


-- Frame resize doesn't affect its parent or siblings
-- Parent controls sizes of all its children
-- Frame resize affect all of its children (by launching their resize methods)
-- Frame resize causes global redraw of borders
-- You can't directly call resize method of any frame, instead you can
--   manipulate children lists of ContainerFrame
--   setGrowFactor of child of SplitFrame
--   setActive of child of SwitcherFrame
--   change resolution of target gpu
-- Frame invalidation for redrawing invalidates its children recursively

-- Frames do not draw anything on the screen except borders and "empty container" messages
--   Normally its only borders


-- BaseFrame
-- Represents constrained part of screen


local BaseFrame = utils.makeClass(function(self)
    self.root = nil

    self.posX = 0
    self.posY = 0
    self.width = 0
    self.height = 0
end)


function BaseFrame:setWindow(x, y, width, height)
    local wc = self.width ~= width
    local hc = self.height ~= height
    local posc = (self.posX ~= x) or (self.posY ~= y)

    self.posX = x
    self.posY = y
    self.width = width
    self.height = height

    if wc or hc or posc then
        self:invalidateContent()
    end
    return wc, hc, posc
end


function BaseFrame:render(gpu)
    error("Not implemented")
end


function BaseFrame:getRegion(gpu)
    return regionModule.RegionGpu(
        gpu,
        self.posX, self.posY,
        self.width, self.height
    )
end


function BaseFrame:getSubRegion(gpu, x, y, w, h)
    x, w = regionModule.intersectionWH(1, self.width, x, w)
    if x == nil then return end
    y, h = regionModule.intersectionWH(1, self.height, y, h)
    if y == nil then return end
    return regionModule.RegionGpu(
        gpu,
        self.posX + x - 1, self.posY + y - 1,
        w, h
    )
end


function BaseFrame:iterBordersCoro()
    -- intentionally empty
end


function BaseFrame:iterBorders()
    return coroutine.wrap(function() self:iterBordersCoro() end)
end


function BaseFrame:invalidateContent()
    if self.root == nil then return false end  -- TODO: remove this check?
    self.root.needRedraw[self] = true
    return true
end


function BaseFrame:invalidateBorders()
    if self.root == nil then return end  -- TODO: remove this check?
    self.root.needReBorder = true
end


-- ContentFrame


local ContentFrame = utils.makeClass(BaseFrame, function(self, super)
    super()
    self.scrollX = 1
    self.scrollY = 1
    self.scrollMaxX = math.huge
    self.scrollMaxY = math.huge
end)


function ContentFrame:getContentWidth()
    return self.width
end


function ContentFrame:getMaxScroll()
    return self.scrollMaxX, self.scrollMaxY
end


function ContentFrame:scrollTo(x, y, suppressInv)
    local oldx, oldy = self.scrollX, self.scrollY
    self.scrollX = regionModule.forceRange(x, 1, self.scrollMaxX)
    self.scrollY = regionModule.forceRange(y, 1, self.scrollMaxY)
    if (oldx == self.scrollX) and (oldy == self.scrollY) then return false end
    if not suppressInv then self:invalidateContent() end
    return true
end


function ContentFrame:relativeScroll(dx, dy, suppressInv)
    return self:scrollTo(self.scrollX + dx, self.scrollY + dy, inv)
end


-- MarkupFrame


local MarkupFrame = utils.makeClass(ContentFrame, function(self, super, markup, defaultStyles, selectorTable)
    super()

    self.markup = markup
    self.defaultStyles = defaultStyles
    self.selectorTable = selectorTable

    self.commands = {}
    self.reflownFor = nil
    self.minWidth = 1

    self.lsScrollX = nil
    self.lsScrollY = nil
    self.lsPosX = nil
    self.lsPosY = nil
    self.lsWidth = nil
    self.lsHeight = nil
end)


function MarkupFrame:setMinimalContentWidth(minWidth)
    assert(minWidth >= 1)
    self.minWidth = minWidth
    self:invalidateContent()
end


function MarkupFrame:getContentWidth()
    return math.max(self.minWidth, self.width)
end


function MarkupFrame:reflowMarkup()
    local width = self:getContentWidth()
    if self.reflownFor == width then return end
    self.reflownFor = width

    self.commands = markupModule.markupToGpuCommands(
        self.markup, self.defaultStyles, self.selectorTable, width
    )
    self.scrollMaxX = math.max(1, width - self.width + 1)
    self.scrollMaxY = math.max(1, #self.commands - self.height + 1)
    MarkupFrame.__super.scrollTo(self, self.scrollX, self.scrollY, true)
end


function MarkupFrame:scrollTo(x, y, suppressInv)
    local oldMatch = (
        (self.scrollX == self.lsScrollX) and
        (self.scrollY == self.lsScrollY)
    )
    if not MarkupFrame.__super.scrollTo(self, x, y, true) then
        return false
    end
    if not suppressInv then
        if (
            oldMatch and
            (self.posX == self.lsPosX) and
            (self.posY == self.lsPosY) and
            (self.width == self.lsWidth) and
            (self.height == self.lsHeight)
        ) then
            local gpu = self:getRegion(self.root.gpu)
            local dx, dy = self.lsScrollX - self.scrollX, self.lsScrollY - self.scrollY
            gpu.copy(1, 1, self.width, self.height, dx, dy)

            if dy ~= 0 then  -- redrawing insufficient rows
                local lineCount = math.abs(dy)
                local fromLine = dy > 0 and 1 or (self.height - lineCount + 1)
                local gpu = self:getSubRegion(self.root.gpu, 1, fromLine, self.width, lineCount)
                if gpu ~= nil then
                    self:renderInner(gpu, fromLine, lineCount, 1)
                end
            end
            if dx ~= 0 then  -- redrawing insufficient cols
                local colCount = math.abs(dx)
                local lineCount = self.height - math.abs(dy)
                local fromLine = 1 + math.max(0, dy)
                local fromCol = dx > 0 and 1 or (self.width - colCount + 1)
                local gpu = self:getSubRegion(self.root.gpu, fromCol, fromLine, colCount, lineCount)
                if gpu ~= nil then
                    self:renderInner(gpu, fromLine, lineCount, fromCol)
                end
            end

            self.lsScrollX = self.scrollX
            self.lsScrollY = self.scrollY
        else
            self:invalidateContent()
        end
    end
    return true
end


function MarkupFrame:renderInner(gpu, fromLine, lineCount, fromCol)
    local cmds = {}
    for i=1,lineCount do
        cmds[i] = self.commands[i + (fromLine - 1) + (self.scrollY - 1)]
    end
    markupModule.execGpuCommands(
        gpu, cmds,
        self.scrollX - 1 + fromCol - 1, 0
    )
end


function MarkupFrame:render(gpu)
    self:reflowMarkup()
    self:renderInner(gpu, 1, self.height, 1)

    self.lsScrollX = self.scrollX
    self.lsScrollY = self.scrollY
    self.lsPosX = self.posX
    self.lsPosY = self.posY
    self.lsWidth = self.width
    self.lsHeight = self.height
end


-- ContainerFrame


local ContainerFrame = utils.makeClass(BaseFrame, function(self, super)
    super()
    self.children = LinkedList(function(event, item)
        self:onChange(event, item)
    end)
end)


function ContainerFrame:onChange(event, item)
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
-- TODO: rewrite for LinkedList children


local SwitcherFrame = utils.makeClass(ContainerFrame, function(self, super)
    super()
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
    self:_rePositionActiveFrame()
    self:getActiveFrame():invalidateContent()
end


function SwitcherFrame:getActiveFrame()
    return self.frames[self.activeFrameId]
end


function SwitcherFrame:invalidateContent()
    if SwitcherFrame.__super.invalidateContent(self) then
        if self.activeFrameId ~= nil then
            self.root.needRedraw[self:getActiveFrame()] = true
        end
    end
end


function SwitcherFrame:_rePositionActiveFrame()
    if self.activeFrameId == nil then return end
    self:getActiveFrame():setWindow(self.posX, self.posY, self.width, self.height)
end


function SwitcherFrame:setWindow(x, y, width, height)
    local wc, hc, posc = SwitcherFrame.__super.setWindow(self, x, y, width, height)
    if wc or hc or posc then
        self:_rePositionActiveFrame()
    end
end


function SwitcherFrame:render(gpu)
    if self.activeFrameId == nil then
        self:renderWarning(gpu, "No active frame available")
    end
end


-- BaseSplitFrame


local BaseSplitFrame = utils.makeClass(ContainerFrame, function(self, super)
    super()
    self:setBorderType(0)
end)


function BaseSplitFrame:setBorderType(borderType)
    self.borderType = borderType
    self.borderWidth = bordersModule.getBorderWidth(borderType)
    self:invalidateBorders()
end


function BaseSplitFrame:onChange(event, item)
    if event == "add" then
        item.growFactor = 1
        item.setGrowFactor = function(frameItem, growFactor)
            assert(growFactor > 0)
            if growFactor == frameItem.growFactor then return end
            frameItem.growFactor = growFactor
            self:resizeInner(self.width, self.height)
            self:invalidateBorders()
            self:invalidateContent()
        end
    end
    self:invalidateBorders()
    self:invalidateContent()
end


function BaseSplitFrame:setWindow(x, y, width, height)
    local wc, hc, posc = BaseSplitFrame.__super.setWindow(self, x, y, width, height)
    if wc or hc or posc then
        self:setWindowInner(x, y, width, height)
    end
end


function BaseSplitFrame:setWindowInner(x, y, width, height)
    error("Not implemented")
end


function BaseSplitFrame:invalidateContent()
    if BaseSplitFrame.__super.invalidateContent(self) then
        for frameItem in self.children:iter() do
            frameItem:getPayload():invalidateContent()
        end
    end
end


function BaseSplitFrame:calcGrowFactorSum()
    local sum = 0
    for frameItem in self.children:iter() do
        sum = sum + frameItem.growFactor
    end
    return sum
end


function BaseSplitFrame:reflowLengths(mainAxisLength)
    mainAxisLength = mainAxisLength - self.borderWidth * (#self.children - 1)
    local growFactorSum = self:calcGrowFactorSum()
    local iter = self.children:iter()
    local restCount = #self.children
    local restSpace = mainAxisLength
    local posAcc = -self.borderWidth
    return function()
        frameItem = iter()
        if frameItem == nil then return end
        local frame = frameItem:getPayload()
        local length = math.floor(
            mainAxisLength * frameItem.growFactor / growFactorSum
        )
        if restCount == 1 then
            length = restSpace
        else
            restCount = restCount - 1
            restSpace = restSpace - length
        end
        posAcc = posAcc + self.borderWidth
        local pos = posAcc
        posAcc = posAcc + length
        return frame, length, pos
    end
end


function BaseSplitFrame:positionFrameBorder(frame)
    error("Not implemented")
end


function BaseSplitFrame:render(gpu)
    if #self.children == 0 then
        self:renderWarning(gpu, "No content available")
    end
end


function BaseSplitFrame:iterBordersCoro()
    if #self.children > 1 then
        coroutine.yield("setBorderType", self.borderType)
        local first = true
        for frameItem in self.children:iter() do
            local frame = frameItem:getPayload()
            if not first then
                coroutine.yield(self:positionFrameBorder(frame))
            end
            if self.borderWidth > 0 then first = false end
        end
    end
    for frameItem in self.children:iter() do
        local frame = frameItem:getPayload()
        frame:iterBordersCoro()
    end
end


-- HSplitFrame, VSplitFrame


local HSplitFrame = utils.makeClass(BaseSplitFrame)
local VSplitFrame = utils.makeClass(BaseSplitFrame)


function HSplitFrame:setWindowInner(x, y, width, height)
    for frame, fsize, fpos in self:reflowLengths(width) do
        frame:setWindow(self.posX + fpos, self.posY, fsize, height)
    end
end
function VSplitFrame:setWindowInner(x, y, width, height)
    for frame, fsize, fpos in self:reflowLengths(height) do
        frame:setWindow(self.posX, self.posY + fpos, width, fsize)
    end
end


function HSplitFrame:positionFrameBorder(frame)
    return "vertical", frame.posX - 1, frame.posY, frame.height
end
function VSplitFrame:positionFrameBorder(frame)
    return "horizontal", frame.posX, frame.posY - 1, frame.width
end


-- FrameRoot


local FrameRoot = utils.makeClass(function(self, gpu)
    self.gpu = gpu
    self.rootFrame = nil
    self.needRedraw = {}
    self.needReBorder = true
    self.gpuWidth = 0
    self.gpuHeight = 0
end)


function FrameRoot:assignRoot(frame)
    assert(self.rootFrame == nil, "Can be assigned only once")
    assert(frame.root == self)
    self.rootFrame = frame
end


function FrameRoot:_checkSize()
    local gpuWidth, gpuHeight = self.gpu.getResolution()
    if (gpuWidth ~= self.gpuWidth) or (gpuHeight ~= self.gpuHeight) then
        self.gpuWidth = gpuWidth
        self.gpuHeight = gpuHeight
        self.rootFrame:setWindow(1, 1, gpuWidth, gpuHeight)
    end
end


function FrameRoot:_accumulateBorders(br)
    local shiftX, shiftY = 0, 0
    local shiftStack = Stack()
    for cmd, a, b, c in self.rootFrame:iterBorders() do
        if cmd == "setBorderType" then
            br:setBorderType(a)
        elseif cmd == "horizontal" then
            br:horizontal(a + shiftX, b + shiftY, c)
        elseif cmd == "vertical" then
            br:vertical(a + shiftX, b + shiftY, c)
        elseif cmd == "enter" then
            shiftStack:push(shiftY)
            shiftStack:push(shiftX)
            shiftX = shiftX + a - 1
            shiftY = shiftY + b - 1
        elseif cmd == "exit" then
            shiftX = shiftStack:pop()
            shiftY = shiftStack:pop()
        end
    end
end


function FrameRoot:_reBorder()
    if not self.needReBorder then return end
    local br = bordersModule.BorderRenderer()
    self:_accumulateBorders(br)
    br:applyJoints()
    self.gpu.setBackground(0x000000)
    self.gpu.setForeground(0x00FF00)
    br:render(self.gpu)
    self.needReBorder = false
end


function FrameRoot:_reDraw()
    for frame, _ in pairs(self.needRedraw) do
        frame:render(frame:getRegion(self.gpu))
    end
    self.needRedraw = {}
end


function FrameRoot:update()
    self:_checkSize()
    self:_reBorder()
    self:_reDraw()
end


function FrameRoot:Markup(...)
    local f = MarkupFrame(...)
    f.root = self
    return f
end


function FrameRoot:Switcher(...)
    local f = SwitcherFrame(...)
    f.root = self
    return f
end


function FrameRoot:HSplit(...)
    local f = HSplitFrame(...)
    f.root = self
    return f
end


function FrameRoot:VSplit(...)
    local f = VSplitFrame(...)
    f.root = self
    return f
end


-- Module


return {
    FrameRoot=FrameRoot
}
