require("busted.runner")()
local mod = require("roomBot.jackBot")


describe("Lumberjack", function()
    it("walks grids properly", function()
        local function dotest(expected, ...)
            local path = {}
            for x, z in mod.testing.enumGrid(...) do
                table.insert(path, {x, z})
            end
            assert.are_same(expected, path)
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
end)
