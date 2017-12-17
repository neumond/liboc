local utils = require("utils")


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


local Styles = utils.makeClass(function(self)
end)


-- local s = Styles()
-- s.add("highlight", {color=0x00ff00})
-- s.add("quote", {align="right", indent=3, marginLeft=4, marginRight=4})


--


local Element = utils.makeClass(function(self, ...)
    -- Abstract Element contains some text
    -- This class is intended for subclassing
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
        local prevGlue = true
        local accuLength = 0

        function appendString(s)
            accuLength = accuLength + #s
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
                    return true, nil
                elseif cmd == Flow.glue then
                    prevGlue = true  -- setting flag and skipping this command
                elseif cmd == Flow.string then
                    if not prevGlue then  -- non-glued word boundary detected
                        flushWord()
                        local idx = appendString(val)
                        return false, idx - 1  -- output everything except last string
                    else  -- glued case
                        prevGlue = false  -- reset flag
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


--


local Span = utils.makeClass(Element, function(super, ...)
    -- Span takes as much horizontal space as needed for content
    -- consequent Spans follow on the same line
    local self = super(...)
end)


-- function Span:getLength()
-- end


--


local Div = utils.makeClass(Element, function(super, ...)
    -- Div takes all the horizontal space available
    -- consequent Divs always start from a new line
    local self = super(...)
end)


function Div:iterTokens()
    local iter = Element.iterTokens(self)
    local stage = 0
    return function()
        if stage == 0 then
            stage = 1
            return Flow.newLine
        elseif stage == 1 then
            local cmd, val = iter()
            if cmd ~= nil then return cmd, val end
            stage = 2
            return Flow.newLine
        end
        return nil
    end
end



function Div:iterTokensCoro()
    coroutine.yield(Flow.newLine)
    Element.iterTokensCoro(self)
    coroutine.yield(Flow.newLine)
end


-- function Div:render(context)
--     context:block()
--     assert(false, "Not implemented")
-- end


--


local Surface = utils.makeClass(function(self)
    -- Represents constrained part of screen capable of outputting Elements
    -- Can scroll vertically over its contents
    self.element = nil
end)


function Surface:changeWidth()
end

--


local VSplitter = utils.makeClass(function(self)
end)


local HSplitter = utils.makeClass(function(self)
end)


--


function makeTestDiv()
    -- <div class="quote">Some nonbr<span class="highlight">eaking</span> word</div>
    return Div(Div(Div("Some", "nonbr", NBR, Span("eaking"):class("highlight"), "words"):class("quote")))
end


function testPrimitives()
    local p = makeTestDiv()
    for cmd, value in squashNewLines(removeGlueAddWordLengths(p:iterTokens())) do
        print(FlowNames[cmd], value)
    end
end


-- outputText()
testPrimitives()
