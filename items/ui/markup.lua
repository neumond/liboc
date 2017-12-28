local utils = require("utils")
local selectorModule = require("ui.selectors")
local Stack = require("lib.stack").Stack
local boxModule = require("ui.boxModel")
local Flow = {}
do
    local function makeEnumeration(items)
        local result = {}
        for i, k in ipairs(items) do
            result[k] = i
        end
        return result
    end
    Flow = makeEnumeration{
        "string", "glue",
        "pushClass", "popClass",
        "wordSize", "lineSize",
        "styleChange",
        "space",
        "blockStart", "blockEnd",
        -- gpu tokens
        "gpuColor", "gpuBackground",
        "gpuFill", "gpuSet",
        "gpuNewLine"
    }
end
local Glue = {}


-- Element
-- Abstract Element contains some text
-- This class is intended for subclassing


local Element = utils.makeClass(function(self, ...)
    self.children = {...}
    self.className = nil
end)


Element._isElement = true


function Element:class(s)
    self.className = s
    return self
end


function Element:iterTokensPushClass()
    if self.className ~= nil then
        coroutine.yield(Flow.pushClass, self.className)
    end
end


function Element:iterTokensPopClass()
    if self.className ~= nil then
        coroutine.yield(Flow.popClass)
    end
end


function Element:iterTokensChildren()
    for _, child in ipairs(self.children) do
        if child._isElement then
            child:iterTokensCoro()
        elseif child == Glue then
            coroutine.yield(Flow.glue)
        else
            coroutine.yield(Flow.string, child)
        end
    end
end


function Element:iterTokensCoro()
    error("Not implemented")
end


function Element:iterTokens()
    return coroutine.wrap(function() self:iterTokensCoro() end)
end


-- Span takes as much horizontal space as needed for content
-- consequent Spans follow on the same line


local Span = utils.makeClass(Element)


function Span:iterTokensCoro()
    self:iterTokensPushClass()
    self:iterTokensChildren()
    self:iterTokensPopClass()
end


-- Div takes all the horizontal space available
-- consequent Divs always start from a new line


local Div = utils.makeClass(Element)


function Div:iterTokensCoro()
    self:iterTokensPushClass()
    coroutine.yield(Flow.blockStart)
    self:iterTokensChildren()
    coroutine.yield(Flow.blockEnd)
    self:iterTokensPopClass()
end


-- Token iteration


local function makeIterChain(func, ...)
    for _, iter in ipairs({...}) do
        func = iter(func)
    end
    return func
end


local function removeGlueAddWordLengths(iter)
    -- removes Flow.glue
    -- adds Flow.wordSize

    -- splitting point of words
    -- Flow.string not preceded by Flow.glue
    -- i.e. Flow.glue makes next Flow.string non word-breaking
    return utils.bufferingIterator(function(append, prepend)
        local glued = true
        local accuLength = 0

        local function appendString(s)
            accuLength = accuLength + utils.strlen(s)
            return append(Flow.string, s)
        end

        local function prependWordSize()
            if accuLength == 0 then return end  -- no word have accumulated
            prepend(Flow.wordSize, accuLength)
            accuLength = 0
        end

        local cmdSwitch = {
            [Flow.glue] = function()
                glued = true  -- setting flag and skipping this command
            end,
            [Flow.string] = function(a)
                if not glued then  -- non-glued word boundary detected
                    prependWordSize()
                    local idx = appendString(a)
                    return false, idx - 1  -- output everything except last string
                else  -- glued case
                    glued = false  -- reset flag
                    appendString(a)
                end
            end,
            [Flow.blockStart] = function()
                prependWordSize()
                append(Flow.blockStart)
                glued = true
                return false, nil
            end,
            [Flow.blockEnd] = function()
                prependWordSize()
                append(Flow.blockEnd)
                glued = true
                return false, nil
            end
        }

        return function()
            while true do
                local cmd, a, b = iter()
                if cmd == nil then
                    prependWordSize()
                    return true, nil  -- finish and output everything in buffer
                end
                local cb = cmdSwitch[cmd]
                if cb ~= nil then
                    local j, k = cb(a, b)
                    if j ~= nil then return j, k end
                else
                    append(cmd, a, b)
                end
            end
        end
    end)
end


