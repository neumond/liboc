local utils = require("utils")


local DEFAULT_STYLES = {
    color=0xFFFFFF,
    background=0x000000
}


-- Selector


local Selector = utils.makeClass(function(self, classChain, styleTable)
    self.classChain = classChain
    self.styleTable = styleTable
end)


-- StyleStack


local StyleStack = utils.makeClass(function(self, changedStyleCallback)
    self.changedStyleCallback = changedStyleCallback

    self.activeStyleSets = {
        [-1]=utils.copyTable(DEFAULT_STYLES)
    }
    -- this must use selector indices as priorities
    -- bigger index = higher priority of this styleset
    -- indices must be unique

    self.minIndex = -1
    self.maxIndex = -1

    self.currentStyles = utils.copyTable(DEFAULT_STYLES)  -- style values
    self.currentStyleIndices = {}  -- top priorities for every style

    for k, v in pairs(self.currentStyles) do
        self.changedStyleCallback(k, v)
    end
end)


function StyleStack:setCurrentStyle(name, value, selectorIndex)
    if self.currentStyles[name] ~= value then
        self.changedStyleCallback(name, value)
    end
    self.currentStyles[name] = value
    self.currentStyleIndices[name] = selectorIndex
end


function StyleStack:insertStyle(name, value, selectorIndex)
    -- fast-return if higher prio style already engaged
    if (self.currentStyleIndices[name] or self.minIndex) >= selectorIndex then return end
    self:setCurrentStyle(name, value, selectorIndex)
end


function StyleStack:recalcStyle(name)
    for i=self.maxIndex,self.minIndex,-1 do
        if self.activeStyleSets[i] ~= nil then
            if self.activeStyleSets[i][name] ~= nil then
                self:setCurrentStyle(name, self.activeStyleSets[i][name], i)
                return
            end
        end
    end
    self:setCurrentStyle(name, nil, nil)
end


function StyleStack:recalcMaxIndex()
    for i=self.maxIndex,self.minIndex,-1 do
        if self.activeStyleSets[i] ~= nil then
            self.maxIndex = i
            break
        end
    end
end


function StyleStack:activate(styleSet, selectorIndex)
    for k, v in pairs(styleSet) do
        self:insertStyle(k, v, selectorIndex)
    end

    assert(self.activeStyleSets[selectorIndex] == nil)
    self.activeStyleSets[selectorIndex] = styleSet
    self.maxIndex = math.max(self.maxIndex, selectorIndex)
end


function StyleStack:deactivate(selectorIndex)
    local styleSet = self.activeStyleSets[selectorIndex]
    self.activeStyleSets[selectorIndex] = nil
    if self.maxIndex == selectorIndex then
        self:recalcMaxIndex()
    end

    for k, v in pairs(styleSet) do
        if self.currentStyleIndices[k] == selectorIndex then
            self:recalcStyle(k)
        end
    end
end


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


local SelectorEngine = utils.makeClass(function(self, selectorTable, changedStyleCallback)
    self.selectorTable = {}
    self.styleSets = {}
    for selectorIndex, sel in ipairs(selectorTable) do
        self.selectorTable[selectorIndex] = SelectorState(sel)
        self.styleSets[selectorIndex] = sel.styleTable
    end

    self.expected = {}
    self.downward = {}
    self.stackPtr = 1
    self.styleStack = StyleStack(changedStyleCallback)

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
        for selectorIndex, _ in pairs(t) do
            local ss = self.selectorTable[selectorIndex]
            self:removeExpectation(className, selectorIndex)
            self:addDownward(selectorIndex)
            if ss:push() then
                self.styleStack:activate(self.styleSets[selectorIndex], selectorIndex)
            else
                self:addExpectation(ss:getExpectedClassName(), selectorIndex)
            end
        end
    end

    self.stackPtr = self.stackPtr + 1
end


function SelectorEngine:pop()
    self.stackPtr = self.stackPtr - 1

    local t = self.downward[self.stackPtr]
    if t ~= nil then
        for selectorIndex, _ in pairs(t) do
            local ss = self.selectorTable[selectorIndex]
            self:removeDownward(selectorIndex)
            if not ss:isTriggered() then  -- already triggered selectors are not in expectation table
                self:removeExpectation(ss:getExpectedClassName(), selectorIndex)
            end
            if ss:pop() then
                self.styleStack:deactivate(selectorIndex)
            end
            self:addExpectation(ss:getExpectedClassName(), selectorIndex)
        end
    end
end


function testSelectorEngine()
    function changedStyleCallback(k, v)
        print(k, v)
    end

    local engine = SelectorEngine({
        Selector({"quote", "em"}, {border=1, align="center"}),
        Selector({"quote", "lol"}, {color=0xFF0000}),
        Selector({"p"}, {}),
    }, changedStyleCallback)

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


-- testSelectorEngine()


return {
    Selector=Selector,
    SelectorEngine=SelectorEngine
}