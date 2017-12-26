require("busted.runner")()
local M = require("utils")


describe("class framework", function()
    it("works in simple class usage pattern", function()
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
    end)
    it("works with subclassing", function()
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
    end)
    it("doesn't fail with subsubclassing", function()
        local A = M.makeClass(function(self)
        end)
        local B = M.makeClass(A, function(super)
            local self = super()
        end)
        local C = M.makeClass(B, function(super)
            local self = super()
        end)

        local o = C()
    end)
end)

describe("bufferingIterator", function()
    local b = M.bufferingIterator

    local function accumulate(iter)
        local result = {}
        for a in iter do
            table.insert(result, a)
        end
        return result
    end

    it("works in simple flow", function()
        local t = accumulate(b(function(append, prepend)
            return function()
                append(1)
                append(2)
                append(3)
                return true, nil
            end
        end))
        assert.are_same(t, {
            1, 2, 3
        })
    end)
    it("works with prepend", function()
        local t = accumulate(b(function(append, prepend)
            return function()
                append(4)
                append(5)
                append(6)
                prepend(3)
                prepend(2)
                prepend(1)
                return true, nil
            end
        end))
        assert.are_same(t, {
            1, 2, 3, 4, 5, 6
        })
    end)
    it("works in several iterations", function()
        local t = accumulate(b(function(append, prepend)
            local i = 0
            return function()
                i = i + 1
                if i > 3 then return true, nil end
                append(i)
                prepend(i + 10)
                prepend(i + 20)
                append(i + 100)
                return false, nil
            end
        end))
        assert.are_same(t, {
            21, 11, 1, 101,
            22, 12, 2, 102,
            23, 13, 3, 103
        })
    end)
    it("handles lack of append calls", function()
        local t = accumulate(b(function(append, prepend)
            local i = 0
            return function()
                i = i + 1
                if i > 3 then return true, nil end
                if i ~= 2 then
                    append(i)
                end
                return false, nil
            end
        end))
        assert.are_same(t, {
            1, 3
        })
    end)
end)