local function pushclassAfterWordsize(iter)
    -- TODO: need?
    -- repositions Flow.pushClass and Flow.wordSize
    return utils.bufferingIterator(function(append, prepend)
        return function()
            while true do
                local cmd, a, b = iter()
                if cmd == nil then
                    return true, nil
                elseif cmd == Flow.pushClass then
                    append(cmd, a, b)
                elseif cmd == Flow.wordSize then
                    prepend(cmd, a, b)
                    return false, nil
                else
                    append(cmd, a, b)
                    return false, nil
                end
            end
        end
    end)
end


local function classesToStyles(markupIter, defaultStyles, selectorTable)
    -- removes Flow.pushClass and Flow.popClass
    -- adds Flow.styleChange
    return utils.bufferingIterator(function(append, prepend)
        local selectorEngine = selectorModule.SelectorEngine(defaultStyles, selectorTable, function(k, v)
            append(Flow.styleChange, k, v)
        end)
        local cmdSwitch = {
            [Flow.pushClass] = function(c)
                selectorEngine:push(c)
            end,
            [Flow.popClass] = function()
                selectorEngine:pop()
            end
        }
        return function()
            local cmd, a, b = markupIter()
            if cmd == nil then return true, nil end
            local cb = cmdSwitch[cmd]
            if cb ~= nil then
                cb(a, b)
            else
                append(cmd, a, b)
            end
            return false, nil
        end
    end)
end


local function styleTracker(props)
    local obj = utils.copyTable(selectorModule.DEFAULT_STYLES)
    obj.onStyleChange = function(k, v)
        if props == nil or props[k] then
            obj[k] = v
        end
    end
    return obj
end


local function makeDefaultBox(screenWidth)
    return boxModule.makeBox(selectorModule.DEFAULT_STYLES, screenWidth)
end


local function blockContentWidths(markupIter, screenWidth)
    -- requires classesToStyles
    -- extends Flow.blockStart and Flow.blockEnd
    --     Flow.blockStart, {margin*, padding*, border*, contentWidth}
    -- TODO: contentWidth can be negative

    local blockStack = Stack()
    blockStack:push(makeDefaultBox(screenWidth))
    local styles = styleTracker(boxModule.trackerConfig)

    local cmdSwitch = {
        [Flow.styleChange] = function(k, v)
            styles.onStyleChange(k, v)
            return Flow.styleChange, k, v
        end,
        [Flow.blockStart] = function()
            blockStack:push(boxModule.makeBox(
                styles, blockStack:tip().contentWidth
            ))
            return Flow.blockStart, blockStack:tip()
        end,
        [Flow.blockEnd] = function()
            blockStack:pop()
            return Flow.blockEnd, blockStack:tip()
        end
    }
    return function()
        local cmd, a, b = markupIter()
        if cmd == nil then return end
        local cb = cmdSwitch[cmd]
        if cb ~= nil then
            return cb(a, b)
        end
        return cmd, a, b
    end
end


local function splitIntoLines(markupIter, screenWidth)
    -- requires
    --     blockContentWidths
    --     removeGlueAddWordLengths
    -- removes Flow.wordSize
    -- reflows Flow.string
    -- adds Flow.lineSize and Flow.space
    return utils.bufferingIterator(function(append, prepend)
        local currentLineWidth = 0
        local spaceCount = 0
        local lineNeedsFlush = false
        local needPreSpace = false

        local function fitWidth(len)
            local v = math.min(len, screenWidth - currentLineWidth)
            return v == len, v
        end

        local function finishLine()
            if currentLineWidth > 0 then
                prepend(Flow.lineSize, currentLineWidth, spaceCount)
                currentLineWidth = 0
                spaceCount = 0
                lineNeedsFlush = true
            end
        end

        local function handleBlockBound(token, box)
            finishLine()
            needPreSpace = false
            screenWidth = box.contentWidth
            append(token, box)
            -- we can safely flush since block bound always breaks a line
            lineNeedsFlush = true
        end

        local cmdSwitch = {
            [Flow.string] = function(s)
                if currentLineWidth >= screenWidth then return end
                local len = utils.strlen(s)
                local fits, len = fitWidth(len)
                if not fits then
                    s = utils.strsub(s, 1, len - 1) .. "…"
                end
                append(Flow.string, s)
                currentLineWidth = currentLineWidth + len
            end,
            [Flow.wordSize] = function(value)
                local fits = fitWidth(value + (needPreSpace and 1 or 0))
                if not fits then
                    finishLine()
                else
                    if needPreSpace then
                        spaceCount = spaceCount + 1
                        currentLineWidth = currentLineWidth + 1
                        append(Flow.space)
                    end
                end
                needPreSpace = true
            end,
            [Flow.blockStart] = function(box)
                handleBlockBound(Flow.blockStart, box)
            end,
            [Flow.blockEnd] = function(box)
                handleBlockBound(Flow.blockEnd, box)
            end
        }

        return function()
            while not lineNeedsFlush do
                local cmd, a, b = markupIter()
                if cmd == nil then
                    finishLine()
                    return true, nil
                end
                local cb = cmdSwitch[cmd]
                if cb == nil then
                    append(cmd, a, b)
                else
                    cb(a, b)
                end
            end
            lineNeedsFlush = false
            return false, nil
        end
    end)
