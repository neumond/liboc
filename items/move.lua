local keyboard = require("keyboard")
local term = require("term")
local event = require("event")
local waypointMod = require("roomBot.waypointNav")
local utils = require("utils")
local Stack = require("lib.stack").Stack


local FILENAME = "/home/waypoints_auto.lua"


-- PathWriter


local PathWriter = utils.makeClass(function(self, robot)
    term.clear()
    print("Use arrow keys, z, x to direct the bot")
    print("Backspace to revert latest movement")
    print("Enter to finish the path")

    self.log = Stack()
    self.robot = robot
    repeat
        local _, _, _, key = event.pull("key_down")
        local action = self.keyMap2[key]
        if action == "reverse" then
            self:reverseAction()
        elseif action ~= nil then
            self:doAction(action)
        end
    until key == keyboard.keys.enter
end)


do
    PathWriter.keyMap = {
        up="forward",
        down="back",
        left="turnLeft",
        right="turnRight",
        z="up",
        x="down",
        -- special values
        back="reverse"
    }

    PathWriter.keyMap2 = {}
    for k, v in pairs(PathWriter.keyMap) do
        PathWriter.keyMap2[keyboard.keys[k]] = v
    end
end


function PathWriter:doAction(action)
    if self.robot[action]() then
        self.log:push(action)
    end
end


function PathWriter:reverseAction()
    local action = self.log:tip()
    if action == nil then return end
    if self.robot[waypointMod.reverseActions[action]]() then
        self.log:pop()
    end
end


function PathWriter:result()
    local r = {}
    for _, action in self.log:iterFromBottom() do
        table.insert(r, action)
    end
    return waypointMod.encode(r)
end


local function writeDataToFile(fname, data)
    local f = assert(io.open(fname, "w"))
    f:write(require("serialization").serialize(data, false))
    f:close()
end


local function enterNewWaypointName(existsCheck)
    term.clear()
    print("Enter name for the new waypoint")
    while true do
        local wname = utils.strTrimRight(term.read())
        if wname == "" then
            print("Waypoint name must not be empty")
        elseif existsCheck(wname) then
            print("Waypoint with this name already exists, enter another name")
        else
            return wname
        end
    end
end


local function chooseExistingWaypoint(hints, existsCheck)
    term.clear()
    print("Enter name of existing waypoint")
    while true do
        local wname = utils.strTrimRight(term.read({hint=hints}))
        if wname == "" then return end
        if existsCheck(wname) then
            return wname
        else
            print("Waypoint doesn't exist, try again")
        end
    end
end


local function createPath(nav)
    local prevPoint = nav:pointAtCurrentPosition()
    assert(prevPoint ~= nil)
    local path = PathWriter(nav.robotTracker):result()
    local nextPoint = nav:pointAtCurrentPosition()
    if nextPoint == nil then
        nextPoint = enterNewWaypointName(function(ptName)
            return nav:pointExists(ptName)
        end)
        nav:registerPoint(nextPoint)
    end
    nav:addBidiChord(prevPoint, nextPoint, path)
end


local function gotoPoint(nav)
    local wp = chooseExistingWaypoint(nav:getPointList(), function(ptName)
        return nav:pointExists(ptName)
    end)
    if wp ~= nil then
        term.clear()
        print("Going to point [" .. wp .. "] ...")
        nav:gotoPoint(wp)
    end
end


local function printMainMenu(nav)
    term.clear()
    print("Waypoint map creation tool")
    print("Choose option:")
    print("[p] Start new path here")
    print("[g] Go to registered point")
    print("[q] Save & quit")
    print()
    print("Current point: " .. nav:pointAtCurrentPosition())
end


local function main()
    local nav = waypointMod.WaypointNav(require("robot"))

    printMainMenu(nav)
    while true do
        local _, _, _, key = event.pull("key_down")
        if key == keyboard.keys.q then
            break
        elseif key == keyboard.keys.p then
            createPath(nav)
            printMainMenu(nav)
        elseif key == keyboard.keys.g then
            gotoPoint(nav)
            printMainMenu(nav)
        end
    end

    writeDataToFile(FILENAME, nav:finalize())
end


main()
