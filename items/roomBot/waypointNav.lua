local utils = require("utils")


local WaypointNav = utils.makeClass(RotationNav, function(self, super, robot, points)
    super(robot)
    self.currentX = 0
    self.currentY = 0
    self.currentZ = 0
    self.points = {base=true}
end)


function WaypointNav:addPoint(name)
    self.points[name] = true
end


function WaypointNav:connect(a, b)
end


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


return {
    WaypointNav=WaypointNav,
    encode=encode,
    reverseEncoded=reverseEncoded,
    execEncoded=execEncoded,
    pathLength=pathLength,
    reverseActions=reverseActions
}
