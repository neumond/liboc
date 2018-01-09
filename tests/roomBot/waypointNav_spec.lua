require("busted.runner")()
local mod = require("roomBot.waypointNav")


describe("WaypointNav", function()
    it("encode", function()
        assert.is_equal("F", mod.encode{"forward"})
        assert.is_equal("F2", mod.encode{"forward", "forward"})
        assert.is_equal("FUF", mod.encode{"forward", "up", "forward"})
    end)
    it("encode optimizations", function()
        assert.is_equal("", mod.encode{"forward", "back"})
        assert.is_equal("", mod.encode{"up", "down"})
        assert.is_equal("", mod.encode{"turnLeft", "turnRight"})
        assert.is_equal("A", mod.encode{"turnLeft", "turnLeft"})
        assert.is_equal("R", mod.encode{"turnLeft", "turnLeft", "turnLeft"})
        assert.is_equal("", mod.encode{"turnLeft", "turnLeft", "turnLeft", "turnLeft"})
    end)
    it("execEncoded", function()
        local robotLog = {}
        local fakeRobot = {}
        setmetatable(fakeRobot, {
            __index=function(t, k)
                table.insert(robotLog, k)
                return function() return true end
            end
        })

        mod.execEncoded(fakeRobot, "F2ULB3")
        assert.are_same({
            "forward", "forward",
            "up", "turnLeft",
            "back", "back", "back"
        }, robotLog)
    end)
    it("reverseEncoded", function()
        assert.is_equal("B", mod.reverseEncoded("F"))
        assert.is_equal("B3RB5", mod.reverseEncoded("F5LF3"))
        assert.is_equal("A", mod.reverseEncoded("A"))
    end)
    it("pathLength", function()
        assert.is_equal(1, mod.pathLength("F"))
        assert.is_equal(5, mod.pathLength("F5"))
        assert.is_equal(2, mod.pathLength("A"))
        assert.is_equal(13, mod.pathLength("F5U4LF3"))
    end)
end)
