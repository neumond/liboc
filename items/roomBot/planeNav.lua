local makeClass = require("utils").makeClass


local rotationMap = {}
for i, v in ipairs({"Z+", "X+", "Z-", "X-"}) do
    rotationMap[v] = i
end


local PlaneNav = makeClass(function(self, robot)
    self.robot = robot
    self.currentX = 0
    self.currentZ = 0
    self.currentRotation = "Z+"
end)


function PlaneNav.planRotation(self, from, to)
    from = self.currentRotation
    if from == to then return nil end

    from = rotationMap[from] - 1
    to = rotationMap[to] - 1
    self.currentRotation = to

    if math.abs(from - to) == 2 then return "around" end

    if from - to >= 3 then
        to = to + 4
    elseif to - from >= 3 then
        from = from + 4
    end
    assert(math.abs(from - to) == 1)

    if to > from then
        return "right"
    else
        return "left"
    end
end


function PlaneNav.rotate(self, to)
    local r = self:planRotation(self.currentRotation, to)
    if r == "around" then
        self.robot.turnAround()
    elseif r == "left" then
        self.robot.turnLeft()
    elseif r == "right" then
        self.robot.turnRight()
    end
    self.currentRotation = to
end


function PlaneNav.gotoPosition(self, x, z)
    function isCoAxial(to)
        return string.sub(self.currentRotation, 1, 1) == to
    end

    function handleAxis(current, target, axis)
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
