require("busted.runner")()
local mod = require("roomBot.rotationNav")


describe("RotationNav", function()
    it("planRotation", function()
        local f = mod.testing.planRotation

        --   Z+
        -- X-  X+
        --   Z-

        assert.is_equal("right", f("Z+", "X+"))
        assert.is_equal("right", f("X+", "Z-"))
        assert.is_equal("right", f("Z-", "X-"))
        assert.is_equal("right", f("X-", "Z+"))

        assert.is_equal("left", f("Z+", "X-"))
        assert.is_equal("left", f("X-", "Z-"))
        assert.is_equal("left", f("Z-", "X+"))
        assert.is_equal("left", f("X+", "Z+"))

        assert.is_equal("around", f("Z+", "Z-"))
        assert.is_equal("around", f("Z-", "Z+"))
        assert.is_equal("around", f("X+", "X-"))
        assert.is_equal("around", f("X-", "X+"))

        assert.is_nil(f("Z+", "Z+"))
        assert.is_nil(f("Z-", "Z-"))
        assert.is_nil(f("X+", "X+"))
        assert.is_nil(f("X-", "X-"))
    end)
end)
