local robot = require("robot")
local term = require("term")
local primitive = require("roomBot.primitive")
local createTracker = require("roomBot.robotTracker").createTracker
local Menu = require("lib.simpleMenu").Menu


local function getItemCount()
    local r = 0
    for slot=1,robot.inventorySize() do
        r = r + robot.count(slot)
    end
    return r
end


local function requireItems(n)
    local avail = getItemCount()
    if avail >= n then return true end
    local s = Menu(false)
        :addText("Not enough items")
        :addText("Available: " .. avail)
        :addText("Required: " .. n)
        :addText("Shortage: " .. (n - avail))
        :addSeparator()
        :addSelectable("Continue", true)
        :addSelectable("Cancel", false)
        :run()
    return s
end


local function createSlotIterator()
    local function findNextSlot()
        for slot = 1,robot.inventorySize() do
            if robot.count(slot) > 0 then
                robot.select(slot)
                return true
            end
        end
        return false
    end

    return function()
        if robot.count() <= 0 then
            if not findNextSlot() then return false end
        end
        return true
    end
end


local function buildRectangle(width, height)
    if not requireItems(width * height) then return end
    local slotFunc = createSlotIterator()
    local tracker = createTracker(robot, 0, -1)
    tracker.pushPolicy("RetryUntilSuccess")
    for x, y in primitive.enumGrid(width, height, 1) do
        tracker.gotoPosition(x, y)
        if not robot.detectDown() then
            if not slotFunc() then break end
            tracker.placeDown()
        end
    end
    tracker.gotoPosition(0, 0)
    tracker.gotoPosition(0, -1)
    tracker.rotate("Y+")
end


local function perimeter(width, height)
    if width == 1 then return height end
    if height == 1 then return width end
    return (width - 2) * 2 + (height - 2) * 2 + 4
end


local function buildWalls(width, height, wallHeight)
    if not requireItems(perimeter(width, height) * wallHeight) then return end
    local slotFunc = createSlotIterator()
    local tracker = createTracker(robot, 0, -1, 0)
    tracker.pushPolicy("RetryUntilSuccess")
    for z=1,wallHeight do
        tracker.gotoPosition(0, 0, z)
        for x, y in primitive.enumPerimeter(width, height) do
            tracker.gotoPosition(x, y)
            if not robot.detectDown() then
                if not slotFunc() then break end
                tracker.placeDown()
            end
        end
    end
    tracker.gotoPosition(0, 0)
    tracker.gotoPosition(0, -1)
    tracker.gotoPosition(0, -1, 0)
    tracker.rotate("Y+")
end


local function readForm(params)
    local result = {}
    term.clear()
    for _, p in ipairs(params) do
        print(p.prompt)
        local value = p.coerce(term.read())
        if value == nil then return end
        result[p.name] = value
    end
    return result
end


local function runFiller()
    local ps = readForm({
        {prompt="Enter width", coerce=tonumber, name="width"},
        {prompt="Enter height", coerce=tonumber, name="height"}
    })
    if ps ~= nil then
        buildRectangle(ps.width, ps.height)
    end
end


local function runWaller()
    local ps = readForm({
        {prompt="Enter width", coerce=tonumber, name="width"},
        {prompt="Enter height", coerce=tonumber, name="height"},
        {prompt="Enter wall height", coerce=tonumber, name="wallHeight"}
    })
    if ps ~= nil then
        buildWalls(ps.width, ps.height, ps.wallHeight)
    end
end


local function main()
    while true do
        local func = Menu(true)
            :addText("Filler robot")
            :addSeparator()
            :addSelectable("Fill horizontal rectangle", runFiller)
            :addSelectable("Walls for horizontal rectangle", runWaller)
            :addSeparator()
            :addSelectable("Quit", nil)
            :run()
        if func == nil then break end
        func()
    end
    term.clear()
end


main()
