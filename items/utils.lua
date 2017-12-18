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


function M.strlen(s)
    -- TODO: intended to be replaced by unicode version
    return #s
end


function M.strsub(s, from, to)
    -- TODO: intended to be replaced by unicode version
    return string.sub(s, from, to)
end


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

    local function flushedAll() return flushUntil < back end

    local iter = createIter(append, prepend)
    return function()
        if flushedAll() then
            if finish then return nil end
            finish, flushUntil = iter()
            if flushUntil == nil then flushUntil = front end
            if finish and flushedAll() then return nil end
        end
        local value = buf[back]
        buf[back] = nil
        back = back + 1
        return table.unpack(value)
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

    if isSubclass then
        classMeta.__call = function(_, ...)
            local self = {}
            setmetatable(self, meta)
            function super(...)
                _callConstructor(parentConstructor, self, ...)
                return self
            end
            _callConstructor(constructor, super, ...)
            return self
        end
    else
        classMeta.__call = function(_, ...)
            local self = {}
            setmetatable(self, meta)
            _callConstructor(constructor, self, ...)
            return self
        end
    end

    local cls = {
        __getMetaForSubclass = function()
            return meta, constructor
        end,
        registerMetaMethod = function(k, v)
            meta[k] = v
        end
    }
    setmetatable(cls, classMeta)
    return cls
end


return M
