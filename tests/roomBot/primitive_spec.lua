require("busted.runner")()
local mod = require("roomBot.primitive")
local tMod = require("lib.testing")


describe("primitive", function()
    it("enumGrid", function()
        local function dotest(expected, ...)
            assert.are_same(expected, tMod.accumulate(mod.enumGrid(...)))
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
    it("enumPerimeter", function()
        local function dotest(expected, ...)
            assert.are_same(expected, tMod.accumulate(mod.enumPerimeter(...)))
        end

        dotest({
            {0, 0}
        }, 1, 1)

        dotest({
            {0, 0},
            {1, 0}
        }, 2, 1)

        dotest({
            {0, 0},
            {0, 1}
        }, 1, 2)

        dotest({
            {0, 0},
            {1, 0},
            {1, 1},
            {0, 1}
        }, 2, 2)

        dotest({
            {0, 0},
            {1, 0},
            {2, 0},
            {2, 1},
            {2, 2},
            {1, 2},
            {0, 2},
            {0, 1}
        }, 3, 3)
    end)
end)
