local utils = require("utils")
local selectorModule = require("ui.selectors")
local Flow = {
    string=1,
    glue=2,
    pushClass=3,
    popClass=4,
    newLine=5,
    wordSize=6,
    startControl=7,
    endControl=8,
    styleChange=9,
    lineSize=10,
    space=11,
    blockStart=12,
    blockEnd=13,
    blockWidth=14
}
local Glue = {}


-- Element
-- Abstract Element contains some text
-- This class is intended for subclassing


local Element = utils.makeClass(function(self, ...)
    self.children = {...}
    self.className = nil
    self.clickCallback = nil
end)


Element._isElement = true


function Element:setContent(...)
    self.children = {...}
end


function Element:class(s)
    self.className = s
    return self
end


function Element:clickable(callback)
    self.clickCallback = callback
    return self
end


function Element:iterTokensPushClass()
    if self.className ~= nil then
        coroutine.yield(Flow.pushClass, self.className)
    end
    if self.clickCallback ~= nil then
        coroutine.yield(Flow.startControl, self.clickCallback)
    end
end


function Element:iterTokensPopClass()
    if self.clickCallback ~= nil then
        coroutine.yield(Flow.endControl)
    end
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
    self:iterTokensPushClass()
    self:iterTokensChildren()
    self:iterTokensPopClass()
end


function Element:iterTokens()
    return coroutine.wrap(function() self:iterTokensCoro() end)
end


-- Span takes as much horizontal space as needed for content
-- consequent Spans follow on the same line


local Span = utils.makeClass(Element, function(super, ...)
    local self = super(...)
end)


-- Div takes all the horizontal space available
-- consequent Divs always start from a new line


local Div = utils.makeClass(Element, function(super, ...)
    local self = super(...)
end)


function Div:iterTokensCoro()
    coroutine.yield(Flow.newLine)
    coroutine.yield(Flow.blockStart)
    self:iterTokensPushClass()

    self:iterTokensChildren()

    coroutine.yield(Flow.newLine)
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


local function squashNewLines(markupIter)
    -- removes excessive Flow.newLine
    local suppress = true  -- must be set to false with first Flow.string
    return function()
        while true do
            local cmd, a, b = markupIter()
            if cmd == nil then
                return nil
            elseif cmd == Flow.newLine then
                if not suppress then
                    suppress = true
                    return cmd, a, b
                end
            elseif cmd == Flow.string then
                suppress = false  -- has some content, don't omit newLine
                return cmd, a, b
            else
                return cmd, a, b
            end
        end
    end
end


local function removeLastNewLine(markupIter)
    -- removes excessive Flow.newLine
    local prevNewLine = false
    return utils.bufferingIterator(function(append, prepend)
        return function()
            while true do
                local cmd, a, b = markupIter()
                if cmd == nil then
                    return true, nil
                elseif cmd == Flow.newLine then
                    prevNewLine = true
                elseif cmd == Flow.string then
                    if prevNewLine then
                        prepend(Flow.newLine)
                        prevNewLine = false
                    end
                    append(cmd, a, b)
                else
                    append(cmd, a, b)
                end
                if not prevNewLine then
                    return false, nil
                end
            end
        end
    end)
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
            [Flow.string] = function(val)
                if not glued then  -- non-glued word boundary detected
                    prependWordSize()
                    local idx = appendString(val)
                    return false, idx - 1  -- output everything except last string
                else  -- glued case
                    glued = false  -- reset flag
                    appendString(val)
                end
            end,
            [Flow.newLine] = function()
                prependWordSize()
                append(Flow.newLine)
                glued = true
                return false, nil
            end
        }

        return function()
            while true do
                local cmd, val = iter()
                if cmd == nil then
                    prependWordSize()
                    return true, nil  -- finish and output everything in buffer
                end
                local cb = cmdSwitch[cmd]
                if cb ~= nil then
                    local a, b = cb(val)
                    if a ~= nil then return a, b end
                else
                    append(cmd, val)
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
                local cmd, val = iter()
                if cmd == nil then
                    return true, nil
                elseif cmd == Flow.pushClass then
                    append(cmd, val)
                elseif cmd == Flow.wordSize then
                    prepend(cmd, val)
                    return false, nil
                else
                    append(cmd, val)
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
            [Flow.pushClass] = function(value)
                selectorEngine:push(value)
            end,
            [Flow.popClass] = function(value)
                selectorEngine:pop()
            end
        }
        return function()
            local cmd, value = markupIter()
            if cmd == nil then return true, nil end
            local cb = cmdSwitch[cmd]
            if cb ~= nil then
                cb(value)
            else
                append(cmd, value)
            end
            return false, nil
        end
    end)