end


-- TODO: margin collapsing


local function textCenterPad(pad)
    return pad // 2
end

local function textStartingX(align, pad)
    local x = 0
    if align == "right" then
        x = pad
    elseif align == "center" then
        x = textCenterPad(pad)
    end
    return x
end

local textPaddingSwitch = {
    left=function(w, pad, cmdAppend)
        cmdAppend(w + 1, pad)
    end,
    right=function(w, pad, cmdAppend)
        cmdAppend(1, pad)
    end,
    center=function(w, pad, cmdAppend)
        local centerPad = textCenterPad(pad)
        if centerPad > 0 then cmdAppend(1, centerPad) end
        local rest = pad - centerPad
        if rest > 0 then cmdAppend(w + 1 + centerPad, rest) end
    end
}


local function renderToGpuLines(markupIter, screenWidth)
    -- requires splitIntoLines
    -- outputs lines with gpu commands
    return utils.bufferingIterator(function(append, prepend)
        local fillerStack = Stack()
        local boxStack = Stack()
        local styleStack = Stack()
        local styles = styleTracker()
        local leftFillerWidth = 0
        local rightFillerWidth = 0
        local textPos

        boxStack:push(makeDefaultBox(screenWidth))
        styleStack:push(utils.copyTable(selectorModule.DEFAULT_STYLES))

        local function pushBox(box)
            boxStack:push(box)
            styleStack:push(utils.copyTable(styles))
        end

        local function popBox()
            boxStack:pop()
            styleStack:pop()
        end

        local function pushFiller(color, background, fillLeft, fillRight, leftWidth, rightWidth)
            fillerStack:push({
                color=color,
                background=background,
                fillLeft=fillLeft,
                fillRight=fillRight,
                leftWidth=leftWidth,
                rightWidth=rightWidth
            })
            leftFillerWidth = leftFillerWidth + leftWidth
            rightFillerWidth = rightFillerWidth + rightWidth
        end

        local function popFiller()
            local f = fillerStack:pop()
            leftFillerWidth = leftFillerWidth - f.leftWidth
            rightFillerWidth = rightFillerWidth - f.rightWidth
        end

        local function newLine()
            append(Flow.gpuNewLine)
            -- Rendering fillers
            local left = 1
            local right = screenWidth + 1
            for _, f in fillerStack:iterFromBottom() do
                right = right - f.rightWidth
                append(Flow.gpuColor, f.color)
                append(Flow.gpuBackground, f.background)
                if f.leftWidth > 0 then
                    append(Flow.gpuFill, left, f.leftWidth, f.fillLeft)
                end
                if f.rightWidth > 0 then
                    append(Flow.gpuFill, right, f.rightWidth, f.fillRight)
                end
                left = left + f.leftWidth
            end
            -- Returning content gap
            return leftFillerWidth + 1, screenWidth - rightFillerWidth - leftFillerWidth
        end

        local function renderTopBorderLine()
            local bc = boxStack:tip().borderChars
            local s = styleStack:tip()
            local pos, width = newLine()
            append(Flow.gpuColor, s.borderColor)
            append(Flow.gpuBackground, s.borderBackground)
            append(Flow.gpuFill, pos, 1, bc.upLeft)
            append(Flow.gpuFill, pos + 1, width - 2, bc.up)
            append(Flow.gpuFill, pos + width - 1, 1, bc.upRight)
        end

        local function renderBottomBorderLine()
            local bc = boxStack:tip().borderChars
            local s = styleStack:tip()
            local pos, width = newLine()
            append(Flow.gpuColor, s.borderColor)
            append(Flow.gpuBackground, s.borderBackground)
            append(Flow.gpuFill, pos, 1, bc.downLeft)
            append(Flow.gpuFill, pos + 1, width - 2, bc.down)
            append(Flow.gpuFill, pos + width - 1, 1, bc.downRight)
        end

        local function renderPaddingLine()
            local s = styleStack:tip()
            local b = boxStack:tip()
            local pos, width = newLine()
            append(Flow.gpuColor, s.paddingColor)
            append(Flow.gpuBackground, s.paddingBackground)
            append(Flow.gpuFill, pos, width, s.paddingFill)
        end

        local cmdSwitch = {
            [Flow.styleChange] = function(k, v)
                styles.onStyleChange(k, v)
            end,
            [Flow.blockStart] = function(box)
                local parStyles = styleStack:tip()
                for i=1,box.marginTop do renderPaddingLine() end
                pushFiller(
                    parStyles.paddingColor, parStyles.paddingBackground,
                    parStyles.paddingFill, parStyles.paddingFill,
                    box.marginLeft, box.marginRight)
                pushBox(box)
                for i=1,box.borderTop do renderTopBorderLine() end
                pushFiller(
                    styles.borderColor, styles.borderBackground,
                    box.borderChars.left, box.borderChars.right,
                    box.borderLeft, box.borderRight)
                for i=1,box.paddingTop do renderPaddingLine() end
                pushFiller(
                    styles.paddingColor, styles.paddingBackground,
                    styles.paddingFill, styles.paddingFill,
                    box.paddingLeft, box.paddingRight)
            end,
            [Flow.blockEnd] = function()
                local box = boxStack:tip()
                popFiller()
                for i=1,box.paddingBottom do renderPaddingLine() end
                popFiller()
                for i=1,box.borderBottom do renderBottomBorderLine() end
                popBox()
                popFiller()
                for i=1,box.marginBottom do renderPaddingLine() end
            end,
            [Flow.lineSize] = function(lineWidth, spaceCount)
                local bs = styleStack:tip()
                local pos, width = newLine()
                local pad = width - lineWidth
                textPos = textStartingX(bs.align, pad) + 1 + leftFillerWidth
                append(Flow.gpuColor, styles.paddingColor)
                append(Flow.gpuBackground, styles.paddingBackground)
                textPaddingSwitch[bs.align](lineWidth, pad, function(x, w)
                    append(Flow.gpuFill, pos + x - 1, w, styles.paddingFill)
                end)
            end,
            [Flow.string] = function(str)
                append(Flow.gpuColor, styles.textColor)
                append(Flow.gpuBackground, styles.textBackground)
                append(Flow.gpuSet, textPos, str)
                textPos = textPos + utils.strlen(str)
            end,
            [Flow.space] = function()
                local spaceWidth = 1
                append(Flow.gpuColor, styles.spaceColor)
                append(Flow.gpuBackground, styles.spaceBackground)
                append(Flow.gpuFill, textPos, spaceWidth, styles.spaceFill)
                textPos = textPos + spaceWidth
            end
        }

        return function()
            local cmd, a, b = markupIter()
            if cmd == nil then return true, nil end
            local cb = cmdSwitch[cmd]
            if cb ~= nil then cb(a, b) end
            return false, nil
        end
    end)
