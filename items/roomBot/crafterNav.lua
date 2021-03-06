local makeClass = require("utils").makeClass
local sides = require("sides")
local createTracker = require("roomBot.robotTracker").createTracker


local CrafterNav = makeClass(function(self, robot, chestCascades)
    self.robotTracker = createTracker(robot)
    self.maxChests = chestCascades * 4
end)


local function getChestPairPosition(n)
    local x = n % 2
    if x == 0 then x = -1 end
    local z = math.floor(n / 2) * 2
    return x, z
end


local function getChestPosition(n)
    n = n - 1
    x, z = getChestPairPosition(math.floor(n / 2))
    return x, z, (n % 2 == 1) and sides.up or sides.down
end


function CrafterNav:gotoBase()
    self.robotTracker.gotoPosition(0, 0)
    self.robotTracker.rotate("Y-")
    return sides.front
end


function CrafterNav:gotoChest(n)
    local x, z, side = getChestPosition(n)
    self.robotTracker.gotoPosition(x, z)
    return side
end


function CrafterNav:walkAllChests()
    local i = 1
    return (function()
        if i > self.maxChests then return end
        local side = self:gotoChest(i)
        i = i + 1
        return side, i - 1
    end)
end


return {
    CrafterNav=CrafterNav
}
