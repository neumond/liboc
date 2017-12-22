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
        func(bot.assemble)
    end)
    if not success then
        print("Error has occured:")
        print(err)
    end

    nav:gotoPosition(0, 0)
    nav:rotate("Z+")
    assert(robot.down())
end


launchAssembler(function(assembleFunc)
    assembleFunc(itemId, amount)
end)
