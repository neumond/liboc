require("busted.runner")()
local mod = require("roomBot.planeNav")


local function createRobot()
    local x = 0
    local z = 0
    local r = 0

    local rmap = {
        [0] = "Z+",
        [1] = "X+",
        [2] = "Z-",
        [3] = "X-"
    }
    local svals = {
        ["+"] = 1,
        ["-"] = -1
    }
    local sfunc = {
        ["X"] = function(shift) x = x + shift end,
        ["Z"] = function(shift) z = z + shift end
    }
    local function rotate(shift)
        r = (r + shift) % 4
    end
    local function move(m)
        local rot = rmap[r]
        sfunc[string.sub(rot, 1, 1)](
            m * svals[string.sub(rot, 2, 2)]
        )
    end

    return {
        get=function()
            return {x, z}
        end,
        forward=function()
            move(1)
            return true
        end,
        back=function()
            move(-1)
            return true
        end,
        turnRight=function() rotate(1) end,
        turnLeft=function() rotate(3) end,
        turnAround=function() rotate(2) end
    }
end



describe("PlaneNav", function()
    it("works", function()
        local robot = createRobot()
        local nav = mod.PlaneNav(robot)

        nav:gotoPosition(10, 10)
        assert.are_same({10, 10}, robot.get())

        nav:gotoPosition(20, -8)
        assert.are_same({20, -8}, robot.get())

        nav:gotoPosition(-4, 0)
        assert.are_same({-4, 0}, robot.get())

        nav:rotate("Z+")

        nav:gotoPosition(2, 2)
        assert.are_same({2, 2}, robot.get())
    end)
end)
