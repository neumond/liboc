require("busted.runner")()
local mod = require("lib.stack")


describe("Stack", function()
    it("works", function()
        local s = mod.Stack()

        assert.is_nil(s:tip())

        s:push("a")
        assert.is_equal(s:tip(), "a")
        assert.is_nil(s:tip(2))

        s:push("b")
        assert.is_equal(s:tip(), "b")
        assert.is_equal(s:tip(2), "a")

        assert.is_equal(s:pop(), "b")
        assert.is_equal(s:tip(), "a")

        assert.is_equal(s:pop(), "a")
        assert.is_nil(s:tip())
    end)
end)
