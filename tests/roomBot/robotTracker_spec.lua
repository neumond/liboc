require("busted.runner")()
local mod = require("roomBot.robotTracker")


describe("robotTracker", function()
    local fakeRobot = mod.testing.createFakeRobot()
    local function check(t, x, y, z, rot)
        assert.are_same({x, y, z}, {t.getPosition()})
        assert.is_equal(rot, t.getRotation())
    end

    it("up down", function()
        local t = mod.createTracker(fakeRobot)
        check(t, 0, 0, 0, "Y+")
        t.up()
        check(t, 0, 0, 1, "Y+")
        t.down()
        check(t, 0, 0, 0, "Y+")
        t.down()
        check(t, 0, 0, -1, "Y+")
    end)
    it("forward back", function()
        local t = mod.createTracker(fakeRobot)
        check(t, 0, 0, 0, "Y+")
        t.forward()
        check(t, 0, 1, 0, "Y+")
        t.back()
        check(t, 0, 0, 0, "Y+")
        t.back()
        check(t, 0, -1, 0, "Y+")
    end)
    it("turnLeft and move", function()
        local t = mod.createTracker(fakeRobot)
        check(t, 0, 0, 0, "Y+")
        t.turnLeft()
        t.forward()
        check(t, -1, 0, 0, "X-")
        t.turnLeft()
        t.forward()
        check(t, -1, -1, 0, "Y-")
        t.turnLeft()
        t.forward()
        check(t, 0, -1, 0, "X+")
        t.turnLeft()
        t.forward()
        check(t, 0, 0, 0, "Y+")
    end)
end)


describe("OpenNav", function()
    describe("rotation", function()
        it("planRotation", function()
            local f = mod.testing.planRotation

            --   Y+
            -- X-  X+
            --   Y-

            assert.is_equal("turnRight", f("Y+", "X+"))
            assert.is_equal("turnRight", f("X+", "Y-"))
            assert.is_equal("turnRight", f("Y-", "X-"))
            assert.is_equal("turnRight", f("X-", "Y+"))

            assert.is_equal("turnLeft", f("Y+", "X-"))
            assert.is_equal("turnLeft", f("X-", "Y-"))
            assert.is_equal("turnLeft", f("Y-", "X+"))
            assert.is_equal("turnLeft", f("X+", "Y+"))

            assert.is_equal("turnAround", f("Y+", "Y-"))
            assert.is_equal("turnAround", f("Y-", "Y+"))
            assert.is_equal("turnAround", f("X+", "X-"))
            assert.is_equal("turnAround", f("X-", "X+"))

            assert.is_nil(f("Y+", "Y+"))
            assert.is_nil(f("Y-", "Y-"))
            assert.is_nil(f("X+", "X+"))
            assert.is_nil(f("X-", "X-"))
        end)
    end)

    describe("movement", function()
        it("works", function()
            local robot = mod.createTracker(mod.testing.createFakeRobot())
            local nav = mod.OpenNav(robot)

            nav:gotoPosition(10, 10)
            assert.are_same({10, 10, 0}, {robot.getPosition()})

            nav:gotoPosition(20, -8)
            assert.are_same({20, -8, 0}, {robot.getPosition()})

            nav:gotoPosition(-4, 0)
            assert.are_same({-4, 0, 0}, {robot.getPosition()})

            nav:rotate("Y+")

            nav:gotoPosition(2, 2)
            assert.are_same({2, 2, 0}, {robot.getPosition()})
        end)
    end)
end)
