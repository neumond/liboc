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

end


function _defaultConstructor(self, ...)
    for i, super in ipairs{...} do
        super()
    end
end


function M.makeClass(...)
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

    local constructor
    local parentClasses = {}
    local parentProtos = {}
    local parentCons = {}
    for _, v in ipairs{...} do
        if type(v) == "function" then
            assert(constructor == nil, "Class can't have multiple constructors")
            constructor = v
        else
            table.insert(parentClasses, v)
            local proto, cons = v.getMetaForSubclass()
            table.insert(parentProtos, proto)
            table.insert(parentCons, cons)
        end
    end
    if constructor == nil then constructor = _defaultConstructor end

    local prototype = {}

    if #parentClasses == 1 then
        setmetatable(prototype, {__index = parentProtos[1]})
    elseif #parentClasses > 1 then
        setmetatable(prototype, {__index = function(t, k)
            local i = 1
            local value
            repeat
                local p = parentProtos[i]
                if p == nil then break end
                value = p[k]
                i = i + 1
            until value ~= nil
            return value
        end})
    end

    local meta = {__index = prototype}
    local function preparedConstructor(self, ...)
        local ags = {}
        local i = 0
        for _, pcons in ipairs(parentCons) do
            i = i + 1
            ags[i] = function(...) pcons(self, ...) end
        end
        -- hacky, but works
        local pa = {...}
        for k=1,#pa do  -- warm-up the sequence to set the length
            ags[i + k] = false
        end
        for k=1,#pa do  -- write actual values including nils
            ags[i + k] = pa[k]
        end
        assert(
            constructor(self, table.unpack(ags)) == nil,
            "Don't return anything from constructor")
    end
    local cls = {
        getMetaForSubclass = function()
            return prototype, preparedConstructor
        end,
        registerMetaMethod = function(k, v)
            meta[k] = v
        end
    }

    -- TODO: improve this
    if #parentClasses == 1 then
        cls.__super = parentClasses[1]
    elseif #parentClasses > 1 then
        cls.__super = parentClasses
    end

    setmetatable(cls, {
        __index = prototype,
        __newindex = prototype,
        __call = function(_, ...)
            local self = {}
            setmetatable(self, meta)
            preparedConstructor(self, ...)
            return self
        end
    })
    return cls
end


return M
