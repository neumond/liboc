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
end)
