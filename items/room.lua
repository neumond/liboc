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
local IntegratedIndex = require("roomindex").IntegratedIndex
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
    if tableSlot == "output" then
        return invModule.tableOutputSlot
    end
    return M.tableSlots[tableSlot]
end


function Storage.updateSlotIndex(self, slotId)
    local accessor = Storage.index:getAddress(slotId)
    local itemData = accessor:getStack()
    if itemData == nil then
        Storage.index:empty(slotId)
        return
    end
    local itemId = db.detect(itemData)
    assert(itemId ~= nil, "Unknown item in storage slot")
    Storage.index:refill(slotId, itemId, itemData.size < itemData.maxSize)
end


function Storage.cleanTableSlot(tableSlot)
    local localSlotId = Storage.tableSlotToRealSlot(tableSlot)
    local itemData = invComp.getStackInInternalSlot(localSlotId)
    if itemData == nil then return end  -- already empty
    local itemId = db.detect(itemData)
    assert(itemId ~= nil, "Unknown item in table slot")

    repeat
        slotId = Storage.index:findOutputSlot(itemId)
        assert(slotId ~= nil, "No slot for output available")
        Storage.index:getAddress(slotId):drop(itemData.size)
        Storage.updateSlotIndex(slotId)
        itemData = invComp.getStackInInternalSlot(localSlotId)
    until itemData == nil
end


function Storage.fillTableSlot(tableSlot, itemId, amount)
    -- NOTE: MUST be emptied (cleanTableSlot) before filling
    -- this is done to avoid extra checks, for some additional speed

    assert(amount > 0)
    assert(amount <= 64)
    local localSlotId = Storage.tableSlotToRealSlot(tableSlot)
    local itemData = nil

    repeat
        slotId = Storage.index:findInputSlot(itemId)
        assert(slotId ~= nil, "No slot with such item available")
        Storage.index:getAddress(slotId):suck(amount)
        Storage.updateSlotIndex(slotId)
        itemData = invComp.getStackInInternalSlot(localSlotId)
    until itemData.size == amount
end


function Storage.cleanTable()
    for i=1,9 do
        Storage.cleanTableSlot(i)
    end
    Storage.cleanTableSlot("output")
end


function Storage.assembleRecipe(itemId, amount)
    local dbItem = db.items[itemId]
    if amount > 1 then
        local maxAmount
        db.recipeOutput(itemId)
    end

    Storage.cleanTable()
    for i=1,9 do
        local itemId = dbItem.recipe[i]
        if itemId ~= nil then
            Storage.fillTableSlot(i, itemId, 1)
        end
    end
    robot.select(Storage.tableSlotToRealSlot("output"))

    local success, n = component.crafting.craft(amount)
    assert(success, "Crafting has failed")
    assert(n > 0, "Nothing has been crafted")
end


-- function M.assemble(itemId, amount)
--     if amount == nil then amount = 1 end
--     local success, clog = craftingPlanner.craft(M.getStockData(), itemId, amount)
--     if not success then
--         print("Not enough items")
--         for k, v in pairs(clog) do
--             print(string.format("%s: %i", db.getItemName(k), v))
--         end
--         return false
--     end
--
--     for i, v in ipairs(clog) do
--         print(string.format("Assembling %s", db.getItemName(v.item)))
--         for k=1,v.times do
--             print(string.format("Pass %i of %i", k, v.times))
--             if not M.assembleRecipe(db.items[v.item].recipe, db.recipeOutput(v.item)) then
--                 print("Recipe assembly has failed")
--                 return false
--             end
--         end
--     end
--     print("Finished successfully.")
--     return true
-- end


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
