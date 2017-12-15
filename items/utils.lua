local M = {}


function M.copyTable(t)
    local r = {}
    for k, v in pairs(t) do
        r[k] = v
    end
    return r
end


function M.isTableEmpty(t)
    return next(t) == nil
end


function M.findInArray(a, val)
    for i, v in ipairs(a) do
        if v == val then return i end
    end
end


function M.removeFromArray(a, val)
    return table.remove(a, M.findInArray(a, val))
end


M.stock = {}


function M.stock.take(stock, item_id, amount)
    if stock[item_id] == nil then return 0 end
    local taken = math.min(stock[item_id], amount)
    stock[item_id] = stock[item_id] - taken
    if stock[item_id] <= 0 then
        stock[item_id] = nil
    end
    return taken
end


function M.stock.put(stock, item_id, amount)
    if amount <= 0 then return end
    local exist = stock[item_id]
    if exist == nil then
        exist = 0
    end
    stock[item_id] = exist + amount
end


function makeClass(constructor, classData)
    -- local class = makeClass(function(self)
    --     ...
    -- end)

    if classData == nil then classData = {} end
    classData.__index = classData

    classData.new = function(...)
        local self = setmetatable({}, classData)
        constructor(self, ...)
        return self
    end

    return classData
end


return M