end


local function execGpuTokens(gpu, iter)
    local currentLine = 0

    local cmdSwitch = {
        [Flow.gpuColor] = function(v)
            gpu.setForeground(v)
        end,
        [Flow.gpuBackground] = function(v)
            gpu.setBackground(v)
        end,
        [Flow.gpuFill] = function(x, w, char)
            gpu.fill(x, currentLine, w, 1, char)
        end,
        [Flow.gpuSet] = function(x, text)
            gpu.set(x, currentLine, text)
        end,
        [Flow.gpuNewLine] = function()
            currentLine = currentLine + 1
        end
    }

    for cmd, a, b, c in iter do
        cmdSwitch[cmd](a, b, c)
    end
end


local function tokenDebug(markupIter)
    local RevFlow = {}
    for k, v in pairs(Flow) do
        RevFlow[v] = k
    end

    for cmd, value in markupIter do
        print(RevFlow[cmd], value)
    end
end


return {
    Span=Span,
    Div=Div,
    Glue=Glue,
    Selector=selectorModule.Selector,
    testing={
        tokenDebug=tokenDebug,
        Flow=Flow,
        removeGlueAddWordLengths=removeGlueAddWordLengths,
        classesToStyles=classesToStyles,
        blockContentWidths=blockContentWidths,
        splitIntoLines=splitIntoLines,
        renderToGpuLines=renderToGpuLines,
        execGpuTokens=execGpuTokens
    }
}
