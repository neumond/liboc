-- constants


local CHEST_CASCADES = 3
local maxChests = CHEST_CASCADES * 4


-- globals


local robot = require("robot")
local sides = require("sides")
local component = require("component")
local invComp = component.inventory_controller
local invModule = require("inventory")
local db = require("recipedb")
local utils = require("utils")
local M = {}


-- General navigation on a plane


local Navigation = {
    currentX=0,
    currentZ=0,
    currentRotation="Z+",
    rotationMap = {}
}


for i, v in ipairs({"Z+", "X+", "Z-", "X-"}) do
    Navigation.rotationMap[v] = i
end


function Navigation.planRotation(from, to)
    from = Navigation.currentRotation
    if from == to then return nil end

    from = Navigation.rotationMap[from] - 1
    to = Navigation.rotationMap[to] - 1
    Navigation.currentRotation = to

    if math.abs(from - to) == 2 then return "around" end

    if from - to >= 3 then
        to = to + 4
    elseif to - from >= 3 then
        from = from + 4
    end
    assert(math.abs(from - to) == 1)

    if to > from then
        return "right"
    else
        return "left"
    end
end


function Navigation.rotate(to)
    local r = Navigation.planRotation(Navigation.currentRotation, to)
    if r == "around" then
        robot.turnAround()
    elseif r == "left" then
        robot.turnLeft()
    elseif r == "right" then
        robot.turnRight()
    end
    Navigation.currentRotation = to
end


function Navigation.gotoPosition(x, z)
    function isCoAxial(to)
        return string.sub(Navigation.currentRotation, 1, 1) == to
    end

    function handleAxis(current, target, axis)
        local delta = target - current
        if delta == 0 then return end
        local direction = axis .. (delta > 0 and "+" or "-")
        if not isCoAxial(axis) then Navigation.rotate(direction) end
        for i=1,math.abs(delta) do
            if Navigation.currentRotation == direction then
                assert(robot.forward())
            else
                assert(robot.back())
            end
        end
    end

    if isCoAxial("X") then
        handleAxis(Navigation.currentX, x, "X")
        handleAxis(Navigation.currentZ, z, "Z")
    else
        handleAxis(Navigation.currentZ, z, "Z")
        handleAxis(Navigation.currentX, x, "X")
    end

    Navigation.currentX = x
    Navigation.currentZ = z
end


-- Storage room navigation


function Navigation.getChestPairPosition(n)
    local x = n % 2
    if x == 0 then x = -1 end
    local z = math.floor(n / 2) * 2
    return x, z
end


function Navigation.getChestPosition(n)
    n = n - 1
    x, z = Navigation.getChestPairPosition(math.floor(n / 2))
    return x, z, (n % 2 == 1) and sides.up or sides.down
end


function Navigation.gotoInput()
    Navigation.gotoPosition(-1, -1)
    Navigation.rotate("Z-")
    return sides.front
end


function Navigation.gotoOutput()
    Navigation.gotoPosition(1, -1)
    Navigation.rotate("Z-")
    return sides.front
end


function Navigation.gotoChest(n)
    local x, z, side = Navigation.getChestPosition(n)
    Navigation.gotoPosition(x, z)
    return side
end


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
        item.full:clear(slotId)
        item.half:maybeBetter(slotId)
    else
        item.half:clear(slotId)
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


function ItemToSlotIndex.empty(self, itemId, slotId)
    -- item disappears from a slot
    local item = self:getItem(itemId, false)
    if item == nil then return end
    if item.slots[slotId] == nil then return end

    self.slots[slotId] = nil
    if utils.isTableEmpty(self.slots) then
        -- no more items of this type
        self.data[itemId] = nil
        return
    end
    if item.full:clear(slotId) then
        self.assignNewTip(item, item.full, false)
    end
    if item.half:clear(slotId) then
        self.assignNewTip(item, item.half, true)
    end
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
        tip:maybeBetter(slotId)
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


function SlotIndex.fill(self, slotId, itemId)
    -- item appears in a slot
    self.data[slotId].content = itemId
end