end


local function blockWidthChanges(markupIter, screenWidth)
    -- requires classesToStyles
    -- adds Flow.blockWidth
    return utils.bufferingIterator(function(append, prepend)
        return function()
        end
    end)
end


local function splitIntoLines(markupIter, screenWidth)
    -- removes Flow.wordSize
    -- adds Flow.lineSize and Flow.space

    -- TODO: port to blockWidthChanges
    -- TODO: should remove Flow.newLine?
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

        local cmdSwitch = {
            [Flow.newLine] = function()
                finishLine()
                needPreSpace = false
                return true
            end,
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
                if cb == nil or cb(a, b) then
                    append(cmd, a, b)
                end
            end
            lineNeedsFlush = false
            return false, nil
        end
    end)
end


-- OLD CODE


local function iterMarkupTokens(markup)
    return pushclassAfterWordsize(
        removeLastBlockBound(
            squashBlockBounds(
                removeGlueAddWordLengths(
                    markup:iterTokens()
                )
            )
        )
    )
end


local GpuLineColorControl = utils.makeClass(function(self, cmdAppend)
    self.cmdAppend = cmdAppend
    self.fg = nil
    self.bg = nil
    self.lastFg = nil
    self.lastBg = nil
end)


function GpuLineColorControl:flush()
    if self.fg ~= nil then
        self.cmdAppend("setForeground", self.fg)
        self.fg = nil
    end
    if self.bg ~= nil then
        self.cmdAppend("setBackground", self.bg)
        self.bg = nil
    end
end


function GpuLineColorControl:setForeground(color)
    if self.lastFg ~= color then
        self.fg = color
        self.lastFg = color
    end
end


function GpuLineColorControl:setBackground(color)
    if self.lastBg ~= color then
        self.bg = color
        self.lastBg = color
    end
end


local GpuLine = utils.makeClass(function(self)
    self.width = 0
    self.spaceCount = 0
    self.commands = {}
    self.nonEmpty = false
end)


function GpuLine:token(s)
    self.width = self.width + utils.strlen(s)
    table.insert(self.commands, {"token", s})
end


function GpuLine:space()
    self.width = self.width + 1
    self.spaceCount = self.spaceCount + 1
    table.insert(self.commands, {"space"})
end


function GpuLine:color(value)
    table.insert(self.commands, {"color", value})
end


function GpuLine:background(value)
    table.insert(self.commands, {"background", value})
end


