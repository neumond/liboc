local robot = require("robot")
local keyboard = require("keyboard")


local reverseActions = {
    forward="back",
    back="forward",
    turnLeft="turnRight",
    turnRight="turnLeft",
    up="down",
    down="up"
}


local function doAction(logData, action)
    if robot[action]() then
        table.insert(logData, action)
    end
end


local function reverseAction(logData)
    if #logData <= 0 then return end
    local action = logData[#logData]
    if robot[reverseActions[action]] then
        logData[#logData] = nil
    end
end


local keyMap = {
    up="forward",
    down="back",
    left="turnLeft",
    right="turnRight",
    z="up",
    x="down"
}
local keyMap2 = {}
for k, v in pairs(keyMap) do
    keyMap2[keyboard.keys[k]] = v
end


local encodeTable = {
    forward="F",
    back="B",
    turnLeft="L",
    turnRight="R",
    up="U",
    down="D"
}


local function encode(logData)
    local result = {}
    local lastAction
    local counter = 0

    local function flush()
        if counter <= 0 then return end
        if counter == 1 then
            table.insert(result, lastAction)
        end
        table.insert(result, lastAction .. counter)
        counter = 0
    end

    for _, action in ipairs(logData) do
        if action ~= lastAction then
            flush()
            lastAction = action
        else
            counter = counter + 1
        end
    end
    flush()

    return table.concat(result)
end


local function main()
    local logData = {}
    local event = require("event")
    repeat
        local _, _, _, key = event.pull("key_down")
        local action = keyMap2[key]
        if action ~= nil then
            doAction(logData, action)
        end
        if key == keyboard.keys.back then
            reverseAction(logData)
        end
    until key == keyboard.keys.enter
    print(encode(logData))
    return logData
end


main()
