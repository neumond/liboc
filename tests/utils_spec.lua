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

        subcls = M.makeClass(cls, function(self, super, p1, p2, p3, p4)
            super(p1, p2)
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
        A.method = function(self, x) return x + 1 end
        local B = M.makeClass(A, function(self, super)
            super()
        end)
        local C = M.makeClass(B, function(self, super)
            super()
        end)

        local o = C()
        assert(o:method(3) == 4)
    end)
    it("creates default constructors", function()
        local A = M.makeClass()
        A.method = function(self, x) return x + 1 end
        local B = M.makeClass(A)
        local C = M.makeClass(B)

        for i, cls in ipairs{A, B, C} do
            local o = cls()
            assert(o:method(4) == 5)
        end
    end)
    it("supports multiple inheritance with default constructors", function()
        local A = M.makeClass()
        A.ma = function(self, x) return x + 1 end
        local B = M.makeClass()
        B.mb = function(self, x) return x + 2 end
        local C = M.makeClass()
        C.mc = function(self, x) return x + 3 end

        local D = M.makeClass(A, B, C)
        local o = D()
        assert(o:ma(1) == 2)
        assert(o:mb(1) == 3)
        assert(o:mc(1) == 4)
    end)
    it("supports multiple inheritance with custom constructors", function()
        local A = M.makeClass(function(self, a1)
            self.a1 = a1
        end)
        local B = M.makeClass(function(self, b1, b2)
            self.b1 = b1
            self.b2 = b2
        end)
        local C = M.makeClass(function(self, c1, c2, c3)
            self.c1 = c1
            self.c2 = c2
            self.c3 = c3
        end)

        local D = M.makeClass(A, B, C, function(self, superA, superB, superC, a1, b1, b2, c1, c2, c3, d1)
            superA(a1)
            superB(b1, b2)
            superC(c1, c2, c3)
            self.d1 = d1
        end)
        local o = D("a1", "b1", "b2", "c1", "c2", "c3", "d1")
        assert(o.a1 == "a1")
        assert(o.b1 == "b1")
        assert(o.b2 == "b2")
        assert(o.c1 == "c1")
        assert(o.c2 == "c2")
        assert(o.c3 == "c3")
        assert(o.d1 == "d1")
    end)
    it("can handle nil constructor parameters", function()
        local A = M.makeClass(function(self, a, b, c, d)
            self.a = a
            self.b = b
            self.c = c
            self.d = d
        end)
        local o = A(1, nil, nil, 4)
        assert(o.a == 1)
        assert(o.b == nil)
        assert(o.c == nil)
        assert(o.d == 4)
    end)
    it("can call superclass methods in simple inheritance", function()
        local A = M.makeClass()
        A.method = function(self, a, b)
            return a + b
        end
        local B = M.makeClass(A)
        B.method = function(self, c)
            return B.__super.method(self, 4, 3) + c
        end
        local o = B()
        assert(o:method(2) == 9)
    end)
    it("can call superclass methods in multiple inheritance", function()
        local A = M.makeClass()
        A.method = function(self, a)
            return a .. "a"
        end
        local B = M.makeClass()
        B.method = function(self, a)
            return a .. "b"
        end

        local C = M.makeClass(A, B)
        C.method = function(self, a)
            a = C.__super[1].method(self, a)
            a = C.__super[2].method(self, a)
            return a
        end

        local o = C()
        assert(o:method("x") == "xab")
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
