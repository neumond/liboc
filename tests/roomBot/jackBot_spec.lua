require("busted.runner")()
local mod = require("roomBot.jackBot")
local tMod = require("lib.testing")


describe("Lumberjack", function()
    it("walks grids properly", function()
        local function dotest(expected, ...)
            assert.are_same(expected, tMod.accumulate(mod.testing.enumGrid(...)))
        end

        dotest({
            {0, 0},
            {5, 0},
            {10, 0},
            {10, 5},
            {5, 5},
            {0, 5},
            {0, 10},
            {5, 10},
            {10, 10}
        }, 3, 3, 5)
    end)
    it("ringPerimeter", function()
        assert.are_equal(1 * 1, mod.testing.ringPerimeter(0))
        assert.are_equal(3 * 3 - 1 * 1, mod.testing.ringPerimeter(1))
        assert.are_equal(5 * 5 - 3 * 3, mod.testing.ringPerimeter(2))
    end)
    it("enumRingPositions", function()
        local function dotest(expected, ...)
            assert.are_same(expected, tMod.accumulate(mod.testing.enumRingPositions(...)))
        end

        dotest({
            {-1, -1, "X+"},
            {0, -1, "X+"},
            {1, -1, "Z+"},
            {1, 0, "Z+"},
            {1, 1, "X-"},
            {0, 1, "X-"},
            {-1, 1, "Z-"},
            {-1, 0, "Z-"}
        }, 1)
    end)
    it("enumInwardRingPositions", function()
        local function dotest(expected, ...)
            assert.are_same(expected, tMod.accumulate(mod.testing.enumInwardRingPositions(...)))
        end

        dotest({
            {-1, -1, "X+"},
            {0, -1, "X+"},
            {1, -1, "Z+"},
            {1, 0, "Z+"},
            {1, 1, "X-"},
            {0, 1, "X-"},
            {-1, 1, "Z-"},
            {-1, 0, "X+"}  -- the difference is here
        }, 1)
    end)
    it("enumInitialIntrusion", function()
        local function dotest(expected, ...)
            assert.are_same(expected, tMod.accumulate(mod.testing.enumInitialIntrusion(...)))
        end

        dotest({
            -- {0, 0, "Z-"},  skip first position, we start at 0, -1
            {0, -1, "X-"},
            {-1, -1, "X+"}
        }, 1)
        dotest({
            -- {0, 0, "Z-"},  skip first position, we start at 0, -1
            {0, -1, "Z-"},
            {0, -2, "X-"},
            {-1, -2, "X-"},
            {-2, -2, "X+"}
        }, 2)
    end)

end)
