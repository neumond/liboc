local robot = require("robot")
local component = require("component")
local CrafterNav = require("roomBot.crafterNav").CrafterNav
local CrafterStorage = require("roomBot.crafterStorage").CrafterStorage
local CrafterBot = require("roomBot.crafterBot").CrafterBot


local function launchAssembler(func)
    assert(robot.up())
    local nav = CrafterNav(robot, 1)  -- TODO: change to 3
    local storage = CrafterStorage(robot, component.inventory_controller, nav)
    local bot = CrafterBot(storage, component.crafting)

    local success, err = pcall(function()
        func(bot)
    end)
    if not success then
        print("Error has occured:")
        print(err)
    end

    nav.nav:gotoPosition(0, 0)
    nav.nav:rotate("Z+")
    assert(robot.down())
end


launchAssembler(function(bot)
    bot:assemble(itemId, amount, print)
end)
