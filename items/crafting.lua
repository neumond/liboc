local M = {}
local db = require("recipedb")
local utils = require("utils")


function getAmountForCraft(stock, item_id, amountNeeded)
    local preDone = utils.stock.take(stock, item_id, amountNeeded)
    utils.stock.put(stock, item_id, preDone)
    return math.max(0, amountNeeded - preDone)
end


function regroupCraftLog(craftLog)
    local result = {}
    local index = {}
    local tip = 1
    for i, step in ipairs(craftLog) do
        if index[step.item] == nil then
            index[step.item] = tip
            tip = tip + 1
            table.insert(result, step)
        else
            local k = index[step.item]
            result[k].times = result[k].times + step.times
        end
    end
    return result
end


function craftInner(stock, item_id, amountNeeded, craftLog, needStock)
    local amountForCraft = getAmountForCraft(stock, item_id, amountNeeded)
    if amountForCraft <= 0 then
        return craftLog, needStock
    end

    local recipe = db.items[item_id].recipe
    if recipe == nil then
        utils.stock.put(needStock, item_id, amountForCraft)
        utils.stock.put(stock, item_id, amountForCraft)
        return craftLog, needStock
    end

    local output = db.recipeOutput(item_id)
    local plannedRepeats = math.ceil(amountForCraft / output)

    -- gather requirements
    local recipeSum = db.recipeSummary(recipe)
    local takenForCraft = {}
    for reqId, recipeAmount in pairs(recipeSum) do
        local reqAmount = recipeAmount * plannedRepeats
        craftInner(stock, reqId, reqAmount, craftLog, needStock)
        local reqTaken = utils.stock.take(stock, reqId, reqAmount)
        takenForCraft[reqId] = reqTaken
    end

    table.insert(craftLog, {item=item_id, times=plannedRepeats})

    -- remove used crafting supplies
    for reqId, recipeAmount in pairs(recipeSum) do
        utils.stock.take(takenForCraft, reqId, recipeAmount * plannedRepeats)
    end

    -- put craft product into main stock
    utils.stock.put(stock, item_id, output * plannedRepeats)

    -- put back unused
    for reqId, reqAmount in pairs(takenForCraft) do
        utils.stock.put(stock, reqId, reqAmount)
    end

    return craftLog, needStock
end


function M.craft(stock, item_id, amountNeeded)
    stock = utils.copyTable(stock)
    craftLog, needStock = craftInner(stock, item_id, amountNeeded, {}, {})
    if utils.isTableEmpty(needStock) then
        return true, regroupCraftLog(craftLog)
    else
        return false, needStock
    end
end


M.planCrafting = M.craft


return M
