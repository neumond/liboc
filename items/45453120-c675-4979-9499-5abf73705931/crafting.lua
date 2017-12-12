local M = {}
local db = require("recipedb")


function copyTable(t)
    local r = {}
    for k, v in pairs(t) do
        r[k] = v
    end
    return r
end


function takeFromStock(stock, item_id, amount)
    if stock[item_id] == nil then return 0 end
    local taken = math.min(stock[item_id], amount)
    stock[item_id] = stock[item_id] - taken
    if stock[item_id] <= 0 then
        stock[item_id] = nil
    end
    return taken
end


function putIntoStock(stock, item_id, amount)
    if amount <= 0 then return end
    local exist = stock[item_id]
    if exist == nil then
        exist = 0
    end
    stock[item_id] = exist + amount
end


function recipeSummary(recipe)
    local r = {}
    for i=1,9 do
        local v = recipe[i]
        if v ~= nil then
            putIntoStock(r, v, 1)
        end
    end
    return r
end


function getAmountForCraft(stock, item_id, amountNeeded)
    local preDone = takeFromStock(stock, item_id, amountNeeded)
    putIntoStock(stock, item_id, preDone)
    return math.max(0, amountNeeded - preDone)
end


function getRecipeOutput(item_id)
    local output = db.items[item_id].output
    if output == nil then output = 1 end
    return output
end


function M.craft(stock, item_id, amountNeeded, craftLog, needStock)
    if craftLog == nil then craftLog = {} end
    if needStock == nil then needStock = {} end

    local amountForCraft = getAmountForCraft(stock, item_id, amountNeeded)
    if amountForCraft <= 0 then return true end

    local recipe = db.items[item_id].recipe
    if recipe == nil then
        -- print("Need", amountForCraft, "of", item_id)
        putIntoStock(needStock, item_id, amountForCraft)
        return false
    end

    local output = getRecipeOutput(item_id)
    local plannedRepeats = math.ceil(amountForCraft / output)

    -- gather requirements
    local recipeSum = recipeSummary(recipe)
    local successfulRepeats = plannedRepeats
    local takenForCraft = {}
    for reqId, recipeAmount in pairs(recipeSum) do
        local reqAmount = recipeAmount * plannedRepeats
        M.craft(stock, reqId, reqAmount, craftLog, needStock)
        local reqTaken = takeFromStock(stock, reqId, reqAmount)
        successfulRepeats = math.min(successfulRepeats, math.floor(reqTaken / recipeAmount))
        takenForCraft[reqId] = reqTaken
    end

    -- print("Crafting", item_id, successfulRepeats, "times")
    if successfulRepeats > 0 then
        table.insert(craftLog, item_id)
        table.insert(craftLog, successfulRepeats)
    end

    -- remove used crafting supplies
    for reqId, recipeAmount in pairs(recipeSum) do
        takeFromStock(takenForCraft, reqId, recipeAmount * successfulRepeats)
    end

    -- put craft product into main stock
    putIntoStock(stock, item_id, output * successfulRepeats)

    -- put back unused
    for reqId, reqAmount in pairs(takenForCraft) do
        putIntoStock(stock, reqId, reqAmount)
    end

    return successfulRepeats == plannedRepeats, craftLog, needStock
end


return M
