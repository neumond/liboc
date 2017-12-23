require("busted.runner")()
local mod = require("lib.linkedList")


describe("LinkedList", function()
    function assertList(l, ref)
        local t = {}
        for item in l:iter() do
            table.insert(t, item:getPayload())
        end
        assert.are_same(t, ref)
    end

    it("can append things", function()
        local l = mod.LinkedList()
        l:append("a")
        l:append("b")
        l:append("c")

        assert.is_equal(#l, 3)
        assertList(l, {"a", "b", "c"})
    end)
    it("can prepend things", function()
        local l = mod.LinkedList()
        l:prepend("a")
        l:prepend("b")
        l:prepend("c")

        assert.is_equal(#l, 3)
        assertList(l, {"c", "b", "a"})
    end)
    it("can append and prepend things", function()
        local l = mod.LinkedList()
        l:append("a")
        l:prepend("A")
        l:append("b")
        l:prepend("B")
        l:append("c")
        l:prepend("C")

        assert.is_equal(#l, 6)
        assertList(l, {"C", "B", "A", "a", "b", "c"})
    end)
    it("can remove things", function()
        local l = mod.LinkedList()
        local a = l:append("a")
        l:append("b")
        local c = l:append("c")
        l:append("d")
        local e = l:append("e")

        a:remove()
        c:remove()
        e:remove()
        assert.is_equal(#l, 2)
        assertList(l, {"b", "d"})
    end)
    it("can delete last item", function()
        local l = mod.LinkedList()
        local a = l:prepend("a")
        a:remove()
        assert.is_equal(#l, 0)
        assertList(l, {})

        local l2 = mod.LinkedList()
        local A = l:append("A")
        local B = l:append("B")
        local C = l:append("C")
        B:remove()
        A:remove()
        C:remove()
        assert.is_equal(#l, 0)
        assertList(l, {})
    end)
end)