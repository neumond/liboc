local robot = require("robot")
local keyboard = require("keyboard")


local function main()
    local keySwitch = {
        [keyboard.keys.up]=function()
            robot.forward()
        end,
        [keyboard.keys.down]=function()
            robot.back()
        end,
        [keyboard.keys.left]=function()
            robot.turnLeft()
        end,
        [keyboard.keys.right]=function()
            robot.turnRight()
        end,
        [keyboard.keys.z]=function()
            robot.up()
        end,
        [keyboard.keys.x]=function()
            robot.down()
        end
    }

    local event = require("event")
    repeat
        local _, _, _, key = event.pull("key_down")
        local f = keySwitch[key]
        if f ~= nil then f() end
    until key == keyboard.keys.enter
end


main()
