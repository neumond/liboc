local utils = require("utils")
local createTracker = require("roomBot.robotTracker").createTracker
local dijkstra = require("lib.dijkstra").dijkstra


local reverseActions = {
    forward="back",
    back="forward",
    turnLeft="turnRight",
    turnRight="turnLeft",
    turnAround="turnAround",
    up="down",
    down="up"
}


local encodeTable = {
    forward="F",
    back="B",
    turnLeft="L",
    turnRight="R",
    turnAround="A",
    up="U",
    down="D"
}


local decodeTable = {}
for k, v in pairs(encodeTable) do
    decodeTable[v] = k
end


local reverseEncodedMap = {}
for k, v in pairs(encodeTable) do
    reverseEncodedMap[v] = encodeTable[reverseActions[k]]
end


local function optimize(eline)
    local oldLen
    repeat
        oldLen = #eline
        eline = string.gsub(eline, "FB", "")
        eline = string.gsub(eline, "BF", "")
        eline = string.gsub(eline, "UD", "")
        eline = string.gsub(eline, "DU", "")
        eline = string.gsub(eline, "LR", "")
        eline = string.gsub(eline, "RL", "")
        eline = string.gsub(eline, "AA", "")
        eline = string.gsub(eline, "LLLL", "")
        eline = string.gsub(eline, "RRRR", "")
        eline = string.gsub(eline, "LLL", "R")
        eline = string.gsub(eline, "RRR", "L")
        eline = string.gsub(eline, "LL", "A")
        eline = string.gsub(eline, "RR", "A")
    until oldLen == #eline
    return eline
end


local function naiveEncode(logData)
    local result = {}
    for _, action in ipairs(logData) do
        table.insert(result, encodeTable[action])
    end
    return table.concat(result)
end


local function condense(eline)
    local result = {}
    local lastAction
    local counter = 0

    local function flush()
        if counter <= 0 then return end
        if counter == 1 then
            table.insert(result, lastAction)
        else
            table.insert(result, lastAction .. counter)
        end
        counter = 0
    end

    for action in string.gmatch(eline, ".") do
        if action ~= lastAction then
            flush()
            lastAction = action
        end
        counter = counter + 1
    end
    flush()
    return table.concat(result)
end


local function encode(logData)
    return condense(optimize(naiveEncode(logData)))
end


local function iterEncoded(eline)
    local iter = string.gmatch(eline, "[A-Z][0-9]*")
    return function()
        local action = iter()
        if action == nil then return end
        return string.sub(action, 1, 1), tonumber(string.sub(action, 2)) or 1
    end
end


local function reverseEncoded(eline)
    local result = {}
    for action, count in iterEncoded(eline) do
        table.insert(
            result,
            reverseEncodedMap[action] .. (count > 1 and count or "")
        )
    end
    utils.reverseArray(result)
    return table.concat(result)
end


local function execEncoded(robot, eline)
    for action, amount in iterEncoded(eline) do
        local method = decodeTable[action]
        for i=1,amount do
            assert(robot[method]())
        end
    end
end


local function pathLength(eline)
    local result = 0
    for action, amount in iterEncoded(eline) do
        if action == "A" then amount = amount * 2 end
        result = result + amount
    end
    return result
end


local function encodePosition(robotTracker)
    local x, y, z = robotTracker.getPosition()
    local rot = robotTracker.getRotation()
    return string.format("%i:%i:%i:%s", x, y, z, rot)
end


-- WaypointNav


local WaypointNav = utils.makeClass(function(self, robot, initial)
    self.robotTracker = createTracker(robot)

    self.paths = {}
    self.weights = {}  -- duplicate of self.path, but with weights instead paths
    self.pointNames = {}
    self.posToPoint = {}

    -- initial parameter value is produced by method :finalize()
    if initial == nil then
        self:registerPoint("Base")
    else
        for epos, name in pairs(initial.posToPoint) do
            self:registerPoint(name, epos)
        end
        for _, chord in ipairs(initial.chords) do
            self:addBidiChord(chord.from, chord.to, chord.path)
        end
    end
end)


function WaypointNav:addChord(from, to, path)
    if self.paths[from] == nil then
        self.paths[from] = {}
        self.weights[from] = {}
    end
    self.paths[from][to] = path
    self.weights[from][to] = pathLength(path)
end


function WaypointNav:addBidiChord(from, to, path)
    self:addChord(from, to, path)
    self:addChord(to, from, reverseEncoded(path))
end


function WaypointNav:registerPoint(name, epos)
    assert(self.pointNames[name] == nil)
    self.pointNames[name] = true
    if epos == nil then
        epos = encodePosition(self.robotTracker)
    end
    self.posToPoint[epos] = name
end


function WaypointNav:pointExists(name)
    return self.pointNames[name] ~= nil
end


function WaypointNav:getPointList()
    local result = {}
    for k, _ in pairs(self.pointNames) do
        table.insert(result, k)
    end
    return result
end


function WaypointNav:pointAtCurrentPosition()
    return self.posToPoint[encodePosition(self.robotTracker)]
end


function WaypointNav:finalize()
    local chords = {}
    local revTrack = {}

    local function addRevTrack(from, to)
        if revTrack[from] == nil then
            revTrack[from] = {}
        end
        revTrack[from][to] = true
    end

    local function inRevTrack(from, to)
        if revTrack[from] == nil then return false end
        return revTrack[from][to] ~= nil
    end

    for from, chs in pairs(self.paths) do
        for to, path in pairs(chs) do
            if not inRevTrack(from, to) then
                table.insert(chords, {from=from, to=to, path=path})
                addRevTrack(from, to)
                addRevTrack(to, from)
            end
        end
    end

    return {
        chords=chords,
        posToPoint=utils.copyTable(self.posToPoint)
    }
end


function WaypointNav:gotoPoint(name)
    local currentPoint = self:pointAtCurrentPosition()
    assert(currentPoint ~= nil)
    local pointList = dijkstra(self.weights, currentPoint, name)
    assert(pointList[1] == currentPoint)
    for i=2,#pointList do
        local nextPoint = pointList[i]
        execEncoded(self.robotTracker, self.paths[currentPoint][nextPoint])
        currentPoint = nextPoint
    end
end


return {
    WaypointNav=WaypointNav,
    encode=encode,
    reverseEncoded=reverseEncoded,
    execEncoded=execEncoded,
    pathLength=pathLength,
    reverseActions=reverseActions
}
