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


function M.bufferingIterator(createIter)
    local buf = {}
    local front = 1
    local back = 1
    local finish = false

    function append(...)
        buf[front] = {...}
        front = front + 1
    end

    function prepend(...)
        back = back - 1
        buf[back] = {...}
    end

    local iter = createIter(append, prepend)
    return function()
        if front == back then
            if finish then return nil end
            finish = finish or iter()
        end
        local value = buf[back]
        buf[back] = nil
        back = back + 1
        return unpack(value)
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


function testSimpleClass()
    local cls = M.makeClass(function(self)
        self.x = 4
    end)
    cls.y = 5  -- changes hidden prototype table
    assert(rawget(cls, "y") == nil)

    local o = cls()
    assert(o.x == 4)
    assert(o.y == 5)

    o.x = 20
    o.y = 21
    assert(rawget(o, "x") == 20)  -- instances change directly

    local k = cls()
    assert(k.x == 4)
    assert(k.y == 5)

    assert(o.x == 20)
    assert(o.y == 21)
end


function testSubclass()
    local cls = M.makeClass(function(self, p1, p2)
        self.p1 = p1
        self.p2 = p2
    end)
    cls.x = 5

    subcls = M.makeClass(cls, function(super, p1, p2, p3, p4)
        local self = super(p1, p2)
        self.p3 = p3
        self.p4 = p4
    end)
    subcls.y = 6

    local a = subcls(10, 20, 30, 40)
    assert(a.x == 5)
    assert(a.y == 6)
    assert(a.p1 == 10)
    assert(a.p2 == 20)
    assert(a.p3 == 30)
    assert(a.p4 == 40)
end


testSimpleClass()
testSubclass()


return M
