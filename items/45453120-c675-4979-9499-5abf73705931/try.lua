c = require("crafting")
local success, craftLog, needStock = c.craft({
    -- ["iron_ingot"]=3,
    -- ["pcb"]=2,
    -- ["gold_ingot"]=1,
    -- ["redstone"]=7,
    -- ["sugarcane"]=6
}, "gpu1", 1)

print("Success", success)
print("Craftlog")
for i, v in ipairs(craftLog) do
    print(v)
end
print("needStock")
for k, v in pairs(needStock) do
    print(k, v)
end