function GpuLine:isEmpty()
    return not (self.nonEmpty or (#self.commands > 0))
end


local function getCenterPad(pad)
    return pad // 2
end


local function getStartingX(align, pad)
    local x = 0
    if align == "right" then
        x = pad
    elseif align == "center" then
        x = getCenterPad(pad)
    end
    return x
end


local fillPadding = {
    left=function(x, pad, cmdAppend)
        cmdAppend(x + 1, pad)
    end,
    right=function(x, pad, cmdAppend)
        cmdAppend(1, pad)
    end,
    center=function(x, pad, cmdAppend)
        local centerPad = getCenterPad(pad)
        if centerPad > 0 then cmdAppend(1, centerPad) end
        centerPad = pad - centerPad
        if centerPad > 0 then cmdAppend(x + 1, centerPad) end
    end
}


function GpuLine:finalize(screenWidth, align, fillBackground, fillChar, fillColor)
    -- TODO: "justify" align
    -- TODO: split this function

    local pad = screenWidth - self.width
    local x = getStartingX(align, pad)

    local cmds = {}
    local tokenSpaceBuf = ""
    local colors = GpuLineColorControl(function(cmd, a)
        table.insert(cmds, {cmd, a})
    end)

    local function flushTokenSpaceBuf()
        if #tokenSpaceBuf == 0 then return false end
        colors:flush()
        table.insert(cmds, {"set", x + 1, tokenSpaceBuf})
        x = x + utils.strlen(tokenSpaceBuf)
        tokenSpaceBuf = ""
        return true
    end

    local cmdSwitch = {
        ["token"] = function(a)
            tokenSpaceBuf = tokenSpaceBuf .. a  -- TODO: is it optimal?
        end,
        ["space"] = function()
            tokenSpaceBuf = tokenSpaceBuf .. " "
        end,
        ["color"] = function(a)
            flushTokenSpaceBuf()
            colors:setForeground(a)
        end,
        ["background"] = function(a)
            flushTokenSpaceBuf()
            colors:setBackground(a)
        end
    }

    for _, c in ipairs(self.commands) do
        local cmd, a = table.unpack(c)
        cmdSwitch[cmd](a)
    end
    flushTokenSpaceBuf()

    if pad > 0 then
        colors:setForeground(fillColor)
        colors:setBackground(fillBackground)
        colors:flush()
        fillPadding[align](x, pad, function(a, b)
            table.insert(cmds, {"fill", a, b, fillChar})
        end)
    end

    return cmds
end


local function markupToGpuCommands(markup, defaultStyles, selectorTable, screenWidth)
    local currentLine = GpuLine()
    local result = {}
    local currentBlock = {currentLine}

    local styleSwitch = {
        ["color"] = function(value)
            currentLine:color(value)
        end,
        ["background"] = function(value)
            currentLine:background(value)
        end
    }

    local selectorEngine = selectorModule.SelectorEngine(defaultStyles, selectorTable, function(k, v)
        local cb = styleSwitch[k]
        if cb ~= nil then cb(v) end
    end)

    local function finalizeCurrentBlock()
        for i, line in ipairs(currentBlock) do
            if not line:isEmpty() then
                table.insert(result, line:finalize(
                    screenWidth,
                    selectorEngine:getCurrentStyle("align"),
                    selectorEngine:getCurrentStyle("background"),
                    selectorEngine:getCurrentStyle("fill"),
                    selectorEngine:getCurrentStyle("fillcolor")
                ))
            end
        end
        currentBlock = {}
    end

    local function startNewLine(realignBlock)
        if realignBlock then finalizeCurrentBlock() end

        currentLine = GpuLine()
        currentLine:color(selectorEngine:getCurrentStyle("color"))
        currentLine:background(selectorEngine:getCurrentStyle("background"))
        table.insert(currentBlock, currentLine)
    end

    local function fitWidth(len)
        local v = math.min(len, screenWidth - currentLine.width)
        return v == len, v
    end

    local function outputToken(s)
        if currentLine.width >= screenWidth then return end
        local fits, len = fitWidth(utils.strlen(s))
        if not fits then
            s = utils.strsub(s, 1, len - 1) .. "…"
        end
        currentLine:token(s)
    end

    local needPreSpace = false
    local cmdSwitch = {
        [Flow.newLine] = function()
            startNewLine(true)
            needPreSpace = false
        end,
        [Flow.string] = function(value)
            outputToken(value)
        end,
        [Flow.wordSize] = function(value)
            local fits = fitWidth(value + (needPreSpace and 1 or 0))
            if not fits then
                startNewLine(false)
            else
                if needPreSpace then currentLine:space() end
            end
            needPreSpace = true
        end,
        [Flow.pushClass] = function(value)
            selectorEngine:push(value)
        end,
        [Flow.popClass] = function(value)
            selectorEngine:pop()
        end,
        [Flow.startControl] = function(value)
            -- TODO
        end,
        [Flow.endControl] = function()
            -- TODO
        end
    }

    for cmd, value in iterMarkupTokens(markup) do
        cmdSwitch[cmd](value)
    end
    finalizeCurrentBlock()

    return result
end


local function execGpuCommands(gpu, commands, shiftX, shiftY)
    if shiftX == nil then shiftX = 0 end
    if shiftY == nil then shiftY = 0 end

    for Y, lineCmds in ipairs(commands) do
        Y = Y - shiftY
        for _, cmd in ipairs(lineCmds) do
            cmd, a, b, c = table.unpack(cmd)
            if cmd == "set" then
                gpu.set(a - shiftX, Y, b)
            elseif cmd == "fill" then
                gpu.fill(a - shiftX, Y, b, 1, c)
            elseif cmd == "setForeground" then
                gpu.setForeground(a)
            elseif cmd == "setBackground" then
                gpu.setBackground(a)
            end
        end
    end
end


local function tokenDebug(markup)
    local RevFlow = {}
    for k, v in pairs(Flow) do
        RevFlow[v] = k
    end

    for cmd, value in iterMarkupTokens(markup) do
        print(RevFlow[cmd], value)
    end
end


return {
    Span=Span,
    Div=Div,
    Glue=Glue,
    Selector=selectorModule.Selector,
    markupToGpuCommands=markupToGpuCommands,
    execGpuCommands=execGpuCommands,
    testing={
        tokenDebug=tokenDebug,
        Flow=Flow,
        removeGlueAddWordLengths=removeGlueAddWordLengths,
        squashNewLines=squashNewLines,
        removeLastNewLine=removeLastNewLine,
        iterMarkupTokens=iterMarkupTokens,
        classesToStyles=classesToStyles,
        splitIntoLines=splitIntoLines
    }
}
