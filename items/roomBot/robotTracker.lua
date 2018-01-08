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
        end
    }
end


return {
    createTracker=createTracker
}
