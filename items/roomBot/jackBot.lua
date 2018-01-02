local makeClass = require("utils").makeClass
local PlaneNav = require("roomBot.planeNav").PlaneNav


-- TODO: debug axes
-- TODO: ability to find and use axes in chest
-- TODO: ability to take saplings from chest
-- TODO: sleep if no wood acquired


local SAPLING_SLOT = 1

-- for .compare()
-- keep in mind, it is not possible to detect _naturally spawned_ leafs
-- .compare() for leaf block almost always returns false (except for damage=0 variant)
-- Same thing happens with wood logs, but .compare() with wood
-- yields positive results more often and applies axe as intended.
-- Some wood (branches) would be gathered by unequipped hand, but there's no way to do it better
local WOOD_SLOT = 2

local TREE_SLICES = 2  -- TREE_SLICES * 3 + 1 rows, without hover upgrade maximum 8 blocks above
local TREE_RINGS = 2  -- excluding center block
local NO_AXE = "no_axe"
local COLORS = {
    CHARGE = 0x00FF00,
    WALK = 0x0080FF,
    CHOP = 0xFF8000
}


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


local function ringSide(ring)
    -- 1, 3, 5
    if ring < 0 then return 0 end
    return ring * 2 + 1
end


local function ringPerimeter(ring)
    local currentSide = ringSide(ring)
    local innerSide = ringSide(ring - 1)
    return currentSide * currentSide - innerSide * innerSide
end


local function enumRingPositions(ring)
    -- 7  6  5
    -- 8  9  4
    -- 1  2  3
    local i = -1
    local p = ringPerimeter(ring)
    local pside = p // 4
    assert(pside > 0)
    local lower = -ring
    local upper = ring
    return function()
        i = i + 1
        if i >= p then return end
        local phase = i // pside
        local x = i % pside
        if phase == 0 then
            return x + lower, lower, "X+"
        elseif phase == 1 then
            return upper, x + lower, "Z+"
        elseif phase == 2 then
            return upper - x, upper, "X-"
        else
            return lower, upper - x, "Z-"
        end
    end
end


local function enumInwardRingPositions(ring)
    if ring <= 0 then return enumRingPositions(ring) end
    local i = 0
    local p = ringPerimeter(ring)
    local iter = enumRingPositions(ring)
    return function()
        i = i + 1
        local a, b, c = iter()
        if a == nil then return end
        if i == p then c = "X+" end
        return a, b, c
    end
end


local function enumInwardSpiral(rings)
    local ring = rings
    local iter
    local function recreateIter()
        iter = enumInwardRingPositions(ring)
    end
    recreateIter()

    return function()
        local a, b, c = iter()
        if a == nil then
            ring = ring - 1
            if ring < 1 then return end
            recreateIter()
            a, b, c = iter()
        end
        return a, b, c
    end
end


local function enumInitialIntrusion(w)
    local phase = 1
    local x = 0

    return function()
        if phase > 3 then return end
        x = x + 1
        if x >= w then
            phase = phase + 1
            x = 0
        end
        if phase == 1 then
            return 0, -x, "Z-"
        elseif phase == 2 then
            return -x, -w, "X-"
        else
            phase = phase + 1
            return -w, -w, "X+"
        end
    end
end


local JackBot = makeClass(function(self, robot, waitCharging, config, invController)
    self.robot = robot
    self.waitCharging = waitCharging
    self.config = config
    self.invController = invController
end)


function JackBot:requiredSaplings()
    -- 1 excessive for .compare() / keep slot occupied by saplings
    return self.config.width * self.config.height + 1
end


function JackBot:preCheck()
    assert(self.robot.inventorySize() >= 8, "Required: inventory upgrade")

    assert(
        self.robot.count(SAPLING_SLOT) >= self:requiredSaplings(),
        "Required: " .. self:requiredSaplings() .. " saplings in slot " .. SAPLING_SLOT)
    assert(
        self.robot.count(WOOD_SLOT) >= 1,
        "Required: Wood log in slot " .. WOOD_SLOT)

    self.equipped = NO_AXE
    if (
        self.invController ~= nil  -- ability to equip
        and
        self.robot.durability() ~= nil  -- we have an axe!
    ) then
        self.equipped = true
    end
