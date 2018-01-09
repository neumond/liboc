local makeClass = require("utils").makeClass


local function makeWrap(robotFunc, trackFunc)
    return function()
        local r, a = robotFunc()
        if r then trackFunc() end
        return r, a
    end
end


local DXMap = {
    [0] = 0,
    [1] = 1,
    [2] = 0,
    [3] = -1
}
local DYMap = {
    [0] = 1,
    [1] = 0,
    [2] = -1,
    [3] = 0
}
local RotMap = {
    [0] = "Y+",
    [1] = "X+",
    [2] = "Y-",
    [3] = "X-"
}
local ReverseRotMap = {}
for k, v in pairs(RotMap) do
    ReverseRotMap[v] = k
end


local function createTracker(robot)
    local rot = 0
    local x, y, z = 0, 0, 0
    return {
        forward=makeWrap(robot.forward, function()
            x = x + DXMap[rot]
            y = y + DYMap[rot]
        end),
        back=makeWrap(robot.back, function()
            x = x - DXMap[rot]
            y = y - DYMap[rot]
        end),
        up=makeWrap(robot.up, function()
            z = z + 1
        end),
        down=makeWrap(robot.down, function()
            z = z - 1
        end),
        turnLeft=makeWrap(robot.turnLeft, function()
            rot = (rot + 3) % 4
        end),
        turnRight=makeWrap(robot.turnRight, function()
            rot = (rot + 1) % 4
        end),
        turnAround=makeWrap(robot.turnAround, function()
            rot = (rot + 2) % 4
        end),
        getPosition=function()
            return x, y, z
        end,
        getRotation=function()
            return RotMap[rot]
        end,
        getRotationNum=function()
            return rot
        end
    }
end


local function createFakeRobot()
    local fakeRobot = {}
    setmetatable(fakeRobot, {__index=function(t, k)
        return function() return true end
    end})
    return fakeRobot
end


local OpenNav = makeClass(function(self, robotTracker)
    self.robot = robotTracker
end)


local function planRotation(from, to)
    if from == to then return nil end

    if math.abs(from - to) == 2 then return "turnAround" end

    if from - to >= 3 then
        to = to + 4
    elseif to - from >= 3 then
        from = from + 4
    end
    assert(math.abs(from - to) == 1)

    if to > from then
        return "turnRight"
    else
        return "turnLeft"
    end
end


function planMovement(rot, cx, cy, cz, x, y, z)
    local result = {}
    local currentRotation = rot

    local function add(method, count)
        table.insert(result, {method, count})
    end

    local function isCoAxial(to)
        return string.sub(currentRotation, 1, 1) == to
    end

    local function handleAxis(current, target, axis)
        local delta = target - current
        if delta == 0 then return end

        local direction = axis .. (delta > 0 and "+" or "-")
        if not isCoAxial(axis) then
            add(planRotation(
                    ReverseRotMap[currentRotation],
                    ReverseRotMap[direction]
                ), 1)
            currentRotation = direction
        end

        local count = math.abs(delta)
        if currentRotation == direction then
            add("forward", count)
        else
            add("back", count)
        end
    end

    if z ~= cz then
        add(z > cz and "up" or "down", math.abs(z - cz))
    end

    if isCoAxial("X") then
        handleAxis(cx, x, "X")
        handleAxis(cy, y, "Y")
    else
        handleAxis(cy, y, "Y")
        handleAxis(cx, x, "X")
    end

    return result
end


function OpenNav:rotate(to)
    local method = planRotation(self.robot.getRotationNum(), ReverseRotMap[to])
    if method == nil then return true end
    return self.robot[method]()
end


function OpenNav:gotoPosition(x, y, z, maxAttempts)
    if maxAttempts == nil then maxAttempts = 1 end
    local cx, cy, cz = self.robot.getPosition()
    if x == nil then x = cx end
    if y == nil then y = cy end
    if z == nil then z = cz end
    local actions = planMovement(
        self.robot.getRotation(),
        cx, cy, cz,
        x, y, z
    )
    for _, a in ipairs(actions) do
        local method, count = a[1], a[2]
        for i=1,count do
            local att = 0
            while not self.robot[method]() do
                att = att + 1
                assert(att <= maxAttempts)
                -- TODO: os.sleep here?
            end
        end
    end
end


return {
    createTracker=createTracker,
    OpenNav=OpenNav,
    testing={
        createFakeRobot=createFakeRobot,
        planRotation=function(from, to)
            return planRotation(ReverseRotMap[from], ReverseRotMap[to])
        end
    }
}
