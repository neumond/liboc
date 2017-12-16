local utils = require("utils")


-- ItemTip


local ItemTip = makeClass(function(self)
    self.slot = nil
end)


function ItemTip.maybeBetter(self, slotId)
    if (self.slot == nil) or (slotId < self.slot) then
        self.slot = slotId
    end
end


function ItemTip.clear(self, slotId)
    if slotId == self.slot then
        self.slot = nil
        return true
    end
    return false
end


-- ItemToSlotIndex


local ItemToSlotIndex = makeClass(function(self)
    self.data = {}
end)


function ItemToSlotIndex.getItem(self, itemId, autocreate)
    if autocreate and self.data[itemId] == nil then
        self.data[itemId] = {
            slots={},
            half=ItemTip.new(),
            full=ItemTip.new()
        }
    end
    return self.data[itemId]
end


function ItemToSlotIndex.refill(self, itemId, slotId, halfFilled)
    -- item appears in a slot
    assert(halfFilled ~= nil)
    local item = self:getItem(itemId, true)
    if item.slots[slotId] == halfFilled then return end

    item.slots[slotId] = halfFilled
    if halfFilled then
        self:clearFull(item, slotId)
        item.half:maybeBetter(slotId)
    else
        self:clearHalf(item, slotId)
        item.full:maybeBetter(slotId)
    end
end


function ItemToSlotIndex.assignNewTip(item, tip, halfFilled)
    for slotId, hf in pairs(item.slots) do
        if halfFilled == hf then
            tip:maybeBetter(slotId)
        end
    end
end


function ItemToSlotIndex.autoCleanItem(self, itemId)
    if utils.isTableEmpty(self.data[itemId].slots) then
        -- no more items of this type
        self.data[itemId] = nil
        return true
    end
    return false
end


function ItemToSlotIndex.clearFull(self, item, slotId)
    if item.full:clear(slotId) then
        self.assignNewTip(item, item.full, false)
    end
end


function ItemToSlotIndex.clearHalf(self, item, slotId)
    if item.half:clear(slotId) then
        self.assignNewTip(item, item.half, true)
    end
end


function ItemToSlotIndex.empty(self, itemId, slotId)
    -- item disappears from a slot
    local item = self:getItem(itemId, false)
    if item == nil then return end
    if item.slots[slotId] == nil then return end

    item.slots[slotId] = nil
    if self:autoCleanItem(itemId) then return end
    self:clearFull(item, slotId)
    self:clearHalf(item, slotId)
end


function ItemToSlotIndex.findForInput(self, itemId)
    local item = self:getItem(itemId, false)
    if item == nil then return nil end
    if item.half.slot ~= nil then
        return item.half.slot
    end
    return item.full.slot
end


function ItemToSlotIndex.findForOutput(self, itemId)
    local item = self:getItem(itemId)
    if item == nil then return nil end
    return item.half.slot
end


-- EmptySlotIndex


local EmptySlotIndex = makeClass(function(self)
    -- by default all slots are busy
    -- you have to explicitly .empty for every discovered empty slot
    self.data = {}
    self.tip = ItemTip.new()
end)


function EmptySlotIndex.assignNewTip(self)
    for slotId, _ in pairs(self.data) do
        self.tip:maybeBetter(slotId)
    end
end


function EmptySlotIndex.fill(self, slotId)
    -- slot becomes busy
    if self.data[slotId] == nil then return end

    self.data[slotId] = nil
    if self.tip:clear(slotId) then
        self:assignNewTip()
    end
end


function EmptySlotIndex.empty(self, slotId)
    -- slot becomes empty
    if self.data[slotId] then return end

    self.data[slotId] = true
    self.tip:maybeBetter(slotId)
end


function EmptySlotIndex.find(self)
    -- find an empty slot
    return self.tip.slot
end


-- SlotIndex


local SlotIndex = makeClass(function(self)
    self.data = {}
    self.stock = {}
end)


function SlotIndex.registerSlot(self, address)
    -- register slot at initialization
    -- by default slot is empty
    -- you have to explicitly call .fill for every slot with contents
    local newSlot = {
        address=address,
        content=nil
    }
    table.insert(self.data, newSlot)
    return #self.data
