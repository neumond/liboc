-- constants


local CHEST_CASCADES = 3
local maxChests = CHEST_CASCADES * 4


-- globals


local robot = require("robot")
local sides = require("sides")
local component = require("component")
local invComp = component.inventory_controller
local invModule = require("inventory")
local db = require("recipedb")


-- General navigation on a plane


local Navigation = {
    currentX=0,
    currentZ=0,
    currentRotation="Z+",
    rotationMap = {}
}


for i, v in ipairs({"Z+", "X+", "Z-", "X-"}) do
    Navigation.rotationMap[v] = i
end


function Navigation.planRotation(from, to)
    from = Navigation.currentRotation
    if from == to then return nil end

    from = Navigation.rotationMap[from] - 1
    to = Navigation.rotationMap[to] - 1
    Navigation.currentRotation = to

    if math.abs(from - to) == 2 then return "around" end

    if from - to >= 3 then
        to = to + 4
    elseif to - from >= 3 then
        from = from + 4
    end
    assert(math.abs(from - to) == 1)

    if to > from then
        return "right"
    else
        return "left"
    end
end


function Navigation.rotate(to)
    local r = Navigation.planRotation(Navigation.currentRotation, to)
    if r == "around" then
        robot.turnAround()
    elseif r == "left" then
        robot.turnLeft()
    elseif r == "right" then
        robot.turnRight()
    end
    Navigation.currentRotation = to
end


function Navigation.gotoPosition(x, z)
    function isCoAxial(to)
        return string.sub(Navigation.currentRotation, 1, 1) == to
    end

    function handleAxis(current, target, axis)
        local delta = target - current
        if delta == 0 then return end
        local direction = axis .. (delta > 0 and "+" or "-")
        if not isCoAxial(axis) then Navigation.rotate(direction) end
        for i=1,math.abs(delta) do
            if Navigation.currentRotation == direction then
                assert(robot.forward())
            else
                assert(robot.back())
            end
        end
    end

    if isCoAxial("X") then
        handleAxis(Navigation.currentX, x, "X")
        handleAxis(Navigation.currentZ, z, "Z")
    else
        handleAxis(Navigation.currentZ, z, "Z")
        handleAxis(Navigation.currentX, x, "X")
    end

    Navigation.currentX = x
    Navigation.currentZ = z
end


-- Storage room navigation


function Navigation.getChestPairPosition(n)
    local x = n % 2
    if x == 0 then x = -1 end
    local z = math.floor(n / 2) * 2
    return x, z
end


function Navigation.getChestPosition(n)
    n = n - 1
    x, z = Navigation.getChestPairPosition(math.floor(n / 2))
    return x, z, (n % 2 == 1) and sides.up or sides.down
end


function Navigation.gotoInput()
    Navigation.gotoPosition(-1, -1)
    Navigation.rotate("Z-")
    return sides.front
end


function Navigation.gotoOutput()
    Navigation.gotoPosition(1, -1)
    Navigation.rotate("Z-")
    return sides.front
end


function Navigation.gotoChest(n)
    local x, z, side = Navigation.getChestPosition(n)
    Navigation.gotoPosition(x, z)
    return side
end


function Navigation.getFurnaceEntryPosition(n)
    n = n - 1
    local x = n % 2
    if x == 0 then x = -1 end
    local z = math.floor(n / 2) * 2 + 1
    return x, z, x > 0 and "X+" or "X-"
end


function Navigation.gotoFurnace(n)
    x
end


--


local StorageIndex = {}


function StorageIndex.initialize()
    StorageIndex.slots = {}
    StorageIndex.emptySlots = {}
    StorageIndex.blockedSlots = {}


    function addSlot(itemData)
        local newSlot = {}
        table.insert(StorageIndex.slots, newSlot)
        if itemData == nil then
            table.insert(StorageIndex.emptySlots, #StorageIndex.slots)
        else
            local itemId = db.detect(itemData)
            if itemId == nil then
                table.insert(StorageIndex.blockedSlots, #StorageIndex.slots)
            else
                newSlot.content = {
                    item=itemId,
                    count=itemData.size,
                    capacity=itemData.maxSize
                }
            end
        end
        return newSlot
    end


    for k in invModule.iterNonTableSlots()
        local slot = addSlot(invComp.getStackInInternalSlot(k))
        slot.address = {
            type="internal",
            slot=k
        }
    end

    for i=1,maxChests do
        local side = Navigation.gotoChest(i)
        for k=1,invComp.getInventorySize(side) do
            local slot = addSlot(invComp.getStackInSlot(side, k))
            slot.address = {
                type="chest",
                chest=i,
                slot=k
            }
        end
    end

end


function buildStorageIndex()
    -- todo: check furnaces

    local slots = {}
    local emptySlots = {}
    local blockedSlots = {}




end


--


function main()
    assert(robot.up())

    for _, i in ipairs({5, 7, 1, 3, 4, 2}) do
        local x, z, ud = Navigation.getChestPosition(i)
        Navigation.gotoPosition(x, z)
    end

    Navigation.gotoPosition(0, 0)
    Navigation.rotate("Z+")
    assert(robot.down())
end


main()
