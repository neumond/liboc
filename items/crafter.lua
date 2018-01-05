local robot = require("robot")
local component = require("component")
local CrafterNav = require("roomBot.crafterNav").CrafterNav
local CrafterStorage = require("roomBot.crafterStorage").CrafterStorage
local CrafterBot = require("roomBot.crafterBot").CrafterBot
local CrafterMenu = require("roomBot.crafterMenu").CrafterMenu
local term = require("term")
local event = require("event")


local function waitForKey()
    repeat
        local _, _, _, key = event.pull("key_down")
    until key == 28
end


local function main()
    assert(robot.forward())

    local nav = CrafterNav(robot, 2)  -- 2 cascades of chests
    local storage = CrafterStorage(robot, component.inventory_controller, nav)
    local bot = CrafterBot(storage, component.crafting)
    nav:gotoBase()

    local function assembleFunc(itemId, amount)
        term.clear()
        storage:reindexLocalInventory()  -- check what user has changed in robot's inventory
        if bot:assemble(itemId, amount, print) then
            storage:cleanLocalInventory()
            storage:takeResult(itemId, amount)
        end
        nav:gotoBase()
        waitForKey()
    end

    local success, err = pcall(function()
        CrafterMenu(assembleFunc)
    end)
    term.clear()
    if not success then
        print("Error has occured:")
        print(err)
    end

    nav:gotoBase()
    assert(robot.forward())
    robot.turnAround()
end


main()
