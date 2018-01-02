local makeClass = require("utils").makeClass
local PlaneNav = require("roomBot.planeNav").PlaneNav


local SAPLING_SLOT = 1
local LEAFS_SLOT = 2
local TREE_SLICES = 2  -- TREE_SLICES * 3 + 1 rows
local TREE_RINGS = 2  -- excluding center block


local function enumGrid(width, height, step)
    local x = 0
    local y = 1
    return function()
        x = x + 1
        if x > width then
            x = 1
            y = y + 1
        end
        if y > height then return end
        if y % 2 == 1 then
            return (x - 1) * step, (y - 1) * step
        else
            return (width - x) * step, (y - 1) * step
        end
    end
end


local JackBot = makeClass(function(self, robot, config)
    self.robot = robot
    self.config = config
end)


function JackBot:preCheck()
    assert(self.robot.inventorySize() >= 8, "Required: inventory upgrade")
    local totalSaplings = self.config.width * self.config.height
    assert(
        self.robot.count(SAPLING_SLOT) >= totalSaplings,
        "Required: " .. totalSaplings .. " saplings in slot " .. SAPLING_SLOT)
    assert(
        self.robot.count(LEAFS_SLOT) >= 1,
        "Required: Leafs block in slot " .. LEAFS_SLOT)
end


function JackBot:isLeaf()
    self.robot.select(LEAFS_SLOT)
    self.robot.compare()

    r, btype = self.robot.detect()
    if not r then return false end
    return btype == "passable"
end


function JackBot:chopmove()
    if self.robot.detect() then self.robot.swing() end
    assert(self.robot.forward())
end


local function chopTree()
    chopmove()

    for z=1,tree_height do
        if robot.detectUp() then robot.swingUp() end
        robot.up()

        for ring=1,radius do
            chopmove()  -- entering ring
            robot.turnLeft()
            for r=1,ring do chopmove() end
            for rside=1,3 do
                robot.turnLeft()
                for r=1,ring*2 do chopmove() end
            end
            robot.turnLeft()
            for r=1,ring do chopmove() end
            robot.turnRight()
        end

        for ring=1,radius do robot.back() end
    end

    for z=1,tree_height do robot.down() end
    robot.back()
end


function JackBot:isSapling()
    r, btype = self.robot.detect()
    if not r then return false end
    return btype == "passable"
end


function JackBot:placeSapling()
    self.robot.select(SAPLING_SLOT)
    self.robot.place()
end


function JackBot:handleTree()
    if not self:isSapling() then
        self:chopTree()
        self:placeSapling()
    end
end


function JackBot:farmSession()
    assert(self.robot.forward())
    local nav = PlaneNav(self.robot)
    for x, z in enumGrid(self.config.width, self.config.height, self.config.step) do
        nav:gotoPosition(x, z)
        nav:rotate("X+")
        assert(self.robot.forward())
        self.robot.turnLeft()
        self:handleTree()
        self.robot.turnRight()
        assert(self.robot.back())
    end
    nav:gotoPosition(0, 0)
    nav:rotate("Z+")
    assert(self.robot.back())
end


function JackBot:unload()
    self.robot.turnRight()
    for slot=3,16 do
        if self.robot.count(slot) >= 1 then
            self.robot.select(slot)
            self.robot.drop()
        end
    end
    self.robot.turnLeft()
end


function JackBot:fullSession()
    self:preCheck()
    self:waitCharging()
    self:farmSession()
    self:unload()
end


function JackBot:main()
    while true do
        self:fullSession()
    end
end


return {
    JackBot=JackBot,
    testing={
        enumGrid=enumGrid
    }
}
