local M = {}
local utils = require("utils")
local db = require("recipedb")
local component = require("component")
local inv = component.inventory_controller
local robot = require("robot")
local craftingPlanner = require("crafting")


local table = {
    1, 2, 3,
    5, 6, 7,
    9, 10, 11
}
local is_table = {}
for i, v in pairs(table) do is_table[v] = true end
local output_slot = 4
is_table[output_slot] = true


function iterNonTableSlots()
    local i=0
    local n=robot.inventorySize()
    return function()
        repeat
            i = i + 1
        until not is_table[i]
        if i > n then return end
        return i
    end
end


function M.getStockData()
    local r = {}
    for i=1,robot.inventorySize() do
        local slot = inv.getStackInInternalSlot(i)
        local itemId = db.detect(slot)
        if itemId ~= nil then
            utils.stock.put(r, itemId, slot.size)
        end
    end
    return r
end


function cleanSlot(slot)
    if robot.count(slot) == 0 then return true end
    robot.select(slot)

    for nonTableSlot in iterNonTableSlots() do
        if robot.compareTo(nonTableSlot) then
            robot.transferTo(nonTableSlot)
            if robot.count() == 0 then return true end
        end
    end

    for nonTableSlot in iterNonTableSlots() do
        if robot.count(nonTableSlot) == 0 then
            robot.transferTo(nonTableSlot)
            return true
        end
    end

    return false
end


function cleanTable()
    local r = true
    for i, tableSlot in ipairs(table) do
        r = cleanSlot(tableSlot) and r
    end
    r = cleanSlot(output_slot) and r
    return r
end


function itemsToCraftingSlot(targetSlot, itemId, amount)
    for nonTableSlot in iterNonTableSlots() do
        local slot = inv.getStackInInternalSlot(nonTableSlot)
        local detectedItemId = db.detect(slot)
        if itemId == detectedItemId then
            robot.select(nonTableSlot)
            robot.transferTo(targetSlot, amount - robot.count(targetSlot))
            if robot.count(targetSlot) == amount then return true end
        end
    end
    return false
end


function M.assembleRecipe(recipe, amount)
    if not cleanTable() then return false end

    for i=1,9 do
        local itemId = recipe[i]
        if itemId ~= nil then
            if not itemsToCraftingSlot(table[i], itemId, 1) then return false end
        end
    end

    robot.select(output_slot)
    return component.crafting.craft(amount)
end


function M.assemble(itemId, amount)
    if amount == nil then amount = 1 end
    local success, clog = craftingPlanner.craft(M.getStockData(), itemId, amount)
    if not success then
        print("Not enough items")
        for k, v in pairs(clog) do
            print(k, v)
        end
        return false
    end

    for i, v in ipairs(clog) do
        for k=1,v.times do
            if not M.assembleRecipe(v.item) then return false end
        end
    end
    return true
end


return M
