c = require("crafting")
local success, second = c.craft({
    ["iron_ingot"]=3,
    ["pcb"]=2,
    ["gold_ingot"]=1,
    ["redstone"]=7,
    ["sugarcane"]=6,
    ["iron_nugget"]=8,
    ["gpu1"]=10
}, "gpu1", 1)

if success then
    print("Success")
    print("Craftlog:")
    for i, v in ipairs(second) do
        print(v.item, v.times)
    end
else
    print("Failure")
    print("NeedStock:")
    for k, v in pairs(second) do
        print(k, v)
    end
end
