local utils = require("utils")
local IntegratedIndex = require("roomBot.storageIndex").IntegratedIndex
local db = require("recipedb")


-- CraftingTable


local CraftingTable = utils.makeClass(function(self, inventorySize)
    self.inventorySize = inventorySize
end)


do
    local c = CraftingTable
    c.tableSlots = {
        1, 2, 3,
        5, 6, 7,
        9, 10, 11
    }
    c.tableOutputSlot = 4
    c.isTable = {}
    for _, v in pairs(c.tableSlots) do
        c.isTable[v] = true
    end
    c.isTable[c.tableOutputSlot] = true
end


function CraftingTable:iterNonTableSlots()
    local i = 0
    return function()
        repeat
            i = i + 1
        until not self.isTable[i]
        if i > self.inventorySize then return end
        return i
    end
end


function CraftingTable:tableSlotToRealSlot(tableSlot)
    if tableSlot == "output" then
        return CraftingTable.tableOutputSlot
    end
    return CraftingTable.tableSlots[tableSlot]
end


-- Slot access classes

-- local s = Slot(...)
-- local itemData = s:getStack()
-- s:suck(amount)
-- s:drop(amount)
-- TODO: return values for suck/drop


local InternalSlot = utils.makeClass(function(self, robot, inventoryController, slot)
    self.robot = robot
    self.inventoryController = inventoryController
    self.slot = slot
end)


function InternalSlot:getStack()
    return self.inventoryController.getStackInInternalSlot(self.slot)
end


function InternalSlot:suck(amount)
    local target = self.robot.select()
    self.robot.select(self.slot)
    local success = self.robot.transferTo(target, amount)
    self.robot.select(target)
    assert(success, "Can't suck items from internal slot")
end


function InternalSlot:drop(amount)
    local success = self.robot.transferTo(self.slot, amount)
    assert(success, "Can't drop items into internal slot")
end


local ChestSlot = utils.makeClass(function(self, nav, inventoryController, chest, slot)
    self.nav = nav
    self.inventoryController = inventoryController
    self.chest = chest
    self.slot = slot
end)


function ChestSlot:getStack()
    local side = self.nav:gotoChest(self.chest)
    return self.inventoryController.getStackInSlot(side, self.slot)
end


function ChestSlot:suck(amount)
    local side = self.nav:gotoChest(self.chest)
    local success, msg = self.inventoryController.suckFromSlot(side, self.slot, amount)
    assert(success, msg)
end


function ChestSlot:drop(amount)
    local side = self.nav:gotoChest(self.chest)
    local success, msg = self.inventoryController.dropIntoSlot(side, self.slot, amount)
    assert(success, msg)
end


-- CrafterStorage


local CrafterStorage = utils.makeClass(function(self, robot, inventoryController, nav)
    self.robot = robot
    self.inventoryController = inventoryController
    self.nav = nav
    self.index = IntegratedIndex()
    self.table = CraftingTable(self.robot.inventorySize())
    self.exchangeSlots = {}

    local function addSlot(address)
        local slotId = self.index:registerSlot(address)
        self:updateSlotIndex(slotId)
        return slotId
    end

    for k in self.table:iterNonTableSlots() do
        local slotId = addSlot(InternalSlot(self.robot, self.inventoryController, k))
        table.insert(self.exchangeSlots, slotId)
    end
    for side, i in self.nav:walkAllChests() do
        for k=1,self.inventoryController.getInventorySize(side) do
            addSlot(ChestSlot(self.nav, self.inventoryController, i, k))
        end
    end
end)


function CrafterStorage:updateSlotIndex(slotId)
    local accessor = self.index:getAddress(slotId)
    local itemData = accessor:getStack()
    if itemData == nil then
        self.index:empty(slotId)
        return
    end
    local itemId = db.detect(itemData)
    assert(itemId ~= nil, "Unknown item in storage slot")
    self.index:refill(slotId, itemId, itemData.size, itemData.maxSize)
end


function CrafterStorage:getInternalStack(localSlotId)
    return self.inventoryController.getStackInInternalSlot(localSlotId)
end


function CrafterStorage:cleanTableSlot(tableSlot)
    local localSlotId = self.table:tableSlotToRealSlot(tableSlot)
    local itemData = self:getInternalStack(localSlotId)
    if itemData == nil then return end  -- already empty
    local itemId = db.detect(itemData)
    assert(itemId ~= nil, "Unknown item in table slot")
    self.robot.select(localSlotId)

    repeat
        slotId = self.index:findOutputSlot(itemId)
        assert(slotId ~= nil, "No slot for output available")
        self.index:getAddress(slotId):drop(itemData.size)
        self:updateSlotIndex(slotId)
        itemData = self:getInternalStack(localSlotId)
    until itemData == nil
end


function CrafterStorage:fillTableSlot(tableSlot, itemId, amount)
    -- NOTE: MUST be emptied (cleanTableSlot) before filling
    -- this is done to avoid extra checks, for some additional speed
    -- items MUST be available

    assert(amount > 0)
    assert(amount <= db.getItemStack(itemId))
    local localSlotId = self.table:tableSlotToRealSlot(tableSlot)
    self.robot.select(localSlotId)
    local itemData = {size=0}

    repeat
        slotId = self.index:findInputSlot(itemId)
        assert(slotId ~= nil, "No slot with such item available")
        self.index:getAddress(slotId):suck(amount - itemData.size)
        self:updateSlotIndex(slotId)
        itemData = self:getInternalStack(localSlotId)
    until itemData.size == amount
end


function CrafterStorage:cleanTable()
    for i=1,9 do
        self:cleanTableSlot(i)
    end
    self:cleanTableSlot("output")
end


function CrafterStorage:selectOutput()
    self.robot.select(self.table:tableSlotToRealSlot("output"))
end


function CrafterStorage:getStock()
    -- NOTE: don't modify returned table!
    return self.index.slots.stock
end


function CrafterStorage:reindexLocalInventory()
    for _, slotId in ipairs(self.exchangeSlots) do
        self:updateSlotIndex(slotId)
    end
    self:cleanTable()
end


local function writeToLog(data)
    local f = assert(io.open("test.log", "a"))
    f:write(require("serialization").serialize(data, false))
    f:write("\n")
    f:close()
end


function CrafterStorage:cleanLocalInventory()
    self:cleanTable()
    local tableSlotId = 1

    -- fake items to keep slot busy in index
    for _, slotId in ipairs(self.exchangeSlots) do
        self.index:refill(slotId, "__stub__", 1, 1)
    end

    writeToLog(self:getStock())

    for _, slotId in ipairs(self.exchangeSlots) do
        local accessor = self.index:getAddress(slotId)
        local itemData = accessor:getStack()
        if itemData ~= nil then
            self.robot.select(self.table:tableSlotToRealSlot(tableSlotId))
            accessor:suck(itemData.size)
            assert(accessor:getStack() == nil)
            self:cleanTableSlot(tableSlotId)
        end
    end

    writeToLog(self:getStock())

    -- remove fake items from index
    for _, slotId in ipairs(self.exchangeSlots) do
        self.index:empty(slotId)
    end

    writeToLog(self:getStock())
end


function CrafterStorage:takeResult(itemId, amount)
    local tableSlot = 1
    local rest = amount
    while rest > 0 do
        assert(tableSlot <= 9)
        local x = math.min(rest, db.getItemStack(itemId))
        self:fillTableSlot(tableSlot, itemId, x)
        rest = rest - x
        tableSlot = tableSlot + 1
    end
end


return {
    CrafterStorage=CrafterStorage
}
