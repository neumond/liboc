local utils = require("utils")


local Flow = {
    string=1,
    glue=2,
    pushClass=3,
    popClass=4,
    newLine=5,
    wordSize=6
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
    return Div("Some", "nonbr", NBR, Span("eaking"):class("highlight"), "word"):class("quote")
end


function testPrimitives()
    local p = makeTestDiv()
    for cmd, value in p:iterTokens() do
        print("OUTPUT", cmd, value)
    end
end


function outputText()
    local p = makeTestDiv()
    local prevGlue = true
    for cmd, value in p:iterTokens() do
        if cmd == Flow.string then
            if not prevGlue then io.write(" ") end
            io.write(value)
            prevGlue = false
        elseif cmd == Flow.glue then
            prevGlue = true
        end
    end
    print("")
end


function wordSizeWrap()
    local p = makeTestDiv()

    local buf = {}
    local prevGlue = true
    local accuLen = 0

    function flushAccumulatedWord()
        if accuLen > 0 then
            print(Flow.wordSize, accuLen)
        end
        for i, v in ipairs(buf) do
            print(v.cmd, v.value)
        end
        buf = {}
        accuLen = 0
    end

    function delay(cmd, value)
        table.insert(buf, {cmd=cmd, value=value})
        if cmd == Flow.string then
            accuLen = accuLen + #value
        end
    end

    for cmd, value in p:iterTokens() do
        if cmd == Flow.glue then
            prevGlue = true
        else
            if not prevGlue then
                flushAccumulatedWord()
            end
            delay(cmd, value)
            if cmd == Flow.string then
                prevGlue = false
            end
        end
    end

    flushAccumulatedWord()
end


-- outputText()
wordSizeWrap()
