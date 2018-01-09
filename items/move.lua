local robot = require("robot")
local keyboard = require("keyboard")
local term = require("term")
local event = require("event")
local waypointNav = require("roomBot.waypointNav")
local utils = require("utils")
local Stack = require("lib.stack").Stack


-- PathWriter


local PathWriter = utils.makeClass(function(self)
    term.clear()
    print("Use arrow keys, z, x to direct the bot")
    print("Backspace to revert latest movement")
    print("Enter to finish the path")

    self.log = Stack()
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
    if robot[action]() then
        self.log:push(action)
    end
end


function PathWriter:reverseAction()
    local action = self.log:tip()
    if action == nil then return end
    if robot[waypointNav.reverseActions[action]]() then
        self.log:pop()
    end
end


function PathWriter:result()
    local r = {}
    for action in self.log:iterFromBottom() do
        table.insert(r, action)
    end
    return waypointNav.encode(r)
end


-- WaypointWriter


local WaypointWriter = utils.makeClass(function(self)
    self.waypoints = {["Base"]=true}
    self.currentWaypoint = "Base"
    self.paths = {}
end)


function WaypointWriter:_addPath(from, to, path)
    if self.paths[from] == nil then
        self.paths[from] = {}
    end
    self.paths[from][to] = path
end


function WaypointWriter:createPath()
    local eline = PathWriter():result()
    if eline == "" then return end

    term.clear()
    print("Enter name for the new waypoint")

    local wname
    repeat
        wname = term.read()
        if self.waypoints[wname] ~= nil then
            print("Waypoint with this name already exists, enter another name")
        else
            break
        end
    until false

    self.waypoints[wname] = true
    self:_addPath(currentWaypoint, wname, eline)
    self:_addPath(wname, currentWaypoint, waypointNav.reverseEncoded(eline))
    self.currentWaypoint = wname
end


function WaypointWriter:gotoWaypoint(name)

end


local function main()
    term.clear()
    print("Waypoint map creation tool")

    local waypoints = {"Base"}
    local paths = {}
    local currentWaypoint = "Base"

    -- repeat
    -- until key == keyboard.keys.enter
end