end


function JackBot:reEquip(useAxe)
    if self.equipped == NO_AXE then return end
    if self.equipped == useAxe then return end
    if self.equipped and self.robot.durability() == nil then  -- axe has broken
        self.equipped = NO_AXE
        return
    end
    self.robot.select(SAPLING_SLOT)
    assert(self.invController.equip())
    self.equipped = useAxe
    if useAxe then assert(self.robot.durability() ~= nil) end
end


function JackBot:chop(detectFunc, compareFunc, swingFunc)
    local r, btype = detectFunc()
    if not r and btype == "air" then return end
    self.robot.select(WOOD_SLOT)
    self:reEquip(compareFunc())  -- don't use axe for leafs
    swingFunc()
end


function JackBot:chopForward()
    local r = self.robot
    self:chop(r.detect, r.compare, r.swing)
end


function JackBot:chopUp()
    local r = self.robot
    self:chop(r.detectUp, r.compareUp, r.swingUp)
end


function JackBot:chopDown()
    local r = self.robot
    self:chop(r.detectDown, r.compareDown, r.swingDown)
end


function JackBot:walkTreeSlice()
    local nav = PlaneNav(self.robot)
    nav.currentZ = -1

    for x, z, d in enumInitialIntrusion(TREE_RINGS) do
        nav:gotoPosition(x, z)
        nav:rotate(d)
        self:chopForward()
    end

    for x, z, d in enumInwardSpiral(TREE_RINGS) do
        nav:gotoPosition(x, z)
        nav:rotate(d)
        self:chopUp()
        self:chopDown()
        self:chopForward()
    end

    nav:gotoPosition(0, 0)
    self:chopUp()
    self:chopDown()

    nav:gotoPosition(0, -1)
    nav:rotate("Z+")
end


local function sliceHeight(slice)
    if slice <= 1 then return 1 end
    return slice * 3 - 3  -- 2=>3, 3=>6
end


function JackBot:chopTree()
    self:chopForward()
    local currentH = 1
    for slice=1,TREE_SLICES do
        local targetH = sliceHeight(slice + 1)
        while currentH < targetH do
            self:chopUp()
            assert(self.robot.up())
            currentH = currentH + 1
        end
        self:walkTreeSlice()
    end
    while currentH > 1 do
        assert(self.robot.down())
        currentH = currentH - 1
    end
end


function JackBot:isSapling()
    r, btype = self.robot.detect()
    if not r then return false end
    return btype == "passable"
end


function JackBot:placeSapling()
    self:reEquip(true)  -- ensure tool in hand, not saplings
    self.robot.select(SAPLING_SLOT)
    self.robot.place()
end


function JackBot:handleTree()
    if not self:isSapling() then
        self.robot.setLightColor(COLORS.CHOP)
        self:chopTree()
        self:placeSapling()
        self.robot.setLightColor(COLORS.WALK)
    end
end


function JackBot:farmSessionInner()
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
end


function JackBot:unloadInner()
    for slot=1,self.robot.inventorySize() do
        local keepAmount = 0
        if slot == SAPLING_SLOT then
            keepAmount = self:requiredSaplings()
        elseif slot == WOOD_SLOT then
            keepAmount = 1
        end

        local excess = self.robot.count(slot) - keepAmount
        if excess > 0 then
            self.robot.select(slot)
            self.robot.drop(excess)
            assert(self.robot.count(slot) == keepAmount)
        end
    end
end


function JackBot:farmSession()
    assert(self.robot.forward())
    self:farmSessionInner()
    assert(self.robot.back())
end


function JackBot:unload()
    self.robot.turnRight()
    self:unloadInner()
    self.robot.turnLeft()
end


function JackBot:fullSession()
    self.robot.setLightColor(COLORS.CHARGE)
    self:preCheck()
    self.waitCharging()
    self.robot.setLightColor(COLORS.WALK)
    self:farmSession()
    self.robot.setLightColor(COLORS.CHARGE)
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
        enumGrid=enumGrid,
        ringPerimeter=ringPerimeter,
        enumRingPositions=enumRingPositions,
        enumInwardRingPositions=enumInwardRingPositions,
        enumInitialIntrusion=enumInitialIntrusion
    }
}
