local component = require("component")
local inv = component.inventory_controller

local d = inv.getStackInInternalSlot()


local f = assert(io.open("r.txt", "a"))

f:write("[\"" .. d.name .. "\"]={\n")
f:write("    name=\"" .. d.label .. "\",\n")
f:write("    recipe={},\n")
f:write("    ident=\"" .. d.name .. "\",\n")
f:write("    damage=" .. d.damage .. ",\n")
f:write("    stack=" .. d.maxSize .. "\n")
f:write("},\n")

f:close()

print(d.name)
