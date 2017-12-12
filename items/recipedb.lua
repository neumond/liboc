local M = {}
local utils = require("utils")


function recipe1x1(item)
    return {
        nil, nil, nil,
        nil, item, nil,
        nil, nil, nil
    }
end


function recipe1x2(a, b)
    return {
        a, nil, nil,
        b, nil, nil,
        nil, nil, nil
    }
end


function recipe2x2(a, b, c, d)
    return {
        a, b, nil,
        c, d, nil,
        nil, nil, nil
    }
end


function recipe3x1(a, b, c)
    return {
        nil, nil, nil,
        a, b, c,
        nil, nil, nil
    }
end


function recipe3x2(a, b, c, d, e, f)
    return {
        nil, nil, nil,
        a, b, c,
        d, e, f
    }
end


M.items = {
    ["planks"]={
        name="Wood planks",
        ident="minecraft:planks",
        damage=0
    },
    ["cobblestone"]={
        name="Cobblestone",
        ident="minecraft:cobblestone"
    },
    ["iron_ingot"]={
        name="Iron ingot",
        ident="minecraft:iron_ingot"
    },
    ["gold_ingot"]={
        name="Gold ingot",
        ident="minecraft:gold_ingot"
    },
    ["diamond"]={
        name="Diamond",
        ident="minecraft:diamond"
    },


    ["stick"]={
        name="Stick",
        recipe=recipe1x2("planks", "planks"),
        output=4,
        ident="minecraft:stick"
    },
    ["iron_nugget"]={
        name="Iron nugget",
        recipe=recipe1x1("iron_ingot"),
        output=9,
        ident="minecraft:iron_nugget"
    },
    ["gold_nugget"]={
        name="Gold nugget",
        recipe=recipe1x1("gold_ingot"),
        output=9,
        ident="minecraft:gold_nugget"
    },
    ["cutting_wire"]={
        name="Cutting wire",
        recipe=recipe3x1("stick", "iron_nugget", "stick"),
        ident="opencomputers:material",
        damage=0
    },
    ["diamond_chip"]={
        name="Diamond chip",
        recipe=recipe1x2("diamond", "cutting_wire"),
        output=6,
        ident="opencomputers:material",
        damage=29
    },


    ["sugarcane"]={
        name="Sugarcane",
        ident="minecraft:reeds"
    },
    ["paper"]={
        name="Paper",
        recipe=recipe3x1("sugarcane", "sugarcane", "sugarcane"),
        output=3,
        ident="minecraft:paper"
    },


    ["redstone"]={
        name="Redstone",
        ident="minecraft:redstone"
    },
    ["clock"]={
        name="Clock",
        recipe={
            nil, "gold_ingot", nil,
            "gold_ingot", "redstone", "gold_ingot",
            nil, "gold_ingot", nil
        },
        ident="minecraft:clock"
    },
    ["piston"]={
        name="Piston",
        recipe={
            "planks", "planks", "planks",
            "cobblestone", "iron_ingot", "cobblestone",
            "cobblestone", "redstone", "cobblestone"
        },
        ident="minecraft:piston"
    },


    ["cactus"]={
        name="Cactus",
        ident="minecraft:cactus"
    },
    ["dye_green"]={
        name="Green dye",
        furnace="cactus",
        ident="minecraft:dye",
        damage=2
    },
    ["clay"]={
        name="Clay",  -- todo: recipe
        ident="minecraft:clay"
    },
    ["raw_pcb"]={
        name="Raw circuit board",
        recipe=recipe3x1("gold_ingot", "clay", "dye_green"),
        output=8,
        ident="opencomputers:material",
        damage=2
    },
    ["pcb"]={
        name="PCB",
        furnace="raw_pcb",
        ident="opencomputers:material",
        damage=4
    },


    ["transistor"]={
        name="Transistor",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "gold_nugget", "paper", "gold_nugget",
            nil, "redstone", nil
        },
        ident="opencomputers:material",
        damage=6
    },


    ["chip1"]={
        name="Chip I",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "redstone", "transistor", "redstone",
            "iron_nugget", "iron_nugget", "iron_nugget"
        },
        output=8,
        ident="opencomputers:material",
        damage=7
    },
    ["chip2"]={
        name="Chip II",
        recipe={
            "gold_nugget", "gold_nugget", "gold_nugget",
            "redstone", "transistor", "redstone",
            "gold_nugget", "gold_nugget", "gold_nugget"
        },
        output=4,
        ident="opencomputers:material",
        damage=8
    },
    ["chip3"]={
        name="Chip III",
        recipe={
            "diamond_chip", "diamond_chip", "diamond_chip",
            "redstone", "transistor", "redstone",
            "diamond_chip", "diamond_chip", "diamond_chip"
        },
        output=2,
        ident="opencomputers:material",
        damage=9
    },


    ["cu"]={
        name="Control unit",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "transistor", "clock", "transistor",
            "gold_nugget", "transistor", "gold_nugget"
        },
        ident="opencomputers:material",
        damage=11
    },
    ["alu"]={
        name="ALU",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "transistor", "chip1", "transistor",
            "iron_nugget", "transistor", "iron_nugget"
        },
        ident="opencomputers:material",
        damage=10
    },


    ["cpu1"]={
        name="CPU I",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "chip1", "cu", "chip1",
            "iron_nugget", "alu", "iron_nugget"
        },
        ident="opencomputers:component",
        damage=0
    },
    ["cpu2"]={
        name="CPU II",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "chip2", "cu", "chip2",
            "gold_nugget", "alu", "gold_nugget"
        },
        ident="opencomputers:component",
        damage=1
    },
    ["cpu3"]={
        name="CPU III",
        recipe={
            "diamond_chip", "redstone", "diamond_chip",
            "chip3", "cu", "chip3",
            "diamond_chip", "alu", "diamond_chip"
        },
        ident="opencomputers:component",
        damage=2
    },


    ["ram1"]={
        name="RAM I",
        recipe=recipe3x2(
            "chip1", "iron_nugget", "chip1",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=6
    },
    ["ram1_plus"]={
        name="RAM I+",
        recipe=recipe3x2(
            "chip1", "chip2", "chip1",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=7
    },
    ["ram2"]={
        name="RAM II",
        recipe=recipe3x2(
            "chip2", "iron_nugget", "chip2",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=8
    },
    ["ram2_plus"]={
        name="RAM II+",
        recipe=recipe3x2(
            "chip2", "chip3", "chip2",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=9
    },
    ["ram3"]={
        name="RAM III",
        recipe=recipe3x2(
            "chip3", "iron_nugget", "chip3",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=10
    },
    ["ram3_plus"]={
        name="RAM III+",
        recipe=recipe3x2(
            "chip3", "chip3", "chip3",
            "chip2", "pcb", "chip2"
        ),
        ident="opencomputers:component",
        damage=11
    },


    ["card_base"]={
        name="Card base",
        recipe={
            "iron_nugget", nil, nil,
            "iron_nugget", "pcb", nil,
            "iron_nugget", "gold_nugget", nil
        },
        ident="opencomputers:material",
        damage=5
    },


    ["gpu1"]={
        name="Graphic card I",
        recipe=recipe3x2(
            "chip1", "alu", "ram1",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=1
    },
    ["gpu2"]={
        name="Graphic card II",
        recipe=recipe3x2(
            "chip2", "alu", "ram2",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=2
    },
    ["gpu3"]={
        name="Graphic card III",
        recipe=recipe3x2(
            "chip3", "alu", "ram3",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=3
    }
}


local detection_map = {}


for k, v in pairs(M.items) do
    assert(v.ident ~= nil)
    if v.damage == nil then
        assert(detection_map[v.ident] == nil)
        detection_map[v.ident] = k
    else
        if detection_map[v.ident] == nil then
            detection_map[v.ident] = {}
        end
        assert(type(detection_map[v.ident]) == "table")
        assert(detection_map[v.ident][v.damage] == nil)
        detection_map[v.ident][v.damage] = k
    end
end


function M.detect(slot)
    if slot == nil then return end
    local s = detection_map[slot.name]
    if s == nil then return end
    if type(s) == "string" then return s end
    return s[slot.damage]
end


function M.formatRecipe(recipe)
    local widths={}

    function getName(row, col)
        local name = recipe[row * 3 + col - 3]
        if name == nil then return "" end
        return M.items[name]["name"]
    end

    for col=1,3 do
        local w=5
        for row=1,3 do
            local sl = string.len(getName(row, col))
            if sl > w then w = sl end
        end
        widths[col] = w
    end

    local rows={}
    for row=1,3 do
        local r={}
        for col=1,3 do
            r[col] = getName(row, col)
            local spaces = widths[col] - string.len(r[col])
            local spaces_left = math.floor(spaces / 2)
            local spaces_right = spaces - spaces_left
            r[col] = string.rep(" ", spaces_left) .. r[col] .. string.rep(" ", spaces_right)
        end
        rows[row] = table.concat(r, " | ")
    end
    return table.concat(rows, "\n")
end


function M.recipeSummary(recipe)
    local r = {}
    for i=1,9 do
        local v = recipe[i]
        if v ~= nil then
            utils.stock.put(r, v, 1)
        end
    end
    return r
end


function M.recipeOutput(item_id)
    local output = M.items[item_id].output
    if output == nil then output = 1 end
    return output
end


return M