end


function SlotIndex.innerEmpty(self, slotId, c)
    utils.stock.take(self.stock, c.item, c.amount)
    self.data[slotId].content = nil
end


function SlotIndex.fill(self, slotId, itemId, amount)
    -- item appears in a slot
    local c = self.data[slotId].content
    if c ~= nil then
        self:innerEmpty(slotId, c)
    end
    utils.stock.put(self.stock, itemId, amount)
    self.data[slotId].content = {item=itemId, amount=amount}
end


function SlotIndex.empty(self, slotId)
    -- slot becomes empty
    local c = self.data[slotId].content
    if c == nil then return end
    self:innerEmpty(slotId, c)
end


function SlotIndex.get(self, slotId)
    local c = self.data[slotId].content
    if c == nil then
        return nil, 0
    end
    return c.item, c.amount
end


function SlotIndex.getAddress(self, slotId)
    return self.data[slotId].address
end


-- IntegratedIndex


local IntegratedIndex = makeClass(function(self)
    self.itemToSlot = ItemToSlotIndex.new()
    self.emptyIndex = EmptySlotIndex.new()
    self.slots = SlotIndex.new()
end)


function IntegratedIndex.registerSlot(self, address)
    local slotId = self.slots:registerSlot(address)
    self:empty(slotId)
    return slotId
end


function IntegratedIndex.refill(self, slotId, itemId, size, maxSize)
    self.itemToSlot:refill(itemId, slotId, size < maxSize)
    self.emptyIndex:fill(slotId)
    self.slots:fill(slotId, itemId, size)
end


function IntegratedIndex.empty(self, slotId)
    local existingItem = self.slots:get(slotId)
    self.itemToSlot:empty(existingItem, slotId)
    self.emptyIndex:empty(slotId)
    self.slots:empty(slotId)
end


function IntegratedIndex.getAddress(self, slotId)
    return self.slots:getAddress(slotId)
end


function IntegratedIndex.findInputSlot(self, itemId)
    return self.itemToSlot:findForInput(itemId)
end


function IntegratedIndex.findOutputSlot(self, itemId)
    local slotId = self.itemToSlot:findForOutput(itemId)
    if slotId == nil then
        slotId = self.emptyIndex:find()
    end
    return slotId
end


-- Tests


function testItemToSlotIndex_simple()
    local x = ItemToSlotIndex.new()
    -- x:refill(itemId, slotId, halfFilled)
    -- x:empty(itemId, slotId)
    -- x:findForInput(itemId)
    -- x:findForOutput(itemId)

    assert(x:findForInput("stone") == nil)
    assert(x:findForOutput("stone") == nil)

    x:refill("stone", 4, true)
    x:refill("stone", 3, false)

    assert(x:findForInput("stone") == 4)
    assert(x:findForOutput("stone") == 4)

    x:empty("stone", 4)

    assert(x:findForInput("stone") == 3)  -- still can take from full slot
    assert(x:findForOutput("stone") == nil)  -- need new empty slot for output

    x:empty("stone", 3)

    assert(x:findForInput("stone") == nil)
    assert(x:findForOutput("stone") == nil)
end


function testItemToSlotIndex_halfToFull()
    local x = ItemToSlotIndex.new()

    x:refill("stone", 4, true)

    assert(x:findForInput("stone") == 4)
    assert(x:findForOutput("stone") == 4)

    x:refill("stone", 4, false)

    assert(x:findForInput("stone") == 4)
    assert(x:findForOutput("stone") == nil)

    x:refill("stone", 4, true)

    assert(x:findForInput("stone") == 4)
    assert(x:findForOutput("stone") == 4)
end


