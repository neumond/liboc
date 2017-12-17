local utils = require("utils")


local Selector = utils.makeClass(function(self, classChain, styleTable)
    self.classChain = classChain
    self.styleTable = styleTable
end)


-- SelectorState


local SelectorState = utils.makeClass(function(self, selector)
    self.selector = selector
    self.trigger = #self.selector.classChain + 1
    self.ptr = 1
end)


function SelectorState:push()
    -- returns true if selector has triggered
    if self:isTriggered() then return true end
    self.ptr = self.ptr + 1
    return self:isTriggered()
end


function SelectorState:pop()
    -- returns true if selector has UNtriggered
    local was = self:isTriggered()
    self.ptr = self.ptr - 1
    assert(self.ptr >= 1)
    return was
end


function SelectorState:getExpectedClassName()
    return self.selector.classChain[self.ptr]
end


function SelectorState:isTriggered()
    return self.ptr >= self.trigger
end


-- SelectorEngine


local SelectorEngine = utils.makeClass(function(self, selectorTable)
    self.selectorTable = {}
    for selectorIndex, sel in ipairs(selectorTable) do
        self.selectorTable[selectorIndex] = SelectorState(sel)
    end

    self.expected = {}
    self.downward = {}
    self.stackPtr = 1

    for selectorIndex, ss in ipairs(self.selectorTable) do
        self:addExpectation(ss:getExpectedClassName(), selectorIndex)
    end
end)


function SelectorEngine:addExpectation(className, selectorIndex)
    if self.expected[className] == nil then
        self.expected[className] = {}
    end
    self.expected[className][selectorIndex] = true
end


function SelectorEngine:removeExpectation(className, selectorIndex)
    self.expected[className][selectorIndex] = nil
end


function SelectorEngine:addDownward(selectorIndex)
    if self.downward[self.stackPtr] == nil then
        self.downward[self.stackPtr] = {}
    end
    self.downward[self.stackPtr][selectorIndex] = true
end


function SelectorEngine:removeDownward(selectorIndex)
    self.downward[self.stackPtr][selectorIndex] = nil
end


function SelectorEngine:push(className)
    local t = self.expected[className]
    if t ~= nil then
        local triggered = {}
        for selectorIndex, _ in pairs(t) do
            local ss = self.selectorTable[selectorIndex]
            self:removeExpectation(className, selectorIndex)
            self:addDownward(selectorIndex)
            if ss:push() then
                table.insert(triggered, selectorIndex)
            else
                self:addExpectation(ss:getExpectedClassName(), selectorIndex)
            end
        end
        for _, v in ipairs(triggered) do
            print("TRIGGERED", v)
        end
        -- TODO: sort `triggered`, then consequently
        -- push to style stack ss.styles
        -- NOTE: this algorithm is wrong, sorting wouldn't help
        -- you can have selector 5 triggered, then selector 3
        -- if triggered must not be on top of 5
    end

    self.stackPtr = self.stackPtr + 1
end


function SelectorEngine:pop()
    self.stackPtr = self.stackPtr - 1

    local t = self.downward[self.stackPtr]
    if t ~= nil then
        local untriggered = {}
        for selectorIndex, _ in pairs(t) do
            local ss = self.selectorTable[selectorIndex]
            self:removeDownward(selectorIndex)
            if not ss:isTriggered() then  -- already triggered selectors are not in expectation table
                self:removeExpectation(ss:getExpectedClassName(), selectorIndex)
            end
            if ss:pop() then
                table.insert(untriggered, selectorIndex)
            end
            self:addExpectation(ss:getExpectedClassName(), selectorIndex)
        end
        -- TODO: handle `untriggered`
        for _, v in ipairs(untriggered) do
            print("UNTRIGGERED", v)
        end
    end
end


function testSelectorEngine()
    local engine = SelectorEngine{
        Selector({"quote", "em"}, {border=1, align="center"}),
        Selector({"quote", "lol"}, {}),
        Selector({"p"}, {}),
    }

    engine:push("lol")
    engine:pop()

    print("=========")

    engine:push("p")
    engine:pop()

    print("=========")

    engine:push("p")
    engine:push("p")
    engine:push("p")
    engine:push("p")
    engine:push("p")
    engine:pop()
    engine:pop()
    engine:pop()
    engine:pop()
    engine:pop()

    print("=========")

    engine:push("quote")
    engine:push("p")
    engine:pop()
    engine:push("em")
    engine:pop()
    engine:pop()

    print("=========")

    engine:push("quote")
    engine:push("p")
    engine:push("em")
    engine:pop()
    engine:pop()
    engine:pop()

    print("=========")

    engine:push("quote")
    engine:push("p")
    engine:push("lol")
    engine:push("em")
    engine:pop()
    engine:pop()
    engine:pop()
    engine:pop()

    print("=========")
end


testSelectorEngine()
