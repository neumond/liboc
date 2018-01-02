local JackBot = require("roomBot.jackBot").JackBot
local os = require("os")
local robot = require("robot")
local computer = require("computer")
local component = require("component")


local function waitCharging()
    while (computer.energy() / computer.maxEnergy()) < 0.9 do
        os.sleep(math.random() * 2 + 1)
    end
end


JackBot(robot, waitCharging, {
    width=1,
    height=1,
    step=6
}, component.inventory_controller):main()
