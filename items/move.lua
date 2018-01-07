local robot = require("robot")
local keyboard = require("keyboard")
local waypointNav = require("roomBot.waypointNav")


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
    if robot[reverseActions[action]]() then
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
    return logData
end


print(waypointNav.encode(main()))
