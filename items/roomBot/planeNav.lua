local makeClass = require("utils").makeClass
local RotationNav = require("roomBot.rotationNav").RotationNav


local PlaneNav = makeClass(RotationNav, function(self, super, robot)
    super(robot)
    self.currentX = 0
    self.currentZ = 0
end)


function PlaneNav:gotoPosition(x, z)
    local function isCoAxial(to)
        return string.sub(self.currentRotation, 1, 1) == to
    end

    local function handleAxis(current, target, axis)
        local delta = target - current
        if delta == 0 then return end
        local direction = axis .. (delta > 0 and "+" or "-")
        if not isCoAxial(axis) then self:rotate(direction) end
        for i=1,math.abs(delta) do
            if self.currentRotation == direction then
                assert(self.robot.forward())
            else
                assert(self.robot.back())
            end
        end
    end

    if isCoAxial("X") then
        handleAxis(self.currentX, x, "X")
        handleAxis(self.currentZ, z, "Z")
    else
        handleAxis(self.currentZ, z, "Z")
        handleAxis(self.currentX, x, "X")
    end

    self.currentX = x
    self.currentZ = z
end


return {
    PlaneNav=PlaneNav
}
