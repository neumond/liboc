local M = {}
local db = require("recipedb")


function copyTable(t)
    local r = {}
    for k, v in pairs(t) do
        r[k] = v
    end
    return r
end


function isTableEmpty(t)
    return next(t) == nil
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
    if amountForCraft <= 0 then return true end

    local recipe = db.items[item_id].recipe
    if recipe == nil then
        putIntoStock(needStock, item_id, amountForCraft)
        putIntoStock(stock, item_id, amountForCraft)
        return craftLog, needStock
    end

    local output = getRecipeOutput(item_id)
    local plannedRepeats = math.ceil(amountForCraft / output)

    -- gather requirements
    local recipeSum = recipeSummary(recipe)
    local takenForCraft = {}
    for reqId, recipeAmount in pairs(recipeSum) do
        local reqAmount = recipeAmount * plannedRepeats
        craftInner(stock, reqId, reqAmount, craftLog, needStock)
        local reqTaken = takeFromStock(stock, reqId, reqAmount)
        takenForCraft[reqId] = reqTaken
    end

    table.insert(craftLog, {item=item_id, times=plannedRepeats})

    -- remove used crafting supplies
    for reqId, recipeAmount in pairs(recipeSum) do
        takeFromStock(takenForCraft, reqId, recipeAmount * plannedRepeats)
    end

    -- put craft product into main stock
    putIntoStock(stock, item_id, output * plannedRepeats)

    -- put back unused
    for reqId, reqAmount in pairs(takenForCraft) do
        putIntoStock(stock, reqId, reqAmount)
    end

    return craftLog, needStock
end


function M.craft(stock, item_id, amountNeeded)
    stock = copyTable(stock)
    craftLog, needStock = craftInner(stock, item_id, amountNeeded, {}, {})
    if isTableEmpty(needStock) then
        return true, regroupCraftLog(craftLog)
    else
        return false, needStock
    end
end


return M
