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
    assert(robot.forward())  -- go inside navplane 0,0 point to correctly initialize

    local nav = CrafterNav(robot, 2)  -- 2 cascades of chests
    local storage = CrafterStorage(robot, component.inventory_controller, nav)
    local bot = CrafterBot(storage, component.crafting)

    local function gotoUserWindow()
        nav:gotoBase()
        assert(robot.forward())
    end

    gotoUserWindow()

    local function assembleFunc(itemId, amount)
        term.clear()
        assert(robot.back())  -- back to navplane 0,0 again
        storage:reindexLocalInventory()  -- check what user has changed in robot's inventory
        local success = bot:assemble(itemId, amount, print)
        if success then
            storage:cleanLocalInventory()
            storage:takeResult(itemId, amount)
        end
        gotoUserWindow()
        if not success then waitForKey() end  -- user able to read messages
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
