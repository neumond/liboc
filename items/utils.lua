local M = {}


function M.isInGame()
    return _OSVERSION ~= nil
end


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


if M.isInGame() then
    M.string = require("unicode")
else
    M.string = require("lua-utf8")
end


-- compatibility
-- TODO: remove
M.strlen = M.string.len
M.strsub = M.string.sub


function M.bufferingIterator(createIter)
    local buf = {}
    local front = 0
    local back = 1
    local flushUntil = front
    local finish = false

    local function append(...)
        front = front + 1
        buf[front] = {...}
        return front
    end

    local function prepend(...)
        back = back - 1
        buf[back] = {...}
        return back
    end

    local function flushedAll() return back > flushUntil end

    local iter = createIter(append, prepend)
    return function()
        while not (finish and flushedAll()) do
            if flushedAll() then
                finish, flushUntil = iter()
                if flushUntil == nil then flushUntil = front end
            else
                local value = buf[back]
                buf[back] = nil
                back = back + 1
                return table.unpack(value)
            end
        end
    end
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


function _callConstructor(constructor, ...)
    assert(constructor(...) == nil, "Don't return anything in constructor")
end


function M.makeClass(a, b)
    -- cls = makeClass(function(self, params...)
    --     modifying self...
    -- end)
    -- cls.attr = xxx
    --
    -- subcls = makeClass(cls, function(super, params...)
    --     local self = super(params for parent constructor...)
    --     modifying self further...
    -- end)
    -- subcls.attr = yyy
    --
    -- obj = cls(params...)
    -- sobj = subcls(params...)

    local prototype = {}
    local isSubclass = b ~= nil
    local constructor = isSubclass and b or a
    local parentMeta, parentConstructor

    if isSubclass then
        parentMeta, parentConstructor = a.__getMetaForSubclass()
        setmetatable(prototype, parentMeta)
    end

    local meta = {__index = prototype}
    local classMeta = {
        __index = prototype,
        __newindex = prototype
    }

    local preparedConstructor = constructor
    if isSubclass then
        preparedConstructor = function(self, ...)
            constructor(function(...)
                _callConstructor(parentConstructor, self, ...)
                return self
            end, ...)
        end
    end

    classMeta.__call = function(_, ...)
        local self = {}
        setmetatable(self, meta)
        _callConstructor(preparedConstructor, self, ...)
        return self
    end

    local cls = {
        __getMetaForSubclass = function()
            return meta, preparedConstructor
        end,
        registerMetaMethod = function(k, v)
            meta[k] = v
        end
    }
    if isSubclass then
        cls.__super = a  -- TODO: improve this
    end
    setmetatable(cls, classMeta)
    return cls
end


return M
