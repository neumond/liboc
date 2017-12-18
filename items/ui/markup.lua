local utils = require("utils")
local selectorModule = require("ui.selectors")


local Flow = {
    string=1,
    glue=2,
    pushClass=3,
    popClass=4,
    newLine=5,
    wordSize=6
}


local FlowNames = {  -- TODO: remove
    [1]="string",
    [2]="glue",
    [3]="push",
    [4]="pop",
    [5]="newline",
    [6]="word"
}


local NBR = {_isGlue=true}


local Styles = utils.makeClass(function(self)  -- TODO: need?
end)


-- local s = Styles()
-- s.add("highlight", {color=0x00ff00})
-- s.add("quote", {align="right", indent=3, marginLeft=4, marginRight=4})


-- Element
-- Abstract Element contains some text
-- This class is intended for subclassing


local Element = utils.makeClass(function(self, ...)
    self.children = {...}
    self.className = nil
end)


Element._isElement = true


function Element:setContent(...)
    self.children = {...}
end


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
        elseif child._isGlue then
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


function removeGlueAddWordLengths(iter)
    -- splitting point of words
    -- Flow.string not preceded by Flow.glue
    -- i.e. Flow.glue makes next Flow.string non word-breaking
    return utils.bufferingIterator(function(append, prepend)
        local glued = true
        local accuLength = 0

        function appendString(s)
            accuLength = accuLength + utils.strlen(s)
            return append(Flow.string, s)
        end

        function flushWord()
            if accuLength == 0 then return end  -- no word have accumulated
            prepend(Flow.wordSize, accuLength)
            accuLength = 0
        end

        return function()
            while true do
                local cmd, val = iter()
                if cmd == nil then
                    flushWord()
                    return true, nil  -- finish and output everything in buffer
                elseif cmd == Flow.glue then
                    glued = true  -- setting flag and skipping this command
                elseif cmd == Flow.string then
                    if not glued then  -- non-glued word boundary detected
                        flushWord()
                        local idx = appendString(val)
                        return false, idx - 1  -- output everything except last string
                    else  -- glued case
                        glued = false  -- reset flag
                        appendString(val)
                    end
                elseif cmd == Flow.newLine then
                    flushWord()
                    append(cmd, val)
                    return false, nil
                else
                    append(cmd, val)
                end
            end
        end
    end)
end


function squashNewLines(iter)
    local prevNewLine = true  -- true to omit first newLine
    return function()
        while true do
            local cmd, val = iter()
            if cmd == nil then
                return nil
            elseif cmd ~= Flow.newLine then
                if cmd == Flow.string then
                    prevNewLine = false  -- has some content, don't omit newLine
                end
                return cmd, val
            else
                if not prevNewLine then
                    prevNewLine = true
                    return cmd, val
                end
            end
        end
    end
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
    self:iterTokensPushClass()
    self:iterTokensChildren()
    coroutine.yield(Flow.newLine)
    self:iterTokensPopClass()
end


-- Renderer


local GpuLine = utils.makeClass(function(self)
    self.width = 0
    self.spaceCount = 0
    self.commands = {}
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
    table.insert(self.commands, {"setForeground", value})
end


function GpuLine:background(value)
    table.insert(self.commands, {"setBackground", value})
end


function GpuLine:finalize(align, screenWidth)
    -- TODO: "justify" align

    local pad = screenWidth - self.width
    local x = 0
    local centerPad
    if align == "right" then
        x = pad
    elseif align == "center" then
        centerPad = math.floor(pad / 2)
        x = centerPad
    end

    local cmds = {}
    for _, c in ipairs(self.commands) do
        if c[1] == "token" then
            table.insert(cmds, {"set", x + 1, c[2]})
            x = x + utils.strlen(c[2])
        elseif c[1] == "space" then
            table.insert(cmds, {"set", x + 1, " "})
            x = x + 1
        else
            table.insert(cmds, c)
        end
    end

    if pad > 0 then
        if align == "left" then
            table.insert(cmds, {"fill", x + 1, pad, " "})
        elseif align == "right" then
            table.insert(cmds, {"fill", 1, pad, " "})
        elseif align == "center" then
            if centerPad > 0 then
                table.insert(cmds, {"fill", 1, centerPad, " "})
            end
            centerPad = pad - centerPad
            if centerPad > 0 then
                table.insert(cmds, {"fill", x + 1, centerPad, " "})
            end
        end
    end

    return cmds
end


function markupToGpuCommands(markup, styles, screenWidth)
    local currentLine = GpuLine()
    local result = {}
    local currentBlock = {currentLine}
    local currentAlign

    local styleSwitch = {
        ["color"] = function(value)
            currentLine:color(value)
        end,
        ["background"] = function(value)
            currentLine:background(value)
        end,
        ["align"] = function(value)
            currentAlign = value
        end
    }

    local selectorEngine = selectorModule.SelectorEngine(styles, function(k, v)
        styleSwitch[k](v)
    end)

    function finalizeCurrentBlock()
        for i, line in ipairs(currentBlock) do
            table.insert(result, line:finalize(currentAlign, screenWidth))
        end
        currentBlock = {}
    end

    function startNewLine(realignBlock)
        if realignBlock then finalizeCurrentBlock() end

        currentLine = GpuLine()
        table.insert(currentBlock, currentLine)
    end

    function fitWidth(len)
        local v = math.min(len, screenWidth - currentLine.width)
        return v == len, v
    end

    function outputToken(s)
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
        -- [Flow.br] = function()  TODO
        [Flow.pushClass] = function(value)
            selectorEngine:push(value)
        end,
        [Flow.popClass] = function(value)
            selectorEngine:pop()
        end
    }

    for cmd, value in squashNewLines(removeGlueAddWordLengths(markup:iterTokens())) do
        cmdSwitch[cmd](value)
    end
    finalizeCurrentBlock()

    -- TODO: remove last empty line

    return result
end


function execGpuCommands(gpu, commands)
    for Y, lineCmds in ipairs(commands) do
        for _, cmd in ipairs(lineCmds) do
            if cmd[1] == "set" then
                gpu.set(cmd[2], Y, cmd[3])
            elseif cmd[1] == "fill" then
                gpu.fill(cmd[2], Y, cmd[3], 1, cmd[4])
            elseif cmd[1] == "setForeground" then
                gpu.setForeground(cmd[2])
            elseif cmd[1] == "setBackground" then
                gpu.setBackground(cmd[2])
            end
        end
    end
end


-- Example markup
--
-- <div class="quote">Some nonbr<span class="highlight">eaking</span> word</div>
--
-- Div("Some", "nonbr", NBR, Span("eaking"):class("highlight"), "words"):class("quote")


return {
    Span=Span,
    Div=Div,
    NBR=NBR,
    Selector=selectorModule.Selector,
    markupToGpuCommands=markupToGpuCommands,
    execGpuCommands=execGpuCommands
}
