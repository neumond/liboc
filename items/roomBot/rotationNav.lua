local makeClass = require("utils").makeClass


local rotationMap = {}
for i, v in ipairs({"Z+", "X+", "Z-", "X-"}) do
    rotationMap[v] = i
end


local RotationNav = makeClass(function(self, robot, initial)
    self.robot = robot
    self.currentRotation = initial or "Z+"
end)


local function planRotation(from, to)
    if from == to then return nil end

    from = rotationMap[from] - 1
    to = rotationMap[to] - 1

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


function RotationNav:rotate(to)
    local r = planRotation(self.currentRotation, to)
    if r == "around" then
        self.robot.turnAround()
    elseif r == "left" then
        self.robot.turnLeft()
    elseif r == "right" then
        self.robot.turnRight()
    end
    self.currentRotation = to
end


return {
    RotationNav=RotationNav,
    testing={
        planRotation=planRotation
    }
}
