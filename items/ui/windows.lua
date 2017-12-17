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


function smartElementIter(elm)
    local iter = elm:iterTokens()

    local prevGlue = true
    local buf = {}
    local bi = 0
    local flui = 0
    local accuLen = 0
    local flushing = false
    local overDelay = nil

    function flush()
        if accuLen > 0 then  -- word length first
            local a = accuLen
            accuLen = 0
            return Flow.wordSize, a
        end
        if flui < bi then
            flui = flui + 2
            return buf[flui], buf[flui - 1]
        end
        buf = {}
        flushing = false
        delay(overDelay.cmd, overDelay.val)
    end

    function delay(cmd, value)
        buf[bi + 1] = value
        buf[bi + 2] = cmd
        bi = bi + 2
        if cmd == Flow.string then
            accuLen = accuLen + #value
        end
    end

    return function()
        while true do
            if flushing then
                local cmd, val = flush()
                if cmd ~= nil then return cmd, val end
            else
                local cmd, val = iter()
                if cmd == nil then return end
                if cmd == Flow.glue then
                    prevGlue = true
                else
                    if not prevGlue then  -- if outside of glued mode
                        flushing = true  -- flush everything
                        flui = 0
                        overDelay = {cmd=cmd, val=val}
                    else
                        delay(cmd, val)
                    end
                    if cmd == Flow.string then
                        prevGlue = false
                    end
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
    for cmd, value in smartElementIter(p) do
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


-- outputText()
testPrimitives()
