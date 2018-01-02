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
    M.strWidth = M.string.wlen
    M.charWidth = M.string.charWidth
else
    M.string = require("lua-utf8")
    M.strWidth = M.string.width
    M.charWidth = function(ch) return M.string.width(M.string.sub(ch, 1, 1)) end
end
M.strlen = M.string.len
M.strsub = M.string.sub


function M.iterChars(text)
    local i = 0
    local len = M.strlen(text)
    return function()
        i = i + 1
        if i > len then return end
        local char = M.strsub(text, i, i)
        return char, M.charWidth(char)
    end
end


if M.isInGame() then
    M.sides = require("sides")
else
    M.sides = {
        bottom = 0,
        top = 1,
        back = 2,
        front = 3,
        right = 4,
        left = 5
    }
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


local function defaultNoParentConstructor(self)
end


local function defaultSingleParentConstructor(self, super, ...)
    super(...)
end


local function defaultMultiParentConstructor(nParents)
    return function(self, ...)
        for i, super in ipairs{...} do
            if i > nParents then break end
            super()
        end
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
    if constructor == nil then
        if #parentClasses == 0 then
            constructor = defaultNoParentConstructor
        elseif #parentClasses == 1 then
            constructor = defaultSingleParentConstructor
        else
            constructor = defaultMultiParentConstructor(#parentClasses)
        end
    end

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
