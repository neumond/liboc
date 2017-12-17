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
    self.class = nil
end)


Element._isElement = true


function Element:setContent(...)
    self.children = {...}
end


function Element:class(s)
    self.class = s
    return self
end


function Element:iterTokensCoro()
    if self.class ~= nil then
        coroutine.yield(Flow.pushClass, self.class)
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

    if self.class ~= nil then
        coroutine.yield(Flow.popClass)
    end
end


function Element:iterTokens()
    return coroutine.wrap(function() self:iterTokensCoro() end)
end


function bufferingIterator(createIter)
    local buf = {}
    local front = 1
    local back = 1
    local finish = false

    function append(...)
        buf[front] = {...}
        front = front + 1
    end

    function prepend(...)
        back = back - 1
        buf[back] = {...}
    end

    local iter = createIter(append, prepend)
    return function()
        if front == back then
            if finish then return nil end
            finish = finish or iter()
        end
        local value = buf[back]
        buf[back] = nil
        back = back + 1
        return unpack(value)
    end
end


function smartElementIter2(iter)
    -- splitting point of words
    -- Flow.string not preceded by Flow.glue
    -- i.e. Flow.glue makes next Flow.string non word-breaking
    return bufferingIterator(function(append, prepend)
        local prevGlue = true
        local overflow = nil
        local accuLength = 0

        function appendString(s)
            accuLength = accuLength + #s
            append(Flow.string, s)
        end

        function flushWord()
            prepend(Flow.wordSize, accuLength)
            accuLength = 0
        end

        return function()
            if overflow ~= nil then
                appendString(overflow)
                overflow = nil
            end
            while true do
                local cmd, val = iter()
                if cmd == nil then
                    flushWord()
                    return true
                end
                if cmd == Flow.glue then
                    prevGlue = true
                else
                    if cmd == Flow.string then
                        if not prevGlue then
                            overflow = val
                            flushWord()
                            return false
                        end
                        prevGlue = false
                        appendString(val)
                    else
                        append(cmd, val)
                    end
                end
            end
        end
    end)
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
    return Div("Some", "nonbr", NBR, Span("eaking"):class("highlight"), "words"):class("quote")
end


function testPrimitives()
    local p = makeTestDiv()
    for cmd, value in smartElementIter2(p:iterTokens()) do
        print(FlowNames[cmd], value)
    end
end


-- outputText()
testPrimitives()
