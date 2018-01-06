local robot = require("robot")
local computer = require("computer")
local os = require("os")


local function noDura()
    local d = robot.durability()
    return d == nil
end


local function haveFreeInventory()
    for i=1,16 do
        if robot.count(i) == 0 then return true end
    end
    return false
end


local function grindCobblestone()
    local recheck = 0
    while true do
        local r, btype = robot.detect()
        if r and btype == "solid" then
            robot.swing()
            if noDura() then break end
            recheck = recheck - 1
            if recheck < 0 then
                recheck = 30
                if not haveFreeInventory() then break end
            end
        else
            os.sleep(0.5)
        end
    end
end


local function main()
    grindCobblestone()
    computer.shutdown()
end


main()