function testItemToSlotIndex_betterSlots()
    local x = ItemToSlotIndex.new()

    x:refill("stone", 18, false)
    x:refill("stone", 19, false)
    x:refill("stone", 20, true)

    assert(x:findForInput("stone") == 20)
    assert(x:findForOutput("stone") == 20)

    x:refill("stone", 19, true)

    assert(x:findForInput("stone") == 19)
    assert(x:findForOutput("stone") == 19)

    x:refill("stone", 19, false)

    assert(x:findForInput("stone") == 20)
    assert(x:findForOutput("stone") == 20)

    x:empty("stone", 20)

    assert(x:findForInput("stone") == 18)
    assert(x:findForOutput("stone") == nil)

    x:empty("stone", 18)

    assert(x:findForInput("stone") == 19)
    assert(x:findForOutput("stone") == nil)
end


function testItemToSlotIndex_idemp()
    local x = ItemToSlotIndex.new()

    x:refill("stone", 4, true)
    x:refill("stone", 4, true)
    x:refill("stone", 4, true)

    assert(x:findForInput("stone") == 4)
    assert(x:findForOutput("stone") == 4)

    x:refill("stone", 4, false)
    x:refill("stone", 4, false)
    x:refill("stone", 4, false)

    assert(x:findForInput("stone") == 4)
    assert(x:findForOutput("stone") == nil)

    x:empty("stone", 4)
    x:empty("stone", 4)
    x:empty("stone", 4)

    assert(x:findForInput("stone") == nil)
    assert(x:findForOutput("stone") == nil)
end


function testEmptySlotIndex()
    local x = EmptySlotIndex.new()
    -- x:fill(slotId)
    -- x:empty(slotId)
    -- x:find()

    assert(x:find() == nil)

    x:empty(19)

    assert(x:find() == 19)

    x:fill(19)

    assert(x:find() == nil)

    x:empty(19)
    x:empty(25)
    x:empty(14)
    x:empty(14)
    x:empty(14)
    x:empty(48)

    assert(x:find() == 14)

    x:fill(14)

    assert(x:find() == 19)

    x:fill(25)
    x:fill(25)
    x:fill(25)
    x:fill(19)

    assert(x:find() == 48)

    x:fill(48)

    assert(x:find() == nil)
end


function testSlotIndex()
    local x = SlotIndex.new()
    -- x:registerSlot(address)
    -- x:fill(slotId, itemId, amount)
    -- x:empty(slotId)
    -- x:get(slotId)

    local slotA = x:registerSlot(nil)
    local slotB = x:registerSlot(nil)

    x:fill(slotA, "stone", 10)

    assert(x.stock["stone"] == 10)

    x:fill(slotB, "stone", 10)

    assert(x.stock["stone"] == 20)

    x:fill(slotB, "stone", 40)

    assert(x.stock["stone"] == 50)

    x:empty(slotB)

    assert(x.stock["stone"] == 10)
end


function testRealBug1()
    local initialItems = {}
    for i=239,247 do
        initialItems[i] = {"cobblestone", 64, 64}
    end
    for i=347,349 do
        initialItems[i] = {"redstone", 64, 64}
    end
    for i=401,410 do
        initialItems[i] = {"iron_ingot", 64, 64}
    end
    initialItems[509] = {"wood", 64, 64}
    initialItems[563] = {"wood", 64, 64}
    initialItems[564] = {"wood", 64, 64}

    local x = IntegratedIndex.new()
    for i=1,670 do
        x:registerSlot(nil)
        if initialItems[i] ~= nil then
            x:refill(i, unpack(initialItems[i]))
        else
            x:empty(i)
        end
    end

    x:refill(509, "wood", 48, 64)
    x:refill(1, "planks", 64, 64)
    x:refill(509, "wood", 32, 64)
    x:refill(2, "planks", 64, 64)
    x:refill(509, "wood", 16, 64)
    x:refill(3, "planks", 64, 64)
    x:refill(509, "wood", 11, 64)
    x:refill(4, "planks", 20, 64)
    x:empty(4)

    local slotId = x:findInputSlot("planks")
    assert(slotId == 1)
end


function runTests()
    testItemToSlotIndex_simple()
    testItemToSlotIndex_halfToFull()
    testItemToSlotIndex_betterSlots()
    testItemToSlotIndex_idemp()
    testEmptySlotIndex()
    testSlotIndex()
    testRealBug1()
end


-- Module export


-- runTests()
local M = {}
M.IntegratedIndex = IntegratedIndex
return M
