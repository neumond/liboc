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


function Element:preIterTokensCoro()
end


function Element:postIterTokensCoro()
end


function Element:iterTokensCoro()
    if self.className ~= nil then
        coroutine.yield(Flow.pushClass, self.className)
    end

    self:preIterTokensCoro()

    for _, child in ipairs(self.children) do
        if child._isElement then
            child:iterTokensCoro()
        elseif child._isGlue then
            coroutine.yield(Flow.glue)
        else
            coroutine.yield(Flow.string, child)
        end
    end

    self:postIterTokensCoro()

    if self.className ~= nil then
        coroutine.yield(Flow.popClass)
    end
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


function Div:preIterTokensCoro()
    coroutine.yield(Flow.newLine)
end


function Div:postIterTokensCoro()
    coroutine.yield(Flow.newLine)
end


-- Renderer


function markupToGpuCommands(markup, styles, screenWidth)
    screenWidth = screenWidth + 1  -- for 1-based indexing

    local currentLine = 1
    local currentX = 1
    local needPreSpace = false
    local result = {{}}

    function perform(...)
        table.insert(result[currentLine], {...})
    end

    function startNewLine()
        perform("fillpad", currentX - 1)
        currentLine = currentLine + 1
        result[currentLine] = {}
        currentX = 1
        needPreSpace = false
    end

    function fitWidth(len)
        local v = math.min(len, screenWidth - currentX)
        return v == len, v
    end

    function outputString(s)
        if currentX >= screenWidth then return end
        local fits, len = fitWidth(utils.strlen(s))
        if not fits then
            s = utils.strsub(s, 1, len - 1) .. "…"
        end
        perform("token", s, currentX)
        currentX = currentX + len
    end

    local styleSwitch = {
        ["color"] = function(value)
            perform("color", value)
        end,
        ["background"] = function(value)
            perform("background", value)
        end
    }

    local selectorEngine = selectorModule.SelectorEngine(styles, function(k, v)
        styleSwitch[k](v)
    end)

    local cmdSwitch = {
        [Flow.newLine] = function()
            startNewLine()
        end,
        [Flow.string] = function(value)
            outputString(value)
        end,
        [Flow.wordSize] = function(value)
            local fits = fitWidth(value + (needPreSpace and 1 or 0))
            if not fits then
                startNewLine()
            else
                if needPreSpace then
                    perform("space", currentX)
                    currentX = currentX + 1
                end
                needPreSpace = true
            end
        end,
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

    return result
end


function execGpuCommands(gpu, commands)
    for Y, lineCmds in ipairs(commands) do
        for _, cmd in ipairs(lineCmds) do
            if cmd[1] == "token" then
                gpu.set(cmd[3], Y, cmd[2])
            elseif cmd[1] == "space" then
                gpu.set(cmd[2], Y, " ")
            elseif cmd[1] == "color" then
                gpu.setForeground(cmd[2])
            elseif cmd[1] == "background" then
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
