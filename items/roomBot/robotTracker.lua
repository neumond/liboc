local makeClass = require("utils").makeClass
local Stack = require("lib.stack").Stack


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

local RetryPolicies={
    ["AsIs"]=function(robotFunc, trackFunc, ...)
        local r, a = robotFunc(...)
        if r then trackFunc() end
        return r, a
    end,
    ["RetryUntilSuccess"]=function(robotFunc, trackFunc, ...)
        while not robotFunc(...) do
        end
        trackFunc()
        return true
    end
}


local function createFakeRobot()
    local fakeRobot = {}
    setmetatable(fakeRobot, {__index=function(t, k)
        return function() return true end
    end})
    return fakeRobot
end


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


local function createTracker(robot, initX, initY, initZ, initRot)
    local rot = 0
    local x, y, z = 0, 0, 0
    local policyStack = Stack()

    if initX ~= nil then x = initX end
    if initY ~= nil then y = initY end
    if initZ ~= nil then z = initZ end
    if initRot ~= nil then rot = ReverseRotMap[initRot] end

    local trackFuncs = {
        forward=function()
            x = x + DXMap[rot]
            y = y + DYMap[rot]
        end,
        back=function()
            x = x - DXMap[rot]
            y = y - DYMap[rot]
        end,
        up=function()
            z = z + 1
        end,
        down=function()
            z = z - 1
        end,
        turnLeft=function()
            rot = (rot + 3) % 4
        end,
        turnRight=function()
            rot = (rot + 1) % 4
        end,
        turnAround=function()
            rot = (rot + 2) % 4
        end,
        place=function() end,
        placeDown=function() end,
        placeUp=function() end
    }

    local function makeWrap(robotFunc, trackFunc)
        return function(...)
            return policyStack:tip()(robotFunc, trackFunc, ...)
        end
    end

    local tracker = {
        pushPolicy=function(policy)
            policyStack:push(RetryPolicies[policy])
        end,
        popPolicy=function()
            policyStack:pop()
        end,
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

    for method, trackFunc in pairs(trackFuncs) do
        tracker[method] = makeWrap(robot[method], trackFunc)
    end

    tracker.pushPolicy("AsIs")

    tracker.rotate = function(to)
        local method = planRotation(rot, ReverseRotMap[to])
        if method == nil then return true end
        return tracker[method]()
    end
    tracker.gotoPosition = function(tx, ty, tz)
        if tx == nil then tx = x end
        if ty == nil then ty = y end
        if tz == nil then tz = z end
        local actions = planMovement(
            RotMap[rot],
            x, y, z,
            tx, ty, tz
        )
        for _, a in ipairs(actions) do
            local method, count = a[1], a[2]
            for i=1,count do
                assert(tracker[method]())
            end
        end
    end

    return tracker
end


return {
    createTracker=createTracker,
    testing={
        createFakeRobot=createFakeRobot,
        planRotation=function(from, to)
            return planRotation(ReverseRotMap[from], ReverseRotMap[to])
        end
    }
}
