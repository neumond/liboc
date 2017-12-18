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
end)
