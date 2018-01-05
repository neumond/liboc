local utils = require("utils")


-- ItemTip


local ItemTip = utils.makeClass(function(self)
    self.slot = nil
end)


function ItemTip:maybeBetter(slotId)
    if (self.slot == nil) or (slotId < self.slot) then
        self.slot = slotId
    end
end


function ItemTip:clear(slotId)
    if slotId == self.slot then
        self.slot = nil
        return true
    end
    return false
end


-- ItemToSlotIndex


local ItemToSlotIndex = utils.makeClass(function(self)
    self.data = {}
end)


function ItemToSlotIndex:getItem(itemId, autocreate)
    if autocreate and self.data[itemId] == nil then
        self.data[itemId] = {
            slots={},
            half=ItemTip(),
            full=ItemTip()
        }
    end
    return self.data[itemId]
end


function ItemToSlotIndex:refill(itemId, slotId, halfFilled)
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


-- class method
function ItemToSlotIndex.assignNewTip(item, tip, halfFilled)
    for slotId, hf in pairs(item.slots) do
        if halfFilled == hf then
            tip:maybeBetter(slotId)
        end
    end
end


function ItemToSlotIndex:autoCleanItem(itemId)
    if utils.isTableEmpty(self.data[itemId].slots) then
        -- no more items of this type
        self.data[itemId] = nil
        return true
    end
    return false
end


function ItemToSlotIndex:clearFull(item, slotId)
    if item.full:clear(slotId) then
        self.assignNewTip(item, item.full, false)
    end
end


function ItemToSlotIndex:clearHalf(item, slotId)
    if item.half:clear(slotId) then
        self.assignNewTip(item, item.half, true)
    end
end


function ItemToSlotIndex:empty(itemId, slotId)
    -- item disappears from a slot
    local item = self:getItem(itemId, false)
    if item == nil then return end
    if item.slots[slotId] == nil then return end

    item.slots[slotId] = nil
    if self:autoCleanItem(itemId) then return end
    self:clearFull(item, slotId)
    self:clearHalf(item, slotId)
end


function ItemToSlotIndex:findForInput(itemId)
    local item = self:getItem(itemId, false)
    if item == nil then return nil end
    if item.half.slot ~= nil then
        return item.half.slot
    end
    return item.full.slot
end


function ItemToSlotIndex:findForOutput(itemId)
    local item = self:getItem(itemId)
    if item == nil then return nil end
    return item.half.slot
end


-- EmptySlotIndex


local EmptySlotIndex = utils.makeClass(function(self)
    -- by default all slots are busy
    -- you have to explicitly .empty for every discovered empty slot
    self.data = {}
    self.tip = ItemTip()
end)


function EmptySlotIndex:assignNewTip()
    for slotId, _ in pairs(self.data) do
        self.tip:maybeBetter(slotId)
    end
end


function EmptySlotIndex:fill(slotId)
    -- slot becomes busy
    if self.data[slotId] == nil then return end

    self.data[slotId] = nil
    if self.tip:clear(slotId) then
        self:assignNewTip()
    end
end


function EmptySlotIndex:empty(slotId)
    -- slot becomes empty
    if self.data[slotId] then return end

    self.data[slotId] = true
    self.tip:maybeBetter(slotId)
end


function EmptySlotIndex:find()
    -- find an empty slot
    return self.tip.slot
end


-- SlotIndex


local SlotIndex = utils.makeClass(function(self)
    self.data = {}
    self.stock = {}
end)


function SlotIndex:registerSlot(address)
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


function SlotIndex:innerEmpty(slotId, c)
    utils.stock.take(self.stock, c.item, c.amount)
    self.data[slotId].content = nil
end


function SlotIndex:fill(slotId, itemId, amount)
    -- item appears in a slot
    local c = self.data[slotId].content
    if c ~= nil then
        self:innerEmpty(slotId, c)
    end
    utils.stock.put(self.stock, itemId, amount)
    self.data[slotId].content = {item=itemId, amount=amount}
end


function SlotIndex:empty(slotId)
    -- slot becomes empty
    local c = self.data[slotId].content
    if c == nil then return end
    self:innerEmpty(slotId, c)
end


function SlotIndex:get(slotId)
    local c = self.data[slotId].content
    if c == nil then
        return nil, 0
    end
    return c.item, c.amount
end


function SlotIndex:getAddress(slotId)
    return self.data[slotId].address
end


-- IntegratedIndex


local IntegratedIndex = utils.makeClass(function(self)
    self.itemToSlot = ItemToSlotIndex()
    self.emptyIndex = EmptySlotIndex()
    self.slots = SlotIndex()
end)


function IntegratedIndex:registerSlot(address)
    local slotId = self.slots:registerSlot(address)
    self:empty(slotId)
    return slotId
end


function IntegratedIndex:refill(slotId, itemId, size, maxSize)
    local existingItem = self.slots:get(slotId)
    if existingItem ~= itemId then
        self.itemToSlot:empty(existingItem, slotId)
    end
    self.itemToSlot:refill(itemId, slotId, size < maxSize)
    self.emptyIndex:fill(slotId)
    self.slots:fill(slotId, itemId, size)
end


function IntegratedIndex:empty(slotId)
    local existingItem = self.slots:get(slotId)
    self.itemToSlot:empty(existingItem, slotId)
    self.emptyIndex:empty(slotId)
    self.slots:empty(slotId)
end


function IntegratedIndex:getAddress(slotId)
    return self.slots:getAddress(slotId)
end


function IntegratedIndex:findInputSlot(itemId)
    return self.itemToSlot:findForInput(itemId)
end


function IntegratedIndex:findOutputSlot(itemId)
    local slotId = self.itemToSlot:findForOutput(itemId)
    if slotId == nil then
        slotId = self.emptyIndex:find()
    end
    return slotId
end


-- Module export


return {
    IntegratedIndex=IntegratedIndex,
    testing={
        ItemToSlotIndex=ItemToSlotIndex,
        EmptySlotIndex=EmptySlotIndex,
        SlotIndex=SlotIndex
    }
}
