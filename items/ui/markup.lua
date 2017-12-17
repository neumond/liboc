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


function Element:iterTokensCoro()
    if self.className ~= nil then
        coroutine.yield(Flow.pushClass, self.className)
    end

    for _, child in ipairs(self.children) do
        if child._isElement then
            child:iterTokensCoro()
        elseif child._isGlue then
            coroutine.yield(Flow.glue)
        else
            coroutine.yield(Flow.string, child)
        end
    end

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


function Div:iterTokensCoro()
    coroutine.yield(Flow.newLine)
    Element.iterTokensCoro(self)
    coroutine.yield(Flow.newLine)
end


-- Renderer


function renderInner(tokenIter, selectorEngine, gpu)
    local screenWidth, screenHeight = gpu.getResolution()

    screenWidth = screenWidth + 1  -- for 1-based indexing

    local currentLine = 1
    local currentX = 1
    local needPreSpace = false

    function startNewLine()
        gpu.fill(currentX, currentLine, screenWidth - currentX, 1, " ")
        currentLine = currentLine + 1
        currentX = 1
        needPreSpace = false
        return currentLine > screenHeight
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
        gpu.set(currentX, currentLine, s)
        currentX = currentX + len
    end

    for cmd, value in tokenIter do
        if cmd == Flow.newLine then
            if startNewLine() then return end
        elseif cmd == Flow.string then
            outputString(value)
        elseif cmd == Flow.wordSize then
            local fits = fitWidth(value + (needPreSpace and 1 or 0))
            if not fits then
                if startNewLine() then return end
            else
                if needPreSpace then
                    gpu.set(currentX, currentLine, " ")
                    currentX = currentX + 1
                end
                needPreSpace = true
            end
        elseif cmd == Flow.pushClass then
            selectorEngine:push(value)
        elseif cmd == Flow.popClass then
            selectorEngine:pop()
        end
    end
end


function render(markup, styles, gpu)
    -- gpu must provide methods
    --   getResolution
    --   fill
    --   set
    --   getForeground
    --   setForeground
    --   getBackground
    --   setBackground
    -- it can be a proxy object to render into constrained parts of screen

    local oldForeground = gpu.getForeground()
    local oldBackground = gpu.getBackground()

    function changedStyleCallback(k, v)
        if k == "color" then
            gpu.setForeground(v)
        elseif k == "background" then
            gpu.setBackground(v)
        end
    end

    local r = renderInner(
        squashNewLines(removeGlueAddWordLengths(markup:iterTokens())),
        selectorModule.SelectorEngine(styles, changedStyleCallback),
        gpu)

    gpu.setForeground(oldForeground)
    gpu.setBackground(oldBackground)
    return r
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
    render=render
}