function SlotIndex.empty(self, slotId)
    -- slot becomes empty
    self.data[slotId].content = nil
end


function SlotIndex.get(self, slotId)
    return self.data[slotId].content
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


function IntegratedIndex.registerSlot(self, address, itemId, halfFilled)
    local slotId = self.slots:registerSlot(address)
    if itemId == nil then
        self:empty(slotId)
    else
        self:refill(slotId, itemId, halfFilled)
    end
    return slotId
end


function IntegratedIndex.refill(self, slotId, itemId, halfFilled)
    local existingItem = self.slots:get(slotId)
    if existingItem ~= nil and existingItem ~= itemId then
        -- replacing existing different item
        self:empty(slotId)
    end

    self.itemToSlot:refill(itemId, slotId, halfFilled)
    self.emptyIndex:fill(slotId)
    self.slots:fill(slotId, itemId)
end


function IntegratedIndex.empty(self, slotId)
    local existingItem = self.slots:get(slotId)
    if existingItem == nil then return end  -- already empty

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


-- Slot access functions


local InternalSlot = makeClass(function(self, slot)
    self.slot = slot
end)


function InternalSlot.getStack(self)
    return invComp.getStackInInternalSlot(self.slot)
end


function InternalSlot.suck(self, amount)
    local target = robot.select()
    robot.select(self.slot)
    local success = robot.transferTo(target, amount)
    robot.select(target)
    assert(success, "Can't suck items from internal slot")
end


function InternalSlot.drop(self, amount)
    local success = robot.transferTo(self.slot, amount)
    assert(success, "Can't drop items into internal slot")
end


local ChestSlot = makeClass(function(self, chest, slot)
    self.chest = chest
    self.slot = slot
end)


function ChestSlot.getStack(self)
    local side = Navigation.gotoChest(self.chest)
    return invComp.getStackInSlot(side, self.slot)
end


function ChestSlot.suck(self, amount)
    local side = Navigation.gotoChest(self.chest)
    local success, msg = invComp.suckFromSlot(side, self.slot, amount)
    assert(success, msg)
end


function ChestSlot.drop(self, amount)
    local side = Navigation.gotoChest(self.chest)
    local success, msg = invComp.dropIntoSlot(side, self.slot, amount)
    assert(success, msg)
end


-- Storage


local Storage = {}


function Storage.initialize()
    Storage.index = IntegratedIndex.new()

    function addSlot(address)
        local itemData = address:getStack()
        local itemId = db.detect(itemData)
        return Storage.index:registerSlot(address, itemId)
    end

    for k in invModule.iterNonTableSlots() do
        addSlot(InternalSlot.new(k))
    end
    for i=1,maxChests do
        local side = Navigation.gotoChest(i)
        for k=1,invComp.getInventorySize(side) do
            addSlot(ChestSlot.new(i, k))
        end
    end
end


function Storage.tableSlotToRealSlot(tableSlot)
    local s = M.tableSlots[tableSlot]
    if s == nil then
        s = invModule.tableOutputSlot
    end
    return s
end


function Storage.cleanTableSlot(tableSlot)
    localSlotId = Storage.tableSlotToRealSlot(tableSlot)
    local itemData = invComp.getStackInInternalSlot(localSlotId)
    if itemData == nil then return true end
    local itemId = db.detect(itemData)
    assert(itemId ~= nil, "Unknown item in table slot")

    slotId = Storage.index:findSlotWithItem(itemId)
end


function Storage.cleanTable()
    for i=1,10 do
        if not Storage.cleanTableSlot(i) then return false end
    end
    return true
end


function Storage.fillTableSlot(tableSlot, itemId, amount)
end


--


function runOperation(func)
    assert(robot.up())

    func()

    Navigation.gotoPosition(0, 0)
    Navigation.rotate("Z+")
    assert(robot.down())
end


function main()
    for _, i in ipairs({5, 7, 1, 3, 4, 2}) do
        local x, z, ud = Navigation.getChestPosition(i)
        Navigation.gotoPosition(x, z)
    end
end


M.runOperation = runOperation
M.StorageIndex = StorageIndex
return M
