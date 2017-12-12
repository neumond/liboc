local M = {}
local utils = require("utils")


function recipe1x1(item)
    return {
        nil, nil, nil,
        nil, item, nil,
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
        name="Wood planks"
    },
    ["cobblestone"]={
        name="Cobblestone"
    },
    ["iron_ingot"]={
        name="Iron ingot"
    },
    ["gold_ingot"]={
        name="Gold ingot"
    },
    ["diamond"]={
        name="Diamond"
    },


    ["iron_nugget"]={
        name="Iron nugget",
        recipe=recipe1x1("iron_ingot"),
        output=9
    },
    ["gold_nugget"]={
        name="Gold nugget",
        recipe=recipe1x1("gold_ingot"),
        output=9
    },
    ["diamond_chip"]={
        name="Diamond chip",
        recipe=recipe1x1("diamond"),
        output=6
    },


    ["sugarcane"]={
        name="Sugarcane"
    },
    ["paper"]={
        name="Paper",
        recipe=recipe3x1("sugarcane", "sugarcane", "sugarcane"),
        output=3
    },


    ["redstone"]={
        name="Redstone"
    },
    ["clock"]={
        name="Clock",
        recipe={
            nil, "gold_ingot", nil,
            "gold_ingot", "redstone", "gold_ingot",
            nil, "gold_ingot", nil
        }
    },
    ["piston"]={
        name="Piston",
        recipe={
            "planks", "planks", "planks",
            "cobblestone", "iron_ingot", "cobblestone",
            "cobblestone", "redstone", "cobblestone"
        }
    },


    ["cactus"]={
        name="Cactus"
    },
    ["dye_green"]={
        name="Green dye",
        furnace="cactus"
    },
    ["clay"]={
        name="Clay"  -- todo: recipe
    },
    ["raw_pcb"]={
        name="Raw circuit board",
        recipe=recipe3x1("gold_ingot", "clay", "dye_green"),
        output=8
    },
    ["pcb"]={
        name="PCB",
        furnace="raw_pcb"
    },


    ["transistor"]={
        name="Transistor",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "gold_nugget", "paper", "gold_nugget",
            nil, "redstone", nil
        }
    },


    ["chip1"]={
        name="Chip I",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "redstone", "transistor", "redstone",
            "iron_nugget", "iron_nugget", "iron_nugget"
        },
        output=8
    },
    ["chip2"]={
        name="Chip II",
        recipe={
            "gold_nugget", "gold_nugget", "gold_nugget",
            "redstone", "transistor", "redstone",
            "gold_nugget", "gold_nugget", "gold_nugget"
        },
        output=4
    },
    ["chip3"]={
        name="Chip III",
        recipe={
            "diamond_chip", "diamond_chip", "diamond_chip",
            "redstone", "transistor", "redstone",
            "diamond_chip", "diamond_chip", "diamond_chip"
        },
        output=2
    },


    ["cu"]={
        name="Control unit",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "transistor", "clock", "transistor",
            "gold_nugget", "transistor", "gold_nugget"
        }
    },
    ["alu"]={
        name="ALU",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "transistor", "chip1", "transistor",
            "iron_nugget", "transistor", "iron_nugget"
        }
    },


    ["cpu1"]={
        name="CPU I",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "chip1", "cu", "chip1",
            "iron_nugget", "alu", "iron_nugget"
        }
    },
    ["cpu2"]={
        name="CPU II",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "chip2", "cu", "chip2",
            "gold_nugget", "alu", "gold_nugget"
        }
    },
    ["cpu3"]={
        name="CPU III",
        recipe={
            "diamond_chip", "redstone", "diamond_chip",
            "chip3", "cu", "chip3",
            "diamond_chip", "alu", "diamond_chip"
        }
    },


    ["ram1"]={
        name="RAM I",
        recipe=recipe3x2(
            "chip1", "iron_nugget", "chip1",
            nil, "pcb", nil
        )
    },
    ["ram1_plus"]={
        name="RAM I+",
        recipe=recipe3x2(
            "chip1", "chip2", "chip1",
            nil, "pcb", nil
        )
    },
    ["ram2"]={
        name="RAM II",
        recipe=recipe3x2(
            "chip2", "iron_nugget", "chip2",
            nil, "pcb", nil
        )
    },
    ["ram2_plus"]={
        name="RAM II+",
        recipe=recipe3x2(
            "chip2", "chip3", "chip2",
            nil, "pcb", nil
        )
    },
    ["ram3"]={
        name="RAM III",
        recipe=recipe3x2(
            "chip3", "iron_nugget", "chip3",
            nil, "pcb", nil
        )
    },
    ["ram3_plus"]={
        name="RAM III+",
        recipe=recipe3x2(
            "chip3", "chip3", "chip3",
            "chip2", "pcb", "chip2"
        )
    },


    ["card_base"]={
        name="Card base",
        recipe={
            "iron_nugget", nil, nil,
            "iron_nugget", "pcb", nil,
            "iron_nugget", "gold_nugget", nil
        }
    },


    ["gpu1"]={
        name="Graphic card I",
        recipe=recipe3x2(
            "chip1", "alu", "ram1",
            nil, "card_base", nil
        )
    },
    ["gpu2"]={
        name="Graphic card II",
        recipe=recipe3x2(
            "chip2", "alu", "ram2",
            nil, "card_base", nil
        )
    },
    ["gpu3"]={
        name="Graphic card III",
        recipe=recipe3x2(
            "chip3", "alu", "ram3",
            nil, "card_base", nil
        )
    }
}


local detection_map = {
    ["minecraft:planks"]={
        [0]="planks"
    },
    ["minecraft:cobblestone"]="cobblestone",
    ["minecraft:iron_ingot"]="iron_ingot",
    ["minecraft:gold_ingot"]="gold_ingot",
    ["minecraft:diamond"]="diamond",
    ["minecraft:iron_nugget"]="iron_nugget",
    ["minecraft:gold_nugget"]="gold_nugget",
    ["opencomputers:material"]={
        [4]="pcb",
        [6]="transistor",
        [7]="chip1",
        [8]="chip2",
        [9]="chip3",
        [29]="diamond_chip"
    },
    ["minecraft:reeds"]="sugarcane",
    ["minecraft:paper"]="paper",
    ["minecraft:redstone"]="redstone",
    ["minecraft:clock"]="clock",
    ["minecraft:piston"]="piston",
    ["minecraft:clay"]="clay",
    ["minecraft:cactus"]="cactus",
    ["minecraft:dye"]={
        [2]="dye_green"
    }
}


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
