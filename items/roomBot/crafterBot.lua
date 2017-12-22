local utils = require("utils")
local db = require("recipedb")


local planCrafting
do
    local function getAmountForCraft(stock, item_id, amountNeeded)
        local preDone = utils.stock.take(stock, item_id, amountNeeded)
        utils.stock.put(stock, item_id, preDone)
        return math.max(0, amountNeeded - preDone)
    end


    local function regroupCraftLog(craftLog)
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


    local function recipeSummary(recipe)
        local r = {}
        for i=1,9 do
            local v = recipe[i]
            if v ~= nil then
                utils.stock.put(r, v, 1)
            end
        end
        return r
    end


    local function craftInner(stock, item_id, amountNeeded, craftLog, needStock)
        local amountForCraft = getAmountForCraft(stock, item_id, amountNeeded)
        if amountForCraft <= 0 then
            return craftLog, needStock
        end

        local recipe = db.getRecipe(item_id)
        if recipe == nil then
            utils.stock.put(needStock, item_id, amountForCraft)
            utils.stock.put(stock, item_id, amountForCraft)
            return craftLog, needStock
        end

        local output = db.getRecipeOutput(item_id)
        local plannedRepeats = math.ceil(amountForCraft / output)

        -- gather requirements
        local recipeSum = recipeSummary(recipe)
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


    planCrafting = function(stock, item_id, amountNeeded)
        stock = utils.copyTable(stock)
        craftLog, needStock = craftInner(stock, item_id, amountNeeded, {}, {})
        if utils.isTableEmpty(needStock) then
            return true, regroupCraftLog(craftLog)
        else
            return false, needStock
        end
    end
end


local CrafterBot = utils.makeClass(function(self, crafterStorage, craftingComponent)
    self.crafterStorage = crafterStorage
    self.craftingComponent = craftingComponent
    self.crafterStorage:cleanTable()
end)


function CrafterBot:assembleRecipe(itemId, neededAmount)
    assert(neededAmount > 0)
    local output = db.getRecipeOutput(itemId)
    local maxCrafts = math.floor(db.getItemStack(itemId) / output)
    assert(maxCrafts > 0)

    self.crafterStorage:cleanTable()
    repeat
        local nCrafts = math.min(
            math.floor(neededAmount / output),
            maxCrafts
        )
        local amountToCraft = nCrafts * output
        neededAmount = neededAmount - amountToCraft

        local recipe = db.getRecipe(itemId)
        for i=1,9 do
            local itemId = recipe[i]
            if itemId ~= nil then
                self.crafterStorage:fillTableSlot(i, itemId, nCrafts)
            end
        end

        self.crafterStorage:selectOutput()

        local success, n = self.craftingComponent.craft(amountToCraft)
        assert(success, "Crafting has failed")
        assert(n > 0, "Nothing has been crafted")
        assert(n == amountToCraft, "Crafted unexpected amount")
        if neededAmount > 0 then
            self.crafterStorage:cleanTableSlot("output")
        end
    until neededAmount <= 0
end


function CrafterBot:assemble(itemId, amount, logger)
    if logger == nil then logger = print end
    if amount == nil then amount = 1 end

    local success, clog = planCrafting(self.crafterStorage:getStock(), itemId, amount)
    if not success then
        logger("Not enough items")
        for k, v in pairs(clog) do
            logger(string.format("%s: %i", db.getItemName(k), v))
        end
        return false
    end

    for i, v in ipairs(clog) do
        local q = v.times * db.getRecipeOutput(v.item)
        logger(string.format("Assembling %i of %s", q, db.getItemName(v.item)))
        self:assembleRecipe(self, v.item, q)
    end
    logger("Finished successfully.")
    return true
end


return {
    CrafterBot=CrafterBot,
    testing={
        planCrafting=planCrafting
    }
}
